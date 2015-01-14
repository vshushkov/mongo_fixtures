library mongo_fixtures.test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:mongo_fixtures/mongo_fixtures.dart';
import 'package:mongo_dart/mongo_dart.dart';

List<MongoFixtureEntity> getFixtures() {
  return [

      new MongoFixtureCollection('some_collection')
        ..insert({
          'field_one': 'value1-1',
          'field_two': 'value1-2',
      })
        ..insert({
          'field_one': 'value2-1',
          'field_two': 'value2-2',
      }),

      new MongoFixtureCollection('some_another_collection')
        ..insert({
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

      MongoFixtureLoader loader = new MongoFixtureLoader(connectionString);

      /// inserting
      return loader.insert([
          new MongoFixtureCollection('colection_to_delete')
            ..insert({'bla_bla': 'bla_bla'})
      ])
      /// checking collection
      .then((_) => db.listCollections().then((List<String> list) {
        expect(list, hasLength(1));
        expect(list, contains('colection_to_delete'));
      }))

      /// clean & insert
      .then((_) => loader.cleanAllAndInsert(getFixtures()))

      /// checking existing collections
      .then((_) => db.listCollections().then((List<String> list) {
        expect(list, hasLength(2));
        expect(list, contains('some_collection'));
        expect(list, contains('some_another_collection'));
      }))

      /// checking collection 'some_collection'
      .then((_) => db.collection('some_collection').find().toList().then((List<Map> list) {
        expect(list, hasLength(2));
        expect(list[0], containsPair('field_one', 'value1-1'));
        expect(list[0], containsPair('field_two', 'value1-2'));
        expect(list[1], containsPair('field_one', 'value2-1'));
        expect(list[1], containsPair('field_two', 'value2-2'));
      }))

      /// checking collection 'some_another_collection'
      .then((_) => db.collection('some_another_collection').find().toList().then((List<Map> list) {
        expect(list, hasLength(1));
        expect(list[0], containsPair('another_field_one', 'value3-1'));
        expect(list[0], containsPair('another_field_two', 'value3-2'));
      }));

    });

    test('insert and then clean', () {

      MongoFixtureLoader loader = new MongoFixtureLoader(connectionString);

      /// inserting
      return loader.insert(getFixtures())

      /// checking existing collections
      .then((_) => db.listCollections().then((List<String> list) {
        expect(list, hasLength(2));
        expect(list, contains('some_collection'));
        expect(list, contains('some_another_collection'));
      }))

      /// checking collection 'some_collection'
      .then((_) => db.collection('some_collection').find().toList().then((List<Map> list) {
        expect(list, hasLength(2));
        expect(list[0], containsPair('field_one', 'value1-1'));
        expect(list[0], containsPair('field_two', 'value1-2'));
        expect(list[1], containsPair('field_one', 'value2-1'));
        expect(list[1], containsPair('field_two', 'value2-2'));
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

  });

}