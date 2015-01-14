# MongoFixtures library for Dart

[![Build Status](https://drone.io/github.com/vshushkov/mongo_fixtures/status.png)](https://drone.io/github.com/vshushkov/mongo_fixtures/latest)

A library for inserting your test fixtures into the MongoDb using [mongo_dart](https://pub.dartlang.org/packages/mongo_dart).

## Usage

A simple usage example:

    import 'package:mongo_fixtures/mongo_fixtures.dart';

    List<MongoFixtureEntity> getFixtures() {
        return [

            new MongoFixtureCollection('some_collection')
                ..insert({
                    'field_one': 'value1',
                    'field_tow': 'value2',
                }),

            new MongoFixtureCollection('some_another_collection')
                ..insert({
                    'another_field_one': 'value3',
                    'another_field_tow': 'value4',
                })

        ];
    }

    main() {

        group('test group', () {

            setUp(() {
                return new MongoFixtureLoader('mongodb://127.0.0.1/db_for_test')
                    .cleanAllAndInsert(getFixtures());
            });

            ...

        });
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/vshushkov/mongo_fixtures/issues).
