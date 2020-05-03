import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_mocks/cloud_firestore_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firestore_cache/firestore_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const String docCacheKey = 'isFetchDoc';
  const String docsCacheKey = 'updatedAt';
  SharedPreferences.setMockInitialValues({});

  test('Test document exists', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference dataDocRef =
        firestore.collection('data').document();
    await dataDocRef.setData(<String, dynamic>{'hello': 'world'});

    final DocumentSnapshot doc = await FirestoreCache.getDocument(
      docRef: dataDocRef,
      cacheKey: docCacheKey,
    );
    expect(doc.exists, true);
  });

  test('Test document does not exist', () async {
    final firestore = MockFirestoreInstance();

    final DocumentReference dataDocRef =
        firestore.collection('data').document();
    final DocumentSnapshot doc = await FirestoreCache.getDocument(
      docRef: dataDocRef,
      cacheKey: docCacheKey,
    );
    expect(doc.exists, false);
  });

  test('Test documents exists', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');
    await cacheDocRef
        .setData(<String, dynamic>{docsCacheKey: DateTime(2020, 1, 2)});

    await firestore.collection('data').add(<String, dynamic>{'hello': 'world'});
    await firestore
        .collection('data')
        .add(<String, dynamic>{'hello': 'world again'});

    final Query query = firestore.collection('data');
    final QuerySnapshot snapshot = await FirestoreCache.getDocuments(
      query: query,
      cacheDocRef: cacheDocRef,
      firestoreCacheKey: docsCacheKey,
    );
    expect(snapshot.documents.isNotEmpty, true);
  });

  test('Test documents do not exist', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');
    await cacheDocRef
        .setData(<String, dynamic>{docsCacheKey: DateTime(2020, 1, 2)});

    final Query query = firestore.collection('data');
    final QuerySnapshot snapshot = await FirestoreCache.getDocuments(
      query: query,
      cacheDocRef: cacheDocRef,
      firestoreCacheKey: docsCacheKey,
    );
    expect(snapshot.documents.isEmpty, true);
  });

  test('Test cache collection does not exist', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');

    await firestore.collection('data').add(<String, dynamic>{'hello': 'world'});
    await firestore
        .collection('data')
        .add(<String, dynamic>{'hello': 'world again'});

    final Query query = firestore.collection('data');
    final QuerySnapshot snapshot = await FirestoreCache.getDocuments(
      query: query,
      cacheDocRef: cacheDocRef,
      firestoreCacheKey: docsCacheKey,
    );
    expect(snapshot.documents.isNotEmpty, true);
  });

  test('Test cache document field does not exist', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');
    await cacheDocRef.setData(<String, dynamic>{'hello': 'world'});

    await firestore.collection('data').add(<String, dynamic>{'hello': 'world'});
    await firestore
        .collection('data')
        .add(<String, dynamic>{'hello': 'world again'});

    final Query query = firestore.collection('data');
    final QuerySnapshot snapshot = await FirestoreCache.getDocuments(
      query: query,
      cacheDocRef: cacheDocRef,
      firestoreCacheKey: docsCacheKey,
    );
    expect(snapshot.documents.isNotEmpty, true);
  });
}
