import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exceptions.dart';

/// FirestoreCache is a Flutter plugin for fetching Firestore documents
/// with read from cache first then server.
///
/// Before using this plugin, you will need to do some inital setup on Firestore.
/// Then you can use this sample code to fetch documents:
///
/// ```dart
/// // This should be the path of the document that you created
/// final DocumentReference cacheDocRef = Firestore.instance.doc('status/status');
///
/// // This should be the timestamp field in that document
/// final String cacheField = 'updatedAt';
///
/// final Query query = Firestore.instance.collection('collection');
/// final QuerySnapshot snapshot = await FirestoreCache.getDocuments(
///     query: query,
///     cacheDocRef: cacheDocRef,
///     firestoreCacheField: cacheField,
/// );
/// ```
class FirestoreCache {
  /// Fetch a document with read from cache first then server.
  ///
  /// This method takes in a [docRef] which is the usual [DocumentReference] object
  /// on Firestore used for retrieving a single document. It tries to retrieve the
  /// document from the cache first, and fallback to retrieving from the server if it
  /// fails to do so. It also takes in an optional argument [source] which you can
  /// force it to fetch the document from the server, an [isRefreshEmptyCache] to
  /// refresh the cached document from the server if it is empty.
  ///
  /// This method should only be used if the document you are fetching does not change
  /// over time. Once the document is cached, it will always be read from the cache.
  static Future<DocumentSnapshot> getDocument(
    DocumentReference docRef, {
    Source source = Source.cache,
    bool isRefreshEmptyCache = true,
  }) async {
    DocumentSnapshot doc;
    try {
      doc = await docRef.get(GetOptions(source: source));
      if (doc.data() == null && isRefreshEmptyCache) doc = await docRef.get();
    } on FirebaseException {
      // Document cache is unavailable so we fallback to default get document behavior.
      doc = await docRef.get();
    }

    return doc;
  }

  /// Fetch documents with read read from cache first then server.
  ///
  /// This method takes in a [query] which is the usual Firestore [Query] object
  /// used to query a collection, and a [cacheDocRef] which is the [DocumentReference]
  /// object of the document containing a [firestoreCacheField] field of timestamp.
  /// You can also pass in [localCacheKey] as the key for storing the last local
  /// cache date, and [isUpdateCacheDate] to set if it should update the last local
  /// cache date to current date and time.
  static Future<QuerySnapshot> getDocuments({
    required Query query,
    required DocumentReference cacheDocRef,
    required String firestoreCacheField,
    String? localCacheKey,
    bool isUpdateCacheDate = true,
  }) async {
    localCacheKey = localCacheKey ?? firestoreCacheField;

    final isFetch = await isFetchDocuments(
      cacheDocRef,
      firestoreCacheField,
      localCacheKey,
    );
    final src = isFetch ? Source.serverAndCache : Source.cache;
    var snapshot = await query.get(GetOptions(source: src));

    // If it is triggered to get documents from cache but the documents do not exist,
    // which means documents may have been removed from cache,
    // we then fallback to default get documents behavior.
    if (src == Source.cache && snapshot.docs.isEmpty) {
      snapshot = await query.get();
    }

    // If it is set to update cache date, and there are documents in the snapshot, and
    // at least one of the documents was retrieved from the server,
    // update the latest local cache date.
    if (isUpdateCacheDate &&
        snapshot.docs.isNotEmpty &&
        snapshot.docs.any((doc) => doc.metadata.isFromCache == false)) {
      var prefs = await SharedPreferences.getInstance();
      await prefs.setString(localCacheKey, DateTime.now().toIso8601String());
    }

    return snapshot;
  }

  @visibleForTesting
  static Future<bool> isFetchDocuments(
    DocumentReference cacheDocRef,
    String firestoreCacheField,
    String localCacheKey,
  ) async {
    var isFetch = true;
    var prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(localCacheKey);

    if (dateStr != null) {
      final cacheDate = DateTime.parse(dateStr);
      final doc = await cacheDocRef.get();
      final data = doc.data();

      if (!doc.exists) {
        throw CacheDocDoesNotExist();
      } else if (data == null || !data.containsKey(firestoreCacheField)) {
        throw CacheDocFieldDoesNotExist();
      }

      final DateTime latestDate = data[firestoreCacheField].toDate();
      if (latestDate.isBefore(cacheDate)) {
        isFetch = false;
      }
    }

    return isFetch;
  }
}
