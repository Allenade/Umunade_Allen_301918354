// Portfolio 4, step 3: basic CRUD (Create, Read, Update, Delete).
// Run after 02-load.js:
//   mongosh "mongodb://localhost:27017/naalya_library" 03-crud.js

function step(label) { print('\n=== ' + label + ' ==='); }

// ---------------------------------------------------------------- CREATE
step('C1. insertOne: a new student joins');
printjson(db.members.insertOne({
  _id: 5001, full_name: 'Halima Nakimuli', email: 'member5001@example.com',
  type: 'student', class_name: 'S1', campus: 'Naalya Main Campus', joined_on: new Date()
}));

step('C2. lend copy 2 of title 1 to the new student (two writes: the loan and the copy status)');
const t1 = db.titles.findOne({ _id: 1 });
printjson(db.loans.insertOne({
  member_id: 5001, title_id: 1, copy_id: 2, lent_by: 100, lent_at: new Date(),
  due_date: new Date(Date.now() + 14 * 24 * 3600 * 1000), status: 'open',
  snapshot: { title: t1.title, member_name: 'Halima Nakimuli', campus: 'Naalya Main Campus' }
}));
printjson(db.titles.updateOne({ _id: 1, 'copies.copy_id': 2 }, { $set: { 'copies.$.status': 'on_loan' } }));

// ---------------------------------------------------------------- READ
step('R1. find: open loans of member 9 (only the fields the desk needs)');
printjson(db.loans.find({ member_id: 9, status: 'open' },
                        { _id: 0, copy_id: 1, 'snapshot.title': 1, lent_at: 1, due_date: 1 }).toArray());

step('R2. find with $filter: copies of title 1 that are available at Naalya Main Campus');
printjson(db.titles.find({ _id: 1 }, {
  title: 1,
  copies: { $filter: { input: '$copies', cond: { $and: [
    { $eq: ['$$this.campus', 'Naalya Main Campus'] }, { $eq: ['$$this.status', 'available'] } ] } } }
}).toArray());

step('R3. find on an embedded array field: titles written by Chinua Achebe');
printjson(db.titles.find({ 'authors.name': 'Chinua Achebe' }, { title: 1, published_year: 1, category: 1 }).toArray());

step('R4. countDocuments: students in S6 at Naalya Kira Campus');
print(db.members.countDocuments({ type: 'student', class_name: 'S6', campus: 'Naalya Kira Campus' }));

// ---------------------------------------------------------------- UPDATE
step('U1. return a book: member 9 brings back copy 1828 (title 609)');
printjson(db.loans.updateOne({ copy_id: 1828, status: 'open' },
                             { $set: { status: 'returned', returned_at: new Date() } }));
printjson(db.titles.updateOne({ _id: 609, 'copies.copy_id': 1828 },
                              { $set: { 'copies.$.status': 'available' } }));
printjson(db.titles.findOne({ _id: 609 }, { title: 1, copies: { $elemMatch: { copy_id: 1828 } } }));

step('U2. pay a fine: the first unpaid fine of member 3577 is paid');
const f = db.loans.findOne({ member_id: 3577, 'fine.status': 'unpaid' }, { fine: 1 });
printjson(f);
if (f) {
  printjson(db.loans.updateOne({ _id: f._id }, { $set: { 'fine.status': 'paid', 'fine.paid_at': new Date() } }));
  printjson(db.loans.findOne({ _id: f._id }, { _id: 0, fine: 1 }));
}

step('U3. updateMany: move every History title published before 1970 to the Reference category');
printjson(db.titles.updateMany({ category: 'History', published_year: { $lt: 1970 } }, { $set: { category: 'Reference' } }));

// ---------------------------------------------------------------- DELETE
step('D1. deleteOne: remove member 5001, who still has a book out');
printjson(db.members.deleteOne({ _id: 5001 }));
print('MongoDB allowed it. There are no foreign keys, so the loan now points to a member that does not exist:');
printjson(db.loans.aggregate([
  { $match: { member_id: 5001 } },
  { $lookup: { from: 'members', localField: 'member_id', foreignField: '_id', as: 'member' } },
  { $project: { _id: 0, member_id: 1, copy_id: 1, status: 1, member_found: { $size: '$member' } } }
]).toArray());
print('(In Part 1, PostgreSQL refuses this delete because of the loan.member_id foreign key.)');

step('D2. clean up: delete the orphan loan and make copy 2 available again');
printjson(db.loans.deleteMany({ member_id: 5001 }));
printjson(db.titles.updateOne({ _id: 1, 'copies.copy_id': 2 }, { $set: { 'copies.$.status': 'available' } }));
