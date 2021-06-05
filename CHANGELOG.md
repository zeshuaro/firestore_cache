## 2.1.1

* Add to parse server date string type for the `firestoreCacheField` in `getDocuments`

## 2.1.0

* **fix**: Fix types mismatch between `firestore_cache` and `cloud_firestore`
* **BREAKING**: Add `Map<String, dynamic>` type to `DocumentReference`, `DocumentSnapshot`, `Query` and `QuerySnapshot`

* **BREAKING**: `getDocument` has been updated with the following function signature:
  ```dart
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> docRef, {
    Source source = Source.cache,
    bool isRefreshEmptyCache = true,
  });
  ```

* **BREAKING**: `getDocuments` has been updated with the following function signature:
  ```dart
  Future<QuerySnapshot<Map<String, dynamic>>> getDocuments({
    required Query<Map<String, dynamic>> query,
    required DocumentReference<Map<String, dynamic>> cacheDocRef,
    required String firestoreCacheField,
    String? localCacheKey,
    bool isUpdateCacheDate = true,
  });
  ```

## 2.0.0

* **chore**: Bump `cloud_firestore: ^2.0.0`
* **chore**: Bump `shared_preferences: ^2.0.0`

## 1.0.0+1

* **docs**: Update readme

## 1.0.0

* **BREAKING**: Opt into null safety
* **chore**: Bump `cloud_firestore: ">=1.0.3 <1.1.0"`
* **chore**: Bump `shared_preferences: ">=2.0.0 <2.1.0"`

## 0.3.0

* **chore**: Bump `cloud_firestore: ">=0.16.0 <0.17.0"`
* **chore**: Remove `meta`

## 0.2.0+1

* **chore**: Bump `cloud_firestore: ">=0.14.0 <0.15.0"`
* **chore**: Bump `meta: ">=1.0.0 <1.3.1"`
* **chore**: Bump `shared_preferences: ">=0.5.0 <2.0.0"`
* **chore**: Remove `firebase_core`

## 0.2.0

* **chore**: Bump `cloud_firestore >= 0.14.0`

## 0.1.1

* **feat**: Add option to re-fetch document from the server if the cached document is empty

## 0.1.0 

* Initial release
