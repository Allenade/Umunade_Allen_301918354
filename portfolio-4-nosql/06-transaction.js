// Portfolio 4, step 6: a multi-document transaction (borrowing a book).
// Borrowing changes TWO documents: the copy status inside the title, and a new
// loan document. A transaction makes the two changes all-or-nothing.
// MongoDB only allows transactions on a replica set (a single-node replica set
// is enough). See the README for how to start one.
//   mongosh "mongodb://localhost:27017/naalya_library" 06-transaction.js

const hello = db.hello();
if (!hello.setName) {
  print('This server is not part of a replica set, so MongoDB will not run transactions here.');
  print('Trying anyway, to show the error MongoDB gives:');
  const t = db.getMongo().startSession();
  try {
    t.startTransaction();
    t.getDatabase(db.getName()).members.findOne({ _id: 1 });
    t.commitTransaction();
  } catch (e) {
    print('  ERROR ' + e.code + ' (' + e.codeName + '): ' + e.errmsg);
  }
  t.endSession();
  print('Start mongod with --replSet rs0 and run rs.initiate() once (see the README), then run this script again.');
  quit(0);
}
print('Connected to replica set "' + hello.setName + '", transactions are allowed.');

const DAY = 24 * 60 * 60 * 1000;
function step(label) { print('\n=== ' + label + ' ==='); }
function copyStatus(titleId, copyId) {
  return db.titles.findOne({ _id: titleId }, { _id: 0, copies: { $elemMatch: { copy_id: copyId } } }).copies[0].status;
}

// Borrow one copy inside the given session. Throws if the copy is not available.
function borrowInSession(s, titleId, copyId, memberId, librarianId) {
  const sdb = s.getDatabase(db.getName());
  const member = sdb.members.findOne({ _id: memberId });
  const title = sdb.titles.findOne({ _id: titleId });
  const copy = title.copies.find(c => c.copy_id === copyId);
  // Only change the copy if it is still available (the filter checks this).
  const r = sdb.titles.updateOne(
    { _id: titleId, copies: { $elemMatch: { copy_id: copyId, status: 'available' } } },
    { $set: { 'copies.$.status': 'on_loan' } });
  if (r.modifiedCount !== 1) throw new Error('copy ' + copyId + ' is not available');
  const now = new Date();
  sdb.loans.insertOne({
    member_id: memberId, title_id: titleId, copy_id: copyId, lent_by: librarianId,
    lent_at: now, due_date: new Date(now.getTime() + 14 * DAY), status: 'open',
    snapshot: { title: title.title, member_name: member.full_name, campus: copy.campus }
  });
  print('  borrowed copy ' + copyId + ' (' + title.title + ') for member ' + memberId);
}

// ---------------------------------------------------------------- T1 commit
step('T1. COMMIT: member 11 borrows copy 1 of "Biology for Secondary Schools"');
print('before: copy 1 is ' + copyStatus(1, 1) + ', open loans for copy 1: ' + db.loans.countDocuments({ copy_id: 1, status: 'open' }));
let s = db.getMongo().startSession();
s.startTransaction({ readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' } });
borrowInSession(s, 1, 1, 11, 100);
print('inside the transaction (not committed yet), other users still see: copy 1 is ' + copyStatus(1, 1) +
      ', open loans for copy 1: ' + db.loans.countDocuments({ copy_id: 1, status: 'open' }));
s.commitTransaction();
s.endSession();
print('after COMMIT: copy 1 is ' + copyStatus(1, 1) + ', open loans for copy 1: ' + db.loans.countDocuments({ copy_id: 1, status: 'open' }));

// ---------------------------------------------------------------- T2 abort
step('T2. ABORT: member 15 borrows copy 2 AND copy 1 together (copy 1 is now out)');
print('before: copy 2 is ' + copyStatus(1, 2) + ', loans for member 15 in the last hour: ' +
      db.loans.countDocuments({ member_id: 15, lent_at: { $gte: new Date(Date.now() - 3600 * 1000) } }));
s = db.getMongo().startSession();
s.startTransaction({ readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' } });
try {
  borrowInSession(s, 1, 2, 15, 100);
  borrowInSession(s, 1, 1, 15, 100);
  s.commitTransaction();
} catch (e) {
  print('  ERROR: ' + e.message + ' -> abortTransaction()');
  s.abortTransaction();
}
s.endSession();
print('after ABORT: copy 2 is ' + copyStatus(1, 2) + ', loans for member 15 in the last hour: ' +
      db.loans.countDocuments({ member_id: 15, lent_at: { $gte: new Date(Date.now() - 3600 * 1000) } }));
print('The first borrow (copy 2) was undone as well, so nothing half-done was saved.');

// ---------------------------------------------------------------- T3 unique index
step('T3. The unique index still protects us: a second open loan for copy 1 inside a transaction');
s = db.getMongo().startSession();
s.startTransaction();
try {
  s.getDatabase(db.getName()).loans.insertOne({
    member_id: 15, title_id: 1, copy_id: 1, lent_by: 100, lent_at: new Date(),
    due_date: new Date(Date.now() + 14 * DAY), status: 'open',
    snapshot: { title: 'Biology for Secondary Schools', member_name: 'test', campus: 'Naalya Main Campus' } });
  s.commitTransaction();
} catch (e) {
  print('  ERROR ' + e.code + ': ' + e.errmsg);
  s.abortTransaction();
}
s.endSession();
print('open loans for copy 1: ' + db.loans.countDocuments({ copy_id: 1, status: 'open' }));
