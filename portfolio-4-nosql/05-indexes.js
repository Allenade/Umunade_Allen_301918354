// Portfolio 4, step 5: indexes, with explain('executionStats') before and after.
// Run after 02-load.js:
//   mongosh "mongodb://localhost:27017/naalya_library" 05-indexes.js
// The script first drops the indexes it creates, so it can be run again.

const now = new Date();

// Short summary of an explain() result: the plan stages, how many index keys
// and documents MongoDB had to look at, and how many it returned.
function stages(p) {
  if (!p) return [];
  let s = p.stage + (p.indexName ? ' (' + p.indexName + ')' : '');
  let kids = [];
  if (p.inputStage) kids = stages(p.inputStage);
  if (p.inputStages) p.inputStages.forEach(c => { kids = kids.concat(stages(c)); });
  return [s].concat(kids);
}
function summary(label, exp) {
  const wp = exp.queryPlanner.winningPlan.queryPlan || exp.queryPlanner.winningPlan;
  const st = exp.executionStats;
  print(label);
  print('  plan:               ' + stages(wp).join(' <- '));
  print('  nReturned:          ' + st.nReturned);
  print('  totalKeysExamined:  ' + st.totalKeysExamined);
  print('  totalDocsExamined:  ' + st.totalDocsExamined);
  print('  executionTimeMillis: ' + st.executionTimeMillis);
  return st;
}

const Q = {
  q1: () => db.loans.find({ member_id: 3912 }).sort({ lent_at: -1 }).limit(20),
  q2: () => db.loans.find({ status: 'open', 'snapshot.campus': 'Naalya Kira Campus', due_date: { $lt: now } }),
  q3: () => db.titles.find({ category: 'Literature' }).sort({ published_year: -1 }).limit(10)
};
const LABEL = {
  q1: 'Q1. loan history of member 3912, newest first (latest 20)',
  q2: 'Q2. overdue open loans at Naalya Kira Campus',
  q3: 'Q3. newest 10 Literature titles'
};

// Clean start: only the _id indexes and the unique ones from 01-schema.js.
['member_id_1_lent_at_-1', 'status_1_snapshot.campus_1_due_date_1'].forEach(n => { try { db.loans.dropIndex(n); } catch (e) {} });
['category_1_published_year_-1', 'title_text_authors.name_text'].forEach(n => { try { db.titles.dropIndex(n); } catch (e) {} });

const before = {}, after = {};
print('================ BEFORE the new indexes ================');
for (const k of Object.keys(Q)) before[k] = summary(LABEL[k], Q[k]().explain('executionStats'));
print('Q4. search titles for "achebe" (no text index yet, so a case-insensitive regex)');
before.q4 = summary('    find({$or: [{title: /achebe/i}, {"authors.name": /achebe/i}]})',
  db.titles.find({ $or: [{ title: /achebe/i }, { 'authors.name': /achebe/i }] }).explain('executionStats'));

print('\n================ creating indexes ================');
// Q1: equality on member_id, then sort on lent_at -> compound index in that order.
print(db.loans.createIndex({ member_id: 1, lent_at: -1 }));
// Q2: follows the ESR rule (Equality, Sort, Range): status and campus are
// equality matches, due_date is a range, so it goes last.
print(db.loans.createIndex({ status: 1, 'snapshot.campus': 1, due_date: 1 }));
// Q3: equality on category, sort on published_year.
print(db.titles.createIndex({ category: 1, published_year: -1 }));
// Q4: a text index on the title and on the embedded author names.
print(db.titles.createIndex({ title: 'text', 'authors.name': 'text' }));

print('\n================ AFTER the new indexes ================');
for (const k of Object.keys(Q)) after[k] = summary(LABEL[k], Q[k]().explain('executionStats'));
print('Q4. search titles for "achebe" with the text index');
after.q4 = summary('    find({$text: {$search: "achebe"}})',
  db.titles.find({ $text: { $search: 'achebe' } }).explain('executionStats'));

print('\n================ summary ================');
print('query | docs examined before -> after | keys examined before -> after | returned');
for (const k of ['q1', 'q2', 'q3', 'q4']) {
  print(k.toUpperCase() + '    | ' + before[k].totalDocsExamined + ' -> ' + after[k].totalDocsExamined +
        ' | ' + before[k].totalKeysExamined + ' -> ' + after[k].totalKeysExamined +
        ' | ' + before[k].nReturned + ' / ' + after[k].nReturned);
}

print('\nIndexes now on loans:');
printjson(db.loans.getIndexes().map(i => i.name));
print('Indexes now on titles:');
printjson(db.titles.getIndexes().map(i => i.name));
