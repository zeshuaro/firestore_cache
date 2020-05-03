library firestore_cache;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreCache {
  static Future<DocumentSnapshot> getDocument({
    @required DocumentReference docRef,
    @required String cacheKey,
  }) async {
    assert(docRef != null && cacheKey != null);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool cacheIsFetch = prefs.getBool(cacheKey);
    final bool isFetch = cacheIsFetch == true || cacheIsFetch == null;

    final Source src = isFetch ? Source.serverAndCache : Source.cache;
    DocumentSnapshot doc = await docRef.get(source: src);

    // If it was triggered to get document from cache but the document does not exist,
    // which means the document may have been removed from cache,
    // we then fallback to default get document behavior.
    if (src == Source.cache && !doc.exists) {
      doc = await docRef.get();
    }

    await prefs.setBool(cacheKey, false);

    return doc;
  }

  static Future<QuerySnapshot> getDocuments({
    @required Query query,
    @required DocumentReference cacheDocRef,
    @required String firestoreCacheKey,
    String localCacheKey,
  }) async {
    assert(query != null && cacheDocRef != null && firestoreCacheKey != null);
    localCacheKey = localCacheKey ?? firestoreCacheKey;

    final Source src =
        await _getSource(cacheDocRef, firestoreCacheKey, localCacheKey);
    QuerySnapshot snapshot = await query.getDocuments(source: src);

    // If it was triggered to get documents from cache but the documents do not exist,
    // which means documents may be removed from cache,
    // we then fallback to default get documents behavior.
    if (src == Source.cache && snapshot.documents.isEmpty) {
      snapshot = await query.getDocuments();
    }

    if (snapshot.documents.isNotEmpty &&
        snapshot.documents.any(
            (DocumentSnapshot doc) => doc.metadata?.isFromCache == false)) {
      await _updateCacheKey(localCacheKey);
    }

    return snapshot;
  }

  static Future<Source> _getSource(
    DocumentReference cacheDocRef,
    String firestoreCacheKey,
    String localCacheKey,
  ) async {
    Source src;
    final bool isFetch =
        await _isFetch(cacheDocRef, firestoreCacheKey, localCacheKey);

    if (isFetch) {
      src = Source.serverAndCache;
    } else {
      src = Source.cache;
    }

    return src;
  }

  static Future<bool> _isFetch(
    DocumentReference cacheDocRef,
    String firestoreCacheKey,
    String localCacheKey,
  ) async {
    bool isFetch = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String dateStr = prefs.getString(localCacheKey);

    if (dateStr != null) {
      final DateTime cacheDate = DateTime.parse(dateStr);
      final DocumentSnapshot doc = await cacheDocRef.get();

      if (doc.exists && doc.data.containsKey(firestoreCacheKey)) {
        final DateTime latestDate = doc.data[firestoreCacheKey].toDate();
        if (latestDate.isBefore(cacheDate)) {
          isFetch = false;
        }
      }
    }

    return isFetch;
  }

  static Future<void> _updateCacheKey(String localCacheKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(localCacheKey, DateTime.now().toIso8601String());
  }
}
