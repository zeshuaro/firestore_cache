# Firestore Cache

[![pub package](https://img.shields.io/pub/v/firestore_cache.svg)](https://pub.dartlang.org/packages/firestore_cache)
[![docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://pub.dev/documentation/firestore_cache/latest/)
[![MIT License](https://img.shields.io/github/license/zeshuaro/firestore_cache.svg)](https://github.com/zeshuaro/firestore_cache/blob/master/LICENSE)
[![GitHub Actions](https://github.com/zeshuaro/firestore_cache/actions/workflows/github-actions.yml/badge.svg)](https://github.com/zeshuaro/firestore_cache/actions/workflows/github-actions.yml)
[![codecov](https://codecov.io/gh/zeshuaro/firestore_cache/branch/main/graph/badge.svg)](https://codecov.io/gh/zeshuaro/firestore_cache)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/4b2fca5d3031431da63158719514eeba)](https://app.codacy.com/gh/zeshuaro/firestore_cache/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![style: flutter_lints](https://img.shields.io/badge/style-flutter__lints-4BC0F5.svg)](https://pub.dev/packages/flutter_lints)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/zeshuaro)
[![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/zeshuaro)
[![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/zeshuaro)
[![LiberaPay](https://img.shields.io/badge/Liberapay-F6C915?style=for-the-badge&logo=liberapay&logoColor=black)](https://liberapay.com/zeshuaro/)
[![Patreon](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://patreon.com/zeshuaro)
[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/JoshuaTang)

A Flutter plugin for fetching Firestore documents with read from cache first then server.

This plugin is mainly designed for applications using the `DocumentReference.get()` and `Query.get()` methods in the `cloud_firestore` plugin, and is implemented with read from cache first then server.

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  firestore_cache: ^2.17.3
```

### Usage

Before using the plugin, you will need to create a document on Firestore and create a timestamp field in that document. See the screenshot below for an example:

![Firestore Screenshot](https://github.com/zeshuaro/firestore_cache/raw/main/images/firestore_screenshot.png)

__⚠️ PLEASE NOTE__ This plugin does not compare the documents in the cache and the ones in the server to determine if it should fetch data from the server. Instead, it relies on the timestamp field in the document to make that decision. And so your application should implement the logic to update this field if you want to read new data from the server instead of reading it from the cache.

You should also create different timestamp fields for different collections or documents that you are fetching.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_cache/firestore_cache.dart';

// This should be the path of the document containing the timestamp field
// that you created
final cacheDocRef = Firestore.instance.doc('status/status');

// This should be the timestamp field in that document
final cacheField = 'updatedAt';

final query = Firestore.instance.collection('posts');
final snapshot = await FirestoreCache.getDocuments(
    query: query,
    cacheDocRef: cacheDocRef,
    firestoreCacheField: cacheField,
);
```
