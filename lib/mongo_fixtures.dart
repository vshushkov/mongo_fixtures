library mongo_fixtures;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';

///
class MongoFixtureLoader {

  ///
  final String _connectionString;

  ///
  const MongoFixtureLoader(this._connectionString);

  ///
  Future _cleanAll(Db db) {
    return db.listCollections().then((List<String> collections) =>
      Future.forEach(collections, (String name) =>
        db.dropCollection(name))
    );
  }

  ///
  Future _insert(Db db, List<MongoFixtureEntity> data) {
    Map<String, DbCollection> collections = {};
    return Future.forEach(data, (MongoFixtureEntity entity) {
      if (!collections.containsKey(entity.collectionName)) {
        collections[entity.collectionName] = db.collection(entity.collectionName);
      }
      return collections[entity.collectionName].insertAll(entity.documents);
    });
  }

  ///
  Future cleanAllAndInsert(List<MongoFixtureEntity> data) {
    Db db = new Db(_connectionString);
    return db.open()
      .then(($) => this._cleanAll(db))
      .then(($) => this._insert(db, data))
      .then(($) => db.close());
  }

  ///
  Future cleanAll() {
    Db db = new Db(_connectionString);
    return db.open()
    .then(($) => this._cleanAll(db))
    .then(($) => db.close());
  }

  ///
  Future insert(List<MongoFixtureEntity> data) {
    Db db = new Db(_connectionString);
    return db.open()
    .then(($) => this._insert(db, data))
    .then(($) => db.close());
  }

}

///
abstract class MongoFixtureEntity {

  ///
  static String getId(String documentName) {
    return null;
  }

  ///
  String get collectionName;

  ///
  List<Map> get documents;
}

///
class MongoFixtureDocument implements MongoFixtureEntity {

  @override
  final String collectionName;

  ///
  final Map map;

  ///
  const MongoFixtureDocument({this.collectionName, this.map});

  @override
  List<Map> get documents => [this.map];
}

///
class MongoFixtureCollection implements MongoFixtureEntity {

  List<Map> _documents = [];

  @override
  final String collectionName;

  ///
  MongoFixtureCollection(this.collectionName);

  @override
  List<Map> get documents => this._documents;

  ///
  void insert(Map map) {
    this._documents.add(map);
  }
}