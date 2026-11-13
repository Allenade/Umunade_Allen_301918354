// Portfolio 4, step 1: create the collections with JSON Schema validation.
// Run: mongosh "mongodb://localhost:27017/naalya_library" 01-schema.js
// WARNING: this drops the naalya_library database first, so it starts clean.

db.dropDatabase();

const CAMPUSES = ['Naalya Main Campus', 'Naalya Lugazi Campus', 'Naalya Bweyogerere Campus',
                  'Naalya Kira Campus', 'Naalya Mukono Campus'];

// titles: one document per book title, with its authors, category and
// physical copies embedded inside it.
db.createCollection('titles', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['_id', 'title', 'category', 'authors', 'copies'],
      properties: {
        _id:            { bsonType: 'int' },
        isbn:           { bsonType: 'string', pattern: '^[0-9]{10}([0-9]{3})?$' },
        title:          { bsonType: 'string', minLength: 1, maxLength: 200 },
        publisher:      { bsonType: 'string' },
        published_year: { bsonType: 'int', minimum: 1450, maximum: 2100 },
        category:       { bsonType: 'string' },
        authors: {
          bsonType: 'array', minItems: 1,
          items: { bsonType: 'object', required: ['name'], properties: { name: { bsonType: 'string' } } }
        },
        copies: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            required: ['copy_id', 'campus', 'accession_number', 'status'],
            properties: {
              copy_id:          { bsonType: 'int' },
              campus:           { enum: CAMPUSES },
              accession_number: { bsonType: 'string' },
              shelf:            { bsonType: 'string' },
              status:           { enum: ['available', 'on_loan', 'on_hold', 'damaged', 'lost'] }
            }
          }
        }
      }
    }
  }
});

// members: students, staff and librarians.
db.createCollection('members', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['_id', 'full_name', 'email', 'type', 'campus', 'joined_on'],
      properties: {
        _id:        { bsonType: 'int' },
        full_name:  { bsonType: 'string' },
        email:      { bsonType: 'string', pattern: '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$' },
        type:       { enum: ['student', 'staff', 'librarian'] },
        class_name: { bsonType: 'string' },
        campus:     { enum: CAMPUSES },
        joined_on:  { bsonType: 'date' }
      },
      // Same rule as the Part 1 CHECK: only students have a class.
      anyOf: [
        { properties: { type: { enum: ['student'] } } },
        { not: { required: ['class_name'] } }
      ]
    }
  }
});

// loans: one document per loan. It points to the member and the copy, keeps a
// small copy (snapshot) of the title, member name and campus as they were on
// the day of the loan, and embeds the fine if there is one.
db.createCollection('loans', {
  validator: {
    $and: [
      { $jsonSchema: {
          bsonType: 'object',
          required: ['member_id', 'title_id', 'copy_id', 'lent_by', 'lent_at', 'due_date', 'status', 'snapshot'],
          properties: {
            member_id:   { bsonType: 'int' },
            title_id:    { bsonType: 'int' },
            copy_id:     { bsonType: 'int' },
            lent_by:     { bsonType: 'int' },
            lent_at:     { bsonType: 'date' },
            due_date:    { bsonType: 'date' },
            returned_at: { bsonType: 'date' },
            status:      { enum: ['open', 'returned'] },
            snapshot: {
              bsonType: 'object',
              required: ['title', 'member_name', 'campus'],
              properties: {
                title: { bsonType: 'string' }, member_name: { bsonType: 'string' }, campus: { enum: CAMPUSES }
              }
            },
            fine: {
              bsonType: 'object',
              required: ['amount', 'reason', 'status'],
              properties: {
                amount: { bsonType: ['int', 'double', 'decimal'], minimum: 0, exclusiveMinimum: true },
                reason: { enum: ['overdue', 'lost', 'damaged'] },
                status: { enum: ['unpaid', 'paid', 'waived'] }
              }
            }
          }
      } },
      // Same as the Part 1 CHECK constraints on dates.
      { $expr: { $gte: ['$due_date', '$lent_at'] } },
      { $expr: { $or: [ { $eq: [{ $type: '$returned_at' }, 'missing'] }, { $gte: ['$returned_at', '$lent_at'] } ] } }
    ]
  }
});

// Unique keys from Part 1.
db.titles.createIndex({ isbn: 1 }, { unique: true, partialFilterExpression: { isbn: { $exists: true } } });
db.members.createIndex({ email: 1 }, { unique: true });
// Same rule as Part 1: a copy can only have ONE open loan at a time.
db.loans.createIndex({ copy_id: 1 }, { unique: true, partialFilterExpression: { status: 'open' },
                                       name: 'one_open_loan_per_copy' });

print('Collections created:');
printjson(db.getCollectionNames().sort());

// ---------------------------------------------------------------------------
// Inserts that must FAIL because they break the rules.
// ---------------------------------------------------------------------------
// Turns MongoDB's validation error details into one short line per broken rule.
function brokenRules(d, path) {
  path = path || '';
  let out = [];
  if (d.clausesNotSatisfied) d.clausesNotSatisfied.forEach(c => { out = out.concat(brokenRules(c.details, path)); });
  if (d.operatorName === '$expr') out.push('$expr ' + JSON.stringify(d.specifiedAs.$expr));
  (d.schemaRulesNotSatisfied || d.details || []).forEach(r => {
    if (r.propertiesNotSatisfied) r.propertiesNotSatisfied.forEach(p => {
      const sub = brokenRules({ schemaRulesNotSatisfied: p.details }, path + p.propertyName + '.');
      out = out.concat(sub.length ? sub : [path + p.propertyName]);
    });
    else if (r.missingProperties) out.push(path + 'missing: ' + r.missingProperties.join(', '));
    else if (r.operatorName && r.operatorName !== 'properties') {
      let extra = r.reason ? ' (' + r.reason + ')' : '';
      if (r.consideredValue !== undefined) extra += ' value: ' + JSON.stringify(r.consideredValue);
      if (r.specifiedAs) extra += ' rule: ' + JSON.stringify(r.specifiedAs);
      out.push(path.replace(/\.$/, '') + (path ? ' ' : '') + r.operatorName + extra);
    }
  });
  return out;
}

function tryInsert(label, coll, doc) {
  print('\n--- ' + label);
  try {
    db.getCollection(coll).insertOne(doc);
    print('INSERTED (this should not happen)');
  } catch (e) {
    print('REJECTED: error ' + e.code + ': ' + e.errmsg);
    if (e.errInfo && e.errInfo.details) brokenRules(e.errInfo.details).forEach(r => print('  broken rule: ' + r));
  }
}

tryInsert('1. member with a bad email and an unknown type', 'members',
  { _id: 900001, full_name: 'Test Person', email: 'not-an-email', type: 'visitor',
    campus: 'Naalya Main Campus', joined_on: new Date() });

tryInsert('2. staff member with a class (only students have a class)', 'members',
  { _id: 900002, full_name: 'Test Teacher', email: 'teacher@example.com', type: 'staff',
    class_name: 'S4', campus: 'Naalya Main Campus', joined_on: new Date() });

tryInsert('3. loan with a negative fine', 'loans',
  { member_id: 1, title_id: 1, copy_id: 1, lent_by: 1, lent_at: new Date(), due_date: new Date(Date.now() + 14 * 864e5),
    status: 'returned', returned_at: new Date(), snapshot: { title: 'X', member_name: 'Y', campus: 'Naalya Main Campus' },
    fine: { amount: -500, reason: 'overdue', status: 'unpaid' } });

tryInsert('4. loan due BEFORE the day it was lent', 'loans',
  { member_id: 1, title_id: 1, copy_id: 1, lent_by: 1, lent_at: new Date(), due_date: new Date(Date.now() - 864e5),
    status: 'open', snapshot: { title: 'X', member_name: 'Y', campus: 'Naalya Main Campus' } });

tryInsert('5. title with no authors and a campus that does not exist', 'titles',
  { _id: 900003, title: 'Broken Book', category: 'Science', authors: [],
    copies: [{ copy_id: 900003, campus: 'Naalya Mars Campus', accession_number: 'X-1', status: 'available' }] });

print('\nDocuments saved after the failing inserts: members=' + db.members.countDocuments() +
      ', loans=' + db.loans.countDocuments() + ', titles=' + db.titles.countDocuments());
