import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_cache/firestore_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: subtype_of_sealed_class
class MockQuery<Map> extends Mock implements Query<Map> {}

class MockQuerySnapshot<Map> extends Mock implements QuerySnapshot<Map> {}

// ignore: subtype_of_sealed_class
class MockQueryDocumentSnapshot<Map> extends Mock
    implements QueryDocumentSnapshot<Map> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference<Map> extends Mock
    implements DocumentReference<Map> {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot<Map> extends Mock implements DocumentSnapshot<Map> {}

class MockSnapshotMetadata extends Mock implements SnapshotMetadata {}

void main() {
  const cacheField = 'updatedAt';
  final data = {'firestore': 'cache'};
  final mockCacheDocRef = MockDocumentReference<Map<String, dynamic>>();
  final mockCacheSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

  when(() => mockCacheDocRef.get()).thenAnswer((_) {
    return Future.value(mockCacheSnapshot);
  });

  group('testGetDocument', () {
    final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
    final mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final mockMetadata = MockSnapshotMetadata();

    when(() => mockSnapshot.data()).thenReturn(data);
    when(() => mockSnapshot.metadata).thenReturn(mockMetadata);

    test('testGetFromServer', () async {
      when(() => mockDocRef.get(any())).thenAnswer((_) {
        return Future.value(mockSnapshot);
      });
      when(() => mockMetadata.isFromCache).thenReturn(false);

      final doc = await FirestoreCache.getDocument(
        mockDocRef,
        source: Source.server,
      );

      expect(doc.metadata.isFromCache, false);
      expect(doc.data(), data);
      verify(() {
        return mockDocRef.get(any(that: isInstanceOf<GetOptions>()));
      }).called(1);
    });

    test('testGetFromCache', () async {
      when(() => mockDocRef.get(any())).thenAnswer((_) {
        return Future.value(mockSnapshot);
      });
      when(() => mockMetadata.isFromCache).thenReturn(true);

      final doc = await FirestoreCache.getDocument(
        mockDocRef,
        source: Source.cache,
      );

      expect(doc.metadata.isFromCache, true);
      expect(doc.data(), data);
      verify(() {
        return mockDocRef.get(any(that: isInstanceOf<GetOptions>()));
      }).called(1);
    });

    test('testGetFromCacheFallbackToServer', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(() => mockDocRef.get(any())).thenThrow(
        FirebaseException(plugin: 'test'),
      );
      when(() => mockDocRef.get()).thenAnswer((_) {
        return Future.value(mockSnapshot);
      });
      when(() => mockMetadata.isFromCache).thenReturn(false);

      final doc = await FirestoreCache.getDocument(
        mockDocRef,
        source: Source.cache,
      );

      expect(doc.metadata.isFromCache, false);
      expect(doc.data(), data);
      verify(() {
        return mockDocRef.get(any(that: isInstanceOf<GetOptions>()));
      }).called(1);
      verify(() => mockDocRef.get()).called(1);
    });

    test('testGetFromCacheNullAndRefresh', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockSnapshotNull = MockDocumentSnapshot<Map<String, dynamic>>();

      when(() => mockDocRef.get(any())).thenAnswer((_) {
        return Future.value(mockSnapshotNull);
      });
      when(() => mockDocRef.get()).thenAnswer((_) {
        return Future.value(mockSnapshot);
      });
      when(() => mockSnapshotNull.data()).thenReturn(null);
      when(() => mockMetadata.isFromCache).thenReturn(false);

      final doc = await FirestoreCache.getDocument(
        mockDocRef,
        source: Source.cache,
        isRefreshEmptyCache: true,
      );

      expect(doc.metadata.isFromCache, false);
      expect(doc.data(), data);
      verify(() {
        return mockDocRef.get(any(that: isInstanceOf<GetOptions>()));
      }).called(1);
      verify(() => mockDocRef.get()).called(1);
    });

    test('testGetFromCacheNullAndNotRefresh', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockSnapshotNull = MockDocumentSnapshot<Map<String, dynamic>>();

      when(() => mockDocRef.get(any())).thenAnswer((_) {
        return Future.value(mockSnapshotNull);
      });
      when(() => mockSnapshotNull.data()).thenReturn(null);

      final doc = await FirestoreCache.getDocument(
        mockDocRef,
        source: Source.cache,
        isRefreshEmptyCache: false,
      );

      expect(doc.data(), null);
      verify(() {
        return mockDocRef.get(any(that: isInstanceOf<GetOptions>()));
      }).called(1);
      verifyNever(() => mockDocRef.get());
    });
  });

  group('testGetDocuments', () {
    final mockQuery = MockQuery<Map<String, dynamic>>();
    final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    final mockQueryMetadata = MockSnapshotMetadata();
    final mockDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
    final mockDocMetadata = MockSnapshotMetadata();

    when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
    when(() => mockQuerySnapshot.metadata).thenReturn(mockQueryMetadata);
    when(() => mockDocSnapshot.data()).thenReturn(data);
    when(() => mockDocSnapshot.metadata).thenReturn(mockDocMetadata);
    when(() => mockCacheSnapshot.exists).thenReturn(true);

    test('testGetUpToDateCache', () async {
      when(() => mockQuery.get(any())).thenAnswer((_) {
        return Future.value(mockQuerySnapshot);
      });
      when(() => mockQueryMetadata.isFromCache).thenReturn(true);
      when(() => mockDocMetadata.isFromCache).thenReturn(true);

      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        cacheField: now.toIso8601String(),
      });
      final updatedAt = now.subtract(const Duration(seconds: 1));
      when(() => mockCacheSnapshot.data()).thenReturn({
        cacheField: Timestamp.fromDate(updatedAt),
      });

      final snapshot = await FirestoreCache.getDocuments(
        query: mockQuery,
        cacheDocRef: mockCacheDocRef,
        firestoreCacheField: cacheField,
      );
      final doc = snapshot.docs.first;

      expect(snapshot.metadata.isFromCache, true);
      expect(doc.data(), data);
      expect(doc.metadata.isFromCache, true);
      verify(() {
        return mockQuery.get(any(that: isInstanceOf<GetOptions>()));
      }).called(1);
    });

    test('testGetFromCacheFallbackToServer', () async {
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final emptyMockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(() => mockQuery.get(any())).thenAnswer((_) {
        return Future.value(emptyMockQuerySnapshot);
      });
      when(() => mockQuery.get()).thenAnswer((_) {
        return Future.value(mockQuerySnapshot);
      });
      when(() => emptyMockQuerySnapshot.docs).thenReturn([]);
      when(() => mockQueryMetadata.isFromCache).thenReturn(false);
      when(() => mockDocMetadata.isFromCache).thenReturn(false);

      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        cacheField: now.toIso8601String(),
      });
      final updatedAt = now.subtract(const Duration(seconds: 1));
      when(() => mockCacheSnapshot.data()).thenReturn({
        cacheField: Timestamp.fromDate(updatedAt),
      });

      final snapshot = await FirestoreCache.getDocuments(
        query: mockQuery,
        cacheDocRef: mockCacheDocRef,
        firestoreCacheField: cacheField,
      );
      final doc = snapshot.docs.first;

      expect(snapshot.metadata.isFromCache, false);
      expect(doc.data(), data);
      expect(doc.metadata.isFromCache, false);
      verify(() {
        return mockQuery.get(any(that: isInstanceOf<GetOptions>()));
      }).called(1);
      verify(() => mockQuery.get()).called(1);
    });
  });

  group('testIsFetchDocuments', () {
    test('testLocalCacheDateNull', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await FirestoreCache.isFetchDocuments(
        mockCacheDocRef,
        cacheField,
        cacheField,
      );

      expect(result, true);
    });

    test('testLocalCacheDateUpToDate', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        cacheField: now.toIso8601String(),
      });
      final updatedAt = now.subtract(const Duration(seconds: 1));
      when(() => mockCacheSnapshot.data()).thenReturn({
        cacheField: Timestamp.fromDate(updatedAt),
      });

      final result = await FirestoreCache.isFetchDocuments(
        mockCacheDocRef,
        cacheField,
        cacheField,
      );

      expect(result, false);
    });

    test('testLocalCacheDateOutdated', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        cacheField: now.toIso8601String(),
      });
      final updatedAt = now.add(const Duration(seconds: 1));
      when(() => mockCacheSnapshot.data()).thenReturn({
        cacheField: Timestamp.fromDate(updatedAt),
      });

      final result = await FirestoreCache.isFetchDocuments(
        mockCacheDocRef,
        cacheField,
        cacheField,
      );

      expect(result, true);
    });

    test('testServerDateString', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        cacheField: now.toIso8601String(),
      });
      final updatedAt = now.add(const Duration(seconds: 1));
      when(() => mockCacheSnapshot.data()).thenReturn({
        cacheField: updatedAt.toIso8601String(),
      });

      final result = await FirestoreCache.isFetchDocuments(
        mockCacheDocRef,
        cacheField,
        cacheField,
      );

      expect(result, true);
    });

    test('testCacheDocRefNotExist', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        cacheField: now.toIso8601String(),
      });
      when(() => mockCacheSnapshot.data()).thenReturn({});
      when(() => mockCacheSnapshot.exists).thenReturn(false);

      expect(
        () async => await FirestoreCache.isFetchDocuments(
          mockCacheDocRef,
          cacheField,
          cacheField,
        ),
        throwsA(isInstanceOf<CacheDocDoesNotExist>()),
      );
    });

    test('testFirebaseCacheFieldNotExist', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        cacheField: now.toIso8601String(),
      });
      when(() => mockCacheSnapshot.data()).thenReturn({});
      when(() => mockCacheSnapshot.exists).thenReturn(true);

      expect(
        () async => await FirestoreCache.isFetchDocuments(
          mockCacheDocRef,
          cacheField,
          cacheField,
        ),
        throwsA(isInstanceOf<CacheDocFieldDoesNotExist>()),
      );
    });

    test('testInvalidServerDateFormat', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        cacheField: now.toIso8601String(),
      });
      when(() => mockCacheSnapshot.data()).thenReturn({
        cacheField: 'invalidDateFormat',
      });

      expect(
        () async => await FirestoreCache.isFetchDocuments(
          mockCacheDocRef,
          cacheField,
          cacheField,
        ),
        throwsA(isInstanceOf<FormatException>()),
      );
    });
  });
}
