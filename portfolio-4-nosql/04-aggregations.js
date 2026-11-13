// Portfolio 4, step 4: aggregation pipelines (reports).
// Run after 02-load.js:
//   mongosh "mongodb://localhost:27017/naalya_library" 04-aggregations.js

const DAY = 24 * 60 * 60 * 1000;
const now = new Date();
function step(label) { print('\n=== ' + label + ' ==='); }

step('A1. Top 10 most borrowed titles in the last 90 days');
printjson(db.loans.aggregate([
  { $match: { lent_at: { $gte: new Date(now - 90 * DAY) } } },
  { $group: { _id: '$title_id', title: { $first: '$snapshot.title' }, times_borrowed: { $sum: 1 } } },
  { $sort: { times_borrowed: -1, _id: 1 } },
  { $limit: 10 }
]).toArray());

step('A2. Overdue loans per campus, with the fine owed so far (UGX 500 per late day)');
printjson(db.loans.aggregate([
  { $match: { status: 'open', due_date: { $lt: now } } },
  { $project: { campus: '$snapshot.campus',
                days_late: { $dateDiff: { startDate: '$due_date', endDate: now, unit: 'day' } } } },
  { $group: { _id: '$campus', overdue_loans: { $sum: 1 },
              fine_owed_ugx: { $sum: { $multiply: ['$days_late', 500] } },
              worst_days_late: { $max: '$days_late' } } },
  { $sort: { overdue_loans: -1 } }
]).toArray());

step('A3. Fines summary by member type and fine status ($lookup to members)');
printjson(db.loans.aggregate([
  { $match: { fine: { $exists: true } } },
  { $lookup: { from: 'members', localField: 'member_id', foreignField: '_id', as: 'member' } },
  { $unwind: '$member' },
  { $group: { _id: { member_type: '$member.type', fine_status: '$fine.status' },
              fines: { $sum: 1 }, total_ugx: { $sum: '$fine.amount' } } },
  { $sort: { '_id.member_type': 1, '_id.fine_status': 1 } }
]).toArray());

step('A4. Five members who owe the most in unpaid fines ($lookup for name, class and campus)');
printjson(db.loans.aggregate([
  { $match: { 'fine.status': 'unpaid' } },
  { $group: { _id: '$member_id', unpaid_ugx: { $sum: '$fine.amount' }, fines: { $sum: 1 } } },
  { $sort: { unpaid_ugx: -1, _id: 1 } },
  { $limit: 5 },
  { $lookup: { from: 'members', localField: '_id', foreignField: '_id', as: 'm' } },
  { $unwind: '$m' },
  { $project: { _id: 0, member_id: '$_id', name: '$m.full_name', class: '$m.class_name',
                campus: '$m.campus', fines: 1, unpaid_ugx: 1 } }
]).toArray());

step('A5. Stock check: copies per campus and status ($unwind the embedded copies)');
printjson(db.titles.aggregate([
  { $unwind: '$copies' },
  { $group: { _id: { campus: '$copies.campus', status: '$copies.status' }, copies: { $sum: 1 } } },
  { $group: { _id: '$_id.campus', total: { $sum: '$copies' },
              by_status: { $push: { k: '$_id.status', v: '$copies' } } } },
  { $project: { _id: 0, campus: '$_id', total: 1, by_status: { $arrayToObject: '$by_status' } } },
  { $sort: { campus: 1 } }
]).toArray());
