library mongo_fixtures.test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:mongo_fixtures/mongo_fixtures.dart';
import 'package:mongo_dart/mongo_dart.dart';

List<Entity> fixturesProvider(Loader loader) {
  return [

      new Collection('some_collection')
        ..insert(map: {
          'field_one': 'value1-1',
          'field_two': 'value1-2',
          'field_three': loader.document('document').field('another_field_two'),
      })
        ..insert(map: {
          'field_one': 'value2-1',
          'field_two': 'value2-2',
          'field_three': loader.document('document').id(),
          'field_four': loader.document('document').idAsHexString()
      }),

      new Collection('some_another_collection')
        ..insert(label: 'document', map: {
          'another_field_one': 'value3-1',
          'another_field_two': 'value3-2',
      })

  ];
}

main() {
  group('inserting fixtures to database', () {

    String connectionString = 'mongodb://127.0.0.1/mongo_fixtures_test';

    Db db = new Db(connectionString);

    setUp(() => db.open()
      .then((_) => db.listCollections())
      .then((List<String> collections) =>
        Future.forEach(collections, (String name) =>
          db.dropCollection(name))
      )
    );
    tearDown(() => db.close());

    test('clean all & insert', () {

      Loader loader = new Loader(connectionString);

      /// inserting
      return loader.insert(
        new Collection('colection_to_delete')
          ..insert(map: {'bla_bla': 'bla_bla'})
      )
      /// checking collection
      .then((_) => db.listCollections().then((List<String> list) {
        expect(list, hasLength(1));
        expect(list, contains('colection_to_delete'));
      }))

      /// clean & insert
      .then((_) => loader.cleanAllAndInsert(fixturesProvider))

      /// checking existing collections
      .then((_) => db.listCollections().then((List<String> list) {
        expect(list, hasLength(2));
        expect(list, contains('some_collection'));
        expect(list, contains('some_another_collection'));
      }))

      /// checking collection 'some_collection'
      .then((_) => db.collection('some_collection')
        .find(where.sortBy('field_one')).toList().then((List<Map> list) {
          expect(list, hasLength(2));

          expect(list[0], containsPair('field_one', 'value1-1'));
          expect(list[0], containsPair('field_two', 'value1-2'));
          expect(list[0], containsPair('field_three', 'value3-2'));

          expect(list[1], containsPair('field_one', 'value2-1'));
          expect(list[1], containsPair('field_two', 'value2-2'));
          expect(list[1], containsPair('field_three', new isInstanceOf<ObjectId>('ObjectId')));
          expect(list[1], containsPair('field_four', hasLength(24)));
          expect((list[1]['field_three'] as ObjectId).toHexString(), list[1]['field_four']);

          return db.collection('some_another_collection')
          .findOne(where.id(list[1]['field_three']))
          .then((Map map) {
            expect(map, containsPair('another_field_one', 'value3-1'));
            expect(map, containsPair('another_field_two', 'value3-2'));
          });
        }))

      /// checking collection 'some_another_collection'
      .then((_) => db.collection('some_another_collection').find().toList().then((List<Map> list) {
        expect(list, hasLength(1));
        expect(list[0], containsPair('another_field_one', 'value3-1'));
        expect(list[0], containsPair('another_field_two', 'value3-2'));
      }));

    });

    test('insert and then clean', () {

      Loader loader = new Loader(connectionString);

      /// inserting
      return loader.insert(fixturesProvider)

      /// checking existing collections
      .then((_) => db.listCollections().then((List<String> list) {
        expect(list, hasLength(2));
        expect(list, contains('some_collection'));
        expect(list, contains('some_another_collection'));
      }))

      /// checking collection 'some_collection'
      .then((_) => db.collection('some_collection')
        .find(where.sortBy('field_one')).toList().then((List<Map> list) {
          expect(list, hasLength(2));

          expect(list[0], containsPair('field_one', 'value1-1'));
          expect(list[0], containsPair('field_two', 'value1-2'));
          expect(list[0], containsPair('field_three', 'value3-2'));

          expect(list[1], containsPair('field_one', 'value2-1'));
          expect(list[1], containsPair('field_two', 'value2-2'));
          expect(list[1], containsPair('field_three', new isInstanceOf<ObjectId>('ObjectId')));
          expect(list[1], containsPair('field_four', hasLength(24)));

          return db.collection('some_another_collection')
          .findOne(where.id(list[1]['field_three']))
          .then((Map map) {
            expect(map, containsPair('another_field_one', 'value3-1'));
            expect(map, containsPair('another_field_two', 'value3-2'));
          });
        }))

      /// checking collection 'some_another_collection'
      .then((_) => db.collection('some_another_collection').find().toList().then((List<Map> list) {
        expect(list, hasLength(1));
        expect(list[0], containsPair('another_field_one', 'value3-1'));
        expect(list[0], containsPair('another_field_two', 'value3-2'));
      }))

      .then((_) => loader.cleanAll())

      /// checking existing collections
      .then((_) => db.listCollections().then((List<String> list) {
        expect(list, hasLength(0));
      }));

    });

    test('specify own "_id" attribute', () {

      Loader loader = new Loader(connectionString);

      ObjectId id = new ObjectId();

      return loader.insert(
          new Collection('some_collection')
            ..insert(map: {'bla_bla': 'bla_bla', '_id': id})
      )
      .then((_) => db.collection('some_collection').find(where.id(id)).toList())
      .then((List<Map> list) {
        expect(list, hasLength(1));
        expect(list[0], containsPair('bla_bla', 'bla_bla'));
        expect(list[0], containsPair('_id', id));
      });

    });

  });

}