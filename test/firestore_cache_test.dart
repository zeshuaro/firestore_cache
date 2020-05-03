import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_mocks/cloud_firestore_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firestore_cache/firestore_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const String cacheKey = 'updatedAt';
  SharedPreferences.setMockInitialValues({});

  test('Test document exists', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');
    await cacheDocRef
        .setData(<String, dynamic>{cacheKey: DateTime(2020, 1, 2)});

    final DocumentReference dataDocRef =
        firestore.collection('data').document();
    await dataDocRef.setData(<String, dynamic>{'hello': 'world'});

    final firestoreCache = FirestoreCache(cacheDocRef, cacheKey);
    final DocumentSnapshot doc = await firestoreCache.getDocument(dataDocRef);
    expect(doc.exists, true);
  });

  test('Test document does not exist', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');
    await cacheDocRef
        .setData(<String, dynamic>{cacheKey: DateTime(2020, 1, 2)});

    final DocumentReference dataDocRef =
        firestore.collection('data').document();

    final firestoreCache = FirestoreCache(cacheDocRef, cacheKey);
    final DocumentSnapshot doc = await firestoreCache.getDocument(dataDocRef);
    expect(doc.exists, false);
  });

  test('Test documents exists', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');
    await cacheDocRef
        .setData(<String, dynamic>{cacheKey: DateTime(2020, 1, 2)});

    await firestore.collection('data').add(<String, dynamic>{'hello': 'world'});
    await firestore
        .collection('data')
        .add(<String, dynamic>{'hello': 'world again'});

    final firestoreCache = FirestoreCache(cacheDocRef, cacheKey);
    final Query query = firestore.collection('data');
    final QuerySnapshot snapshot = await firestoreCache.getDocuments(query);
    expect(snapshot.documents.isNotEmpty, true);
  });

  test('Test documents do not exist', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');
    await cacheDocRef
        .setData(<String, dynamic>{cacheKey: DateTime(2020, 1, 2)});

    final firestoreCache = FirestoreCache(cacheDocRef, cacheKey);
    final Query query = firestore.collection('data');
    final QuerySnapshot snapshot = await firestoreCache.getDocuments(query);
    expect(snapshot.documents.isEmpty, true);
  });

  test('Test cache collection does not exist', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');

    final DocumentReference dataDocRef =
        firestore.collection('data').document();
    await dataDocRef.setData(<String, dynamic>{'hello': 'world'});

    final firestoreCache = FirestoreCache(cacheDocRef, cacheKey);
    final DocumentSnapshot doc = await firestoreCache.getDocument(dataDocRef);
    expect(doc.exists, true);
  });

  test('Test cache document does not exist', () async {
    final firestore = MockFirestoreInstance();
    final DocumentReference cacheDocRef =
        firestore.collection('cache').document('cache');
    await cacheDocRef.setData(<String, dynamic>{'hello': 'world'});

    final DocumentReference dataDocRef =
        firestore.collection('data').document();
    await dataDocRef.setData(<String, dynamic>{'hello': 'world'});

    final firestoreCache = FirestoreCache(cacheDocRef, cacheKey);
    final DocumentSnapshot doc = await firestoreCache.getDocument(dataDocRef);
    expect(doc.exists, true);
  });
}
