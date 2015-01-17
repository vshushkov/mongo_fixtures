# MongoFixtures library for Dart

[![Build Status](https://drone.io/github.com/vshushkov/mongo_fixtures/status.png)](https://drone.io/github.com/vshushkov/mongo_fixtures/latest)
[![Pub](https://img.shields.io/pub/v/mongo_fixtures.svg?style=flat-square)]()

A library for inserting your test fixtures into the MongoDb using [mongo_dart](https://pub.dartlang.org/packages/mongo_dart).

## Usage

A simple usage example:

    import 'package:mongo_fixtures/mongo_fixtures.dart' as fixtures;

    List<fixtures.Entity> fixturesProvider(fixtures.Loader loader) {
        return [

            new fixtures.Collection('some_collection')
                ..insert(map: {
                    'field_one': 'value1',
                    'field_two': 'value2',
                    'field_three': loader.document('document').field('another_field_one'),
                }),

            new fixtures.Collection('some_another_collection')
                ..insert(map: {
                    'another_field_one': 'value3',
                    'another_field_two': 'value4',
                })
                ..insert(label: 'document', map: {
                    'another_field_one': 'value3',
                    'another_field_two': 'value4',
                })

        ];
    }

    main() {

        group('test group', () {

            setUp(() {
                return new fixtures.Loader('mongodb://127.0.0.1/db_for_test')
                    .cleanAllAndInsert(fixturesProvider);
            });

            ...

        });
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/vshushkov/mongo_fixtures/issues).
