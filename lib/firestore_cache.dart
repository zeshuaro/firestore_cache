library firestore_cache;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreCache {
  static Future<DocumentSnapshot> getDocument(DocumentReference docRef) async {
    DocumentSnapshot doc = await docRef.get(source: Source.cache);

    // If the document does not exist, which means the document
    // may have been removed from cache,
    // we then fallback to default get document behavior.
    if (!doc.exists) {
      doc = await docRef.get();
    }

    return doc;
  }

  static Future<QuerySnapshot> getDocuments({
    @required Query query,
    @required DocumentReference cacheDocRef,
    @required String firestoreCacheField,
    String localCacheKey,
    bool isUpdateCacheDate = true,
  }) async {
    assert(query != null && cacheDocRef != null && firestoreCacheField != null);
    localCacheKey = localCacheKey ?? firestoreCacheField;

    final bool isFetch = await _isFetchDocuments(
        cacheDocRef, firestoreCacheField, localCacheKey);
    final Source src = isFetch ? Source.serverAndCache : Source.cache;
    QuerySnapshot snapshot = await query.getDocuments(source: src);

    // If it is triggered to get documents from cache but the documents do not exist,
    // which means documents may be removed from cache,
    // we then fallback to default get documents behavior.
    if (src == Source.cache && snapshot.documents.isEmpty) {
      snapshot = await query.getDocuments();
    }

    // If it is set to update cache date, and there are documents in the snapshot, and
    // at least one of the documents was retrieved from the server,
    // update the latest local cache date.
    if (isUpdateCacheDate &&
        snapshot.documents.isNotEmpty &&
        snapshot.documents.any(
            (DocumentSnapshot doc) => doc.metadata?.isFromCache == false)) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(localCacheKey, DateTime.now().toIso8601String());
    }

    return snapshot;
  }

  static Future<bool> _isFetchDocuments(
    DocumentReference cacheDocRef,
    String firestoreCacheField,
    String localCacheKey,
  ) async {
    bool isFetch = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String dateStr = prefs.getString(localCacheKey);

    if (dateStr != null) {
      final DateTime cacheDate = DateTime.parse(dateStr);
      final DocumentSnapshot doc = await cacheDocRef.get();

      if (!doc.exists) {
        throw CacheDocDoesNotExist();
      } else if (!doc.data.containsKey(firestoreCacheField)) {
        throw CacheDocFieldDoesNotExist();
      }

      final DateTime latestDate = doc.data[firestoreCacheField].toDate();
      if (latestDate.isBefore(cacheDate)) {
        isFetch = false;
      }
    }

    return isFetch;
  }
}

class CacheDocDoesNotExist implements Exception {
  final String message = '''Your cache document does not exist on Firestore, 
            which means you will always be fetching your documents from the server. 
            Create your cache document on Firestore first 
            with your specified field name of a timestamp.''';

  CacheDocDoesNotExist();

  String toString() {
    return message;
  }
}

class CacheDocFieldDoesNotExist implements Exception {
  final String message =
      '''Your cache document does not contain your specified field, 
            which means you will always be fetching your documents from the server. 
            Create your specified filed name with a timestamp 
            in your cache document on Firestore first.''';

  CacheDocFieldDoesNotExist();

  String toString() {
    return message;
  }
}
