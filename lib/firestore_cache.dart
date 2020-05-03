library firestore_cache;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreCache {
  final DocumentReference cacheDocRef;
  final String firestoreCacheKey;
  final String localCacheKey;

  FirestoreCache(this.cacheDocRef, this.firestoreCacheKey, [localCacheKey])
      : localCacheKey = localCacheKey ?? firestoreCacheKey;

  Future<DocumentSnapshot> getDocument(DocumentReference docRef) async {
    final Source src = await _getSource();
    DocumentSnapshot doc = await docRef.get(source: src);

    // If it was triggered to get document from cache but the document does not exist,
    // which means the document may be removed from cache,
    // we then fallback to default get document behavior.
    if (src == Source.cache && !doc.exists) {
      doc = await docRef.get();
    }

    if (doc.exists && !doc.metadata.isFromCache) {
      await _updateCacheKey();
    }

    return doc;
  }

  Future<QuerySnapshot> getDocuments(Query query) async {
    final Source src = await _getSource();
    QuerySnapshot snapshot = await query.getDocuments(source: src);

    // If it was triggered to get documents from cache but the documents do not exist,
    // which means documents may be removed from cache,
    // we then fallback to default get documents behavior.
    if (src == Source.cache && snapshot.documents.isEmpty) {
      snapshot = await query.getDocuments();
    }

    if (snapshot.documents.isNotEmpty &&
        snapshot.documents
            .any((DocumentSnapshot doc) => !doc.metadata.isFromCache)) {
      await _updateCacheKey();
    }

    return snapshot;
  }

  Future<Source> _getSource() async {
    Source src;
    final bool isFetch = await _isFetch();

    if (isFetch) {
      src = Source.serverAndCache;
    } else {
      src = Source.cache;
    }

    return src;
  }

  Future<bool> _isFetch() async {
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

  Future<void> _updateCacheKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(localCacheKey, DateTime.now().toIso8601String());
  }
}
