library mongo_fixtures;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';

///
class Loader {

  ///
  final String _connectionString;

  Map<String, Document> _insertedDocuments = {};
  Map<String, List<Document>> _pendingFor = {};

  ///
  Loader(this._connectionString);

  ///
  _LabeledDocument document(String label) {
    return new _LabeledDocument(label);
  }

  ///
  Future _cleanAll(Db db) =>
    db.listCollections().then((List<String> collections) =>
      Future.forEach(collections, (String name) =>
        db.dropCollection(name))
    );

  ///
  Future _insert(Db db, Iterable<Document> data) {
    return Future.forEach(data, (Document document) {
      if (_insertedDocuments.containsKey(document.label) || _stillPending(document)) {
        return null;
      }

      DbCollection collection = db.collection(document.collectionName);

      return collection.insert(_replacePlaceholders(document.map)).then((_) {
        if (document.label != null) {
          _insertedDocuments[document.label] = document;
          return collection.findOne(where.id(document.id))
            .then((Map map) {
              if (_pendingFor.containsKey(document.label)) {
                return _insert(db, _pendingFor[document.label]);
              }
            });
        }
      });
    });
  }

  Iterable<Entity> _prepareEntityList(dynamic provider) {
    Iterable<Entity> entities;
    if (provider is Provider) {
      entities = provider(this);
    } else if (provider is Iterable<Entity>) {
      entities = provider;
    } else if (provider is Entity) {
      entities = (provider as Entity).documents;
    } else {
      // throw exception?
      entities = new Iterable<Entity>.generate(0);
    }

    Iterable<Document> documents = entities
      .expand((Entity entity) => entity.documents);

    // reset
    _insertedDocuments = {};
    _pendingFor = {};

    // filling [_pendingFor] map
    documents.where((Document document) => document.pendingFor.length > 0)
      .forEach((Document dependentDocument) =>
          dependentDocument.pendingFor.forEach((String hostDocumentLabel) =>
          _pendingFor.putIfAbsent(hostDocumentLabel, () => []).add(dependentDocument)
        )
      );

    return documents;
  }

  ///
  bool _stillPending(Document document) {
    return document.pendingFor.length > 0
      && _insertedDocuments.keys.where((String label) =>
        document.pendingFor.contains(label)
      ).length != document.pendingFor.length;
  }

  ///
  Iterable<Document> _remapDocuments(Iterable<Entity> data) {

    Iterable<Document> list = data
      .expand((Entity entity) => entity.documents);

    return list;
  }

  ///
  Map _replacePlaceholders(Map map) {
    map.keys.forEach((key) {
      if (map[key] is _LabeledDocumentField) {
        _LabeledDocumentField field = map[key] as _LabeledDocumentField;
        map[key] = _insertedDocuments[field.documentLabel].map[field.field];
      }
    });
    return map;
  }

  ///
  Future cleanAllAndInsert(dynamic provider) {
    Db db = new Db(_connectionString);
    return db.open()
      .then(($) => this._cleanAll(db))
      .then(($) => this._insert(db, _prepareEntityList(provider)))
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
  Future insert(dynamic provider) {
    Db db = new Db(_connectionString);
    return db.open()
    .then(($) => this._insert(db, _prepareEntityList(provider)))
    .then(($) => db.close());
  }

}

///
abstract class Entity {

  ///
  String get collectionName;

  ///
  Iterable<Document> get documents;
}

///
class Document implements Entity {

  @override
  final String collectionName;

  ///
  final Map<String, dynamic> map;

  ///
  final String label;

  ///
  final ObjectId id = new ObjectId();

  ///
  Document({this.collectionName, this.map, this.label: null}) {
    this.map["_id"] = id;
  }

  @override
  Iterable<Document> get documents => [this];

  Iterable<String> get pendingFor {
    return map.values.where((value) => value is _LabeledDocumentField)
      .map((_LabeledDocumentField field) => field.documentLabel);
  }
}

///
class Collection implements Entity {

  List<Document> _documents = [];

  @override
  final String collectionName;

  ///
  Collection(this.collectionName);

  @override
  Iterable<Document> get documents => this._documents;

  ///
  void insert({Map map, String label: null}) =>
    this._documents.add(new Document(collectionName: collectionName, map: map, label: label));
}

///
class _LabeledDocument {
  final String _label;
  const _LabeledDocument(this._label);
  _LabeledDocumentField field(String field)
    => new _LabeledDocumentField(this._label, field);
}

///
class _LabeledDocumentField {
  final String _documentLabel;
  final String _field;
  const _LabeledDocumentField(this._documentLabel, this._field);
  String get documentLabel => this._documentLabel;
  String get field => this._field;
}

typedef List<Entity> Provider(Loader loader);
