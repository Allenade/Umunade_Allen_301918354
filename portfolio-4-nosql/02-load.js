// Portfolio 4, step 2: load made-up sample data.
// Run after 01-schema.js:
//   mongosh "mongodb://localhost:27017/naalya_library" 02-load.js
// All names and emails are invented. A fixed seed is used so the same data
// comes out every time.

const started = Date.now();
const DAY = 24 * 60 * 60 * 1000;
const NOW = new Date();

// Small random number generator with a fixed seed (mulberry32).
let seed = 42;
function rand() {
  seed |= 0; seed = seed + 0x6D2B79F5 | 0;
  let t = Math.imul(seed ^ seed >>> 15, 1 | seed);
  t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
  return ((t ^ t >>> 14) >>> 0) / 4294967296;
}
const pick = arr => arr[Math.floor(rand() * arr.length)];
const randInt = (lo, hi) => lo + Math.floor(rand() * (hi - lo + 1));

const CAMPUSES = ['Naalya Main Campus', 'Naalya Lugazi Campus', 'Naalya Bweyogerere Campus',
                  'Naalya Kira Campus', 'Naalya Mukono Campus'];
const CATEGORIES = ['Science', 'Mathematics', 'Literature', 'History', 'Physics', 'Chemistry', 'Geography',
                    'Economics', 'Religious Education', 'Computer Studies', 'English Language', 'Kiswahili',
                    'French', 'Agriculture', 'Fine Art', 'Music', 'Entrepreneurship', 'Fiction', 'Biography', 'Reference'];
const FIRST = ['Grace','Brian','Aisha','Peter','Joan','Daniel','Ruth','Isaac','Mary','Samuel',
               'Esther','Moses','Sarah','Joseph','Agnes','David','Faith','Ivan','Doreen','Henry'];
const LAST = ['Namuli','Okello','Nakato','Mugisha','Akello','Ssempa','Nansubuga','Kato','Achieng','Wasswa',
              'Babirye','Opio','Atim','Lubega','Nabirye','Ouma','Kyomuhendo','Tumusiime','Auma','Kizza'];
const AUTHOR_LAST = ['Achebe','Ngugi','Okot','Soyinka','Adichie','Mazrui','Roberts','Neill','Quadling','Ingham',
                     'Kiwanuka','Mwangi','Byaruhanga','Smith','Brown','Taylor','Wilson','Clarke','Mensah','Banda'];
const WORDS1 = ['Introduction to','Foundations of','Essential','Revision Guide for','Advanced','A Short History of',
                'Practical','Understanding','Exploring','New Certificate'];
const WORDS2 = ['Biology','Chemistry','Physics','Mathematics','Geography','History','Economics','Literature',
                'Agriculture','Computer Studies','Fine Art','Music','Kiswahili','French','English'];
const PUBLISHERS = ['Oxford','Cambridge','Longman','Heinemann','Fountain','Macmillan','Pearson','MK Publishers'];

// ---------------------------------------------------------------- members
const members = [];
for (let i = 1; i <= 5000; i++) {
  const type = i % 100 === 0 ? 'librarian' : (i % 10 === 0 ? 'staff' : 'student');
  const m = {
    _id: i,
    full_name: pick(FIRST) + ' ' + pick(LAST),
    email: 'member' + i + '@example.com',
    type: type,
    campus: pick(CAMPUSES),
    joined_on: new Date(NOW - randInt(30, 2000) * DAY)
  };
  if (type === 'student') m.class_name = 'S' + randInt(1, 6);
  members.push(m);
}
db.members.insertMany(members);
const librariansByCampus = {};
members.filter(m => m.type === 'librarian').forEach(m => {
  (librariansByCampus[m.campus] = librariansByCampus[m.campus] || []).push(m._id);
});

// ---------------------------------------------------------------- titles + copies
// The first four are the same books as the Part 1 seed data.
const fixed = [
  { title: 'Biology for Secondary Schools', authors: ['M. B. V. Roberts'], category: 'Science', publisher: 'Oxford', year: 2016 },
  { title: 'Things Fall Apart', authors: ['Chinua Achebe'], category: 'Literature', publisher: 'Heinemann', year: 1958 },
  { title: 'Core Mathematics', authors: ['Hugh Neill', 'Douglas Quadling'], category: 'Mathematics', publisher: 'Cambridge', year: 2018 },
  { title: 'A History of East Africa', authors: ['Kenneth Ingham'], category: 'History', publisher: 'Cambridge', year: 2001 }
];
const titles = [];
const allCopies = [];   // flat list, used below to create loans
let copyId = 0;
for (let i = 1; i <= 2000; i++) {
  const f = fixed[i - 1];
  const nAuthors = rand() < 0.2 ? 2 : 1;
  const authors = f ? f.authors.map(n => ({ name: n }))
                    : Array.from({ length: nAuthors }, () => ({ name: pick('ABCDEGHJKLMNPRSTW'.split('')) + '. ' + pick(AUTHOR_LAST) }));
  const copies = [];
  const nCopies = randInt(1, 5);
  for (let c = 0; c < nCopies; c++) {
    copyId++;
    const copy = { copy_id: copyId, campus: pick(CAMPUSES), accession_number: 'BK-' + String(copyId).padStart(6, '0'),
                   shelf: pick('ABCDEFGH'.split('')) + randInt(1, 20), status: 'available' };
    copies.push(copy);
    allCopies.push({ title_id: i, copy: copy });
  }
  const t = {
    _id: i,
    isbn: '978' + String(i).padStart(10, '0'),
    title: f ? f.title : pick(WORDS1) + ' ' + pick(WORDS2) + ' Book ' + i,
    publisher: f ? f.publisher : pick(PUBLISHERS),
    published_year: f ? f.year : randInt(1960, 2025),
    category: f ? f.category : pick(CATEGORIES),
    authors: authors,
    copies: copies
  };
  titles.push(t);
}
const titleName = {};
titles.forEach(t => { titleName[t._id] = t.title; });

// ---------------------------------------------------------------- loans
const loans = [];
// 30,000 returned loans over the last 3 years, about 15% returned late (with a fine).
for (let i = 0; i < 30000; i++) {
  const c = pick(allCopies);
  const member = members[randInt(0, members.length - 1)];
  const lentAt = new Date(NOW - (30 + rand() * 1065) * DAY);
  const due = new Date(lentAt.getTime() + 14 * DAY);
  const late = rand() < 0.15;
  const returned = new Date(lentAt.getTime() + (late ? (15 + rand() * 30) : rand() * 13) * DAY);
  const loan = {
    member_id: member._id, title_id: c.title_id, copy_id: c.copy.copy_id,
    lent_by: pick(librariansByCampus[c.copy.campus]),
    lent_at: lentAt, due_date: due, returned_at: returned, status: 'returned',
    snapshot: { title: titleName[c.title_id], member_name: member.full_name, campus: c.copy.campus }
  };
  if (late) {
    const daysLate = Math.ceil((returned - due) / DAY);
    loan.fine = { amount: Math.min(500 * daysLate, 20000), reason: 'overdue',
                  status: returned > new Date(NOW - 90 * DAY) && rand() < 0.7 ? 'unpaid' : (rand() < 0.05 ? 'waived' : 'paid') };
  }
  loans.push(loan);
}
// About 10% of copies are out right now: one open loan each, lent in the last 25 days.
allCopies.forEach(c => {
  if (rand() < 0.10) {
    const member = members[randInt(0, members.length - 1)];
    const lentAt = new Date(NOW - rand() * 25 * DAY);
    loans.push({
      member_id: member._id, title_id: c.title_id, copy_id: c.copy.copy_id,
      lent_by: pick(librariansByCampus[c.copy.campus]),
      lent_at: lentAt, due_date: new Date(lentAt.getTime() + 14 * DAY), status: 'open',
      snapshot: { title: titleName[c.title_id], member_name: member.full_name, campus: c.copy.campus }
    });
    c.copy.status = 'on_loan';
  } else if (rand() < 0.01) {
    c.copy.status = rand() < 0.5 ? 'damaged' : 'lost';
  }
});

db.titles.insertMany(titles);
for (let i = 0; i < loans.length; i += 5000) db.loans.insertMany(loans.slice(i, i + 5000));

print('Loaded in ' + (Date.now() - started) + ' ms');
printjson({
  members: db.members.countDocuments(),
  titles: db.titles.countDocuments(),
  copies_embedded_in_titles: db.titles.aggregate([{ $project: { n: { $size: '$copies' } } }, { $group: { _id: null, n: { $sum: '$n' } } }]).toArray()[0].n,
  loans: db.loans.countDocuments(),
  open_loans: db.loans.countDocuments({ status: 'open' }),
  overdue_now: db.loans.countDocuments({ status: 'open', due_date: { $lt: NOW } }),
  loans_with_fine: db.loans.countDocuments({ fine: { $exists: true } })
});

print('\nOne title document (embedded authors and copies):');
printjson(db.titles.findOne({ _id: 2 }));
print('\nOne member document:');
printjson(db.members.findOne({ _id: 7 }));
print('\nOne loan document (references + snapshot + embedded fine):');
printjson(db.loans.findOne({ fine: { $exists: true } }, { _id: 0 }));
