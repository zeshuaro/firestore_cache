import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exceptions.dart';

/// FirestoreCache is a Flutter plugin for fetching Firestore documents with
/// read from cache first then server.
///
/// Before using this plugin, you will need to do some inital setup on
/// Firestore. Then you can use this sample code to fetch documents:
///
/// ```dart
/// import 'package:cloud_firestore/cloud_firestore.dart';
/// import 'package:firestore_cache/firestore_cache.dart';
///
/// // This should be the path of the document containing the timestampe field
/// // that you created
/// final cacheDocRef = Firestore.instance.doc('status/status');
///
/// // This should be the timestamp field in that document
/// final cacheField = 'updatedAt';
///
/// final query = Firestore.instance.collection('posts');
/// final snapshot = await FirestoreCache.getDocuments(
///     query: query,
///     cacheDocRef: cacheDocRef,
///     firestoreCacheField: cacheField,
/// );
/// ```
///
class FirestoreCache {
  /// Fetch a document with read from cache first then server.
  ///
  /// This method takes in a [docRef] which is the usual [DocumentReference]
  /// object on Firestore used for retrieving a single document. It tries to
  /// fetch the document from the cache first, and fallback to retrieving from
  /// the server if it fails to do so.
  ///
  /// It also takes in the optional arguments [source] which you can force it to
  /// fetch the document from the server, and [isRefreshEmptyCache] to refresh
  /// the cached document from the server if it is empty.
  ///
  /// This method should only be used if the document you are fetching does not
  /// change over time. Once the document is cached, it will always be read from
  /// the cache.
  static Future<DocumentSnapshot<T>> getDocument<T>(
    DocumentReference<T> docRef, {
    Source source = Source.cache,
    bool isRefreshEmptyCache = true,
  }) async {
    DocumentSnapshot<T> doc;

    try {
      doc = await docRef.get(GetOptions(source: source));
      if (doc.data() == null && isRefreshEmptyCache) doc = await docRef.get();
    } on FirebaseException {
      // Document cache is unavailable so we fallback to default get document
      // behavior.
      doc = await docRef.get();
    }

    return doc;
  }

  /// Fetch documents with read read from cache first then server.
  ///
  /// This method takes in a [query] which is the usual Firestore [Query] object
  /// used to query a collection, and a [cacheDocRef] which is the timestamp
  /// [DocumentReference] object of the document containing the
  /// [firestoreCacheField] field of [Timestamp] or [String]. If the field is a
  /// [String], it must be parsable by [DateTime.parse]. Otherwise
  /// [FormatException] will be thrown.
  ///
  /// If [cacheDocRef] does not exist, [CacheDocDoesNotExist] will be thrown.
  /// And if [firestoreCacheField] does not exist, [CacheDocFieldDoesNotExist]
  /// will be thrown.
  ///
  /// You can also pass in [localCacheKey] as the key for storing the last local
  /// cache date, and [isUpdateCacheDate] to set if it should update the last
  /// local cache date to current date and time.
  ///
  /// If you are using firestore collection withConverter then you have to also
  /// pass toFirestore method to converter
  static Future<QuerySnapshot<T>> getDocuments<T>({
    required Query<T> query,
    required DocumentReference<T> cacheDocRef,
    required String firestoreCacheField,
    String? localCacheKey,
    bool isUpdateCacheDate = true,
    Map<String, Object?> Function(T value, SetOptions? options)? converter,
  }) async {
    if (cacheDocRef is! DocumentReference<Map<String, dynamic>>) {
      assert(
        converter != null,
        "converter should not be null if cacheDocRef's collection is initiated with withConverter method ",
      );
    }

    localCacheKey = localCacheKey ?? firestoreCacheField;

    final isFetch = await isFetchDocuments(
      cacheDocRef,
      firestoreCacheField,
      localCacheKey,
      converter: converter,
    );
    final src = isFetch ? Source.serverAndCache : Source.cache;
    var snapshot = await query.get(GetOptions(source: src));

    // If it is triggered to get documents from cache but the documents do not
    // exist, which means documents may have been removed from cache, we then
    // fallback to default get documents behavior.
    if (src == Source.cache && snapshot.docs.isEmpty) {
      snapshot = await query.get();
    }

    // If it is set to update cache date, and there are documents in the
    // snapshot, and at least one of the documents was retrieved from the
    // server, update the latest local cache date.
    if (isUpdateCacheDate &&
        snapshot.docs.isNotEmpty &&
        snapshot.docs.any((doc) => doc.metadata.isFromCache == false)) {
      var prefs = await SharedPreferences.getInstance();
      await prefs.setString(localCacheKey, DateTime.now().toIso8601String());
    }

    return snapshot;
  }

  @visibleForTesting
  static Future<bool> isFetchDocuments<T>(
    DocumentReference<T> cacheDocRef,
    String firestoreCacheField,
    String localCacheKey, {
    Map<String, Object?> Function(T value, SetOptions? options)? converter,
  }) async {
    var isFetch = true;
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(localCacheKey);

    if (dateStr != null) {
      final cacheDate = DateTime.parse(dateStr);
      final doc = await cacheDocRef.get();
      final data = doc.data();

      if (!doc.exists || data == null) {
        throw CacheDocDoesNotExist();
      }

      final dynamic serverDateRaw;

      if (doc is DocumentSnapshot<Map<String, dynamic>>) {
        if (!(data as Map).containsKey(firestoreCacheField)) {
          throw CacheDocFieldDoesNotExist();
        }

        serverDateRaw = data[firestoreCacheField];
      } else {
        final newData = converter!(data, null);

        if (!(newData).containsKey(firestoreCacheField)) {
          throw CacheDocFieldDoesNotExist();
        }

        serverDateRaw = newData[firestoreCacheField];
      }

      DateTime? serverDate;

      if (serverDateRaw is Timestamp) {
        serverDate = serverDateRaw.toDate();
      } else if (serverDateRaw is String) {
        serverDate = DateTime.tryParse(serverDateRaw);
      }

      if (serverDate == null) {
        throw FormatException('Invalid date format', serverDateRaw);
      } else if (serverDate.isBefore(cacheDate) == true) {
        isFetch = false;
      }
    }

    return isFetch;
  }
}
