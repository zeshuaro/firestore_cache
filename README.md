# Firestore Cache

A Flutter plugin for fetching Firestore documents with read from cache first then server.

This plugin is mainly designed for applications using the `DocumentReference.get()` and `Query.getDocuments()` methods in the `cloud_firestore` plugin, and is implemented with read from cache first then server.

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  firestore_cache: ^0.1.0
```

## Usage

Before using the plugin, you will need to create a document on Firestore and create a timestamp field in that document. See the screenshot below for an example:

![Firestore Screenshot](images/firestore_screenshot.png)

__PLEASE NOTE__ This plugin does not compare the documents in the cache and the ones in the server to determine if it should fetch data from the server. Instead, it relies on this timestamp field in the document to make that decision. And so your application should implement the logic to update this field if you want to read new data from the server instead of reading it from cache.

You should also create different timestamp fields for different collections or documents that you are reading.

```dart
import 'package:firestore_cache/firestore_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This should be the path of the document that you created
final DocumentReference cacheDocRef = Firestore.instance.document('status/status');

// This should be the timestamp field in that document
final String cacheField = 'updatedAt';

final Query query = Firestore.instance.collection('collection');
final QuerySnapshot snapshot = await FirestoreCache.getDocuments(
    query: query,
    cacheDocRef: cacheDocRef,
    firestoreCacheField: cacheField,
);
```