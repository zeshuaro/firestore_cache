## 2.2.1

* **docs**: Updated readme and documentation

## 2.2.0

* **chore**: Updated `cloud_firestore: ^3.0.0`

## 2.1.1

* **feat**: Added to parse server date string type for the `firestoreCacheField` in `getDocuments`

## 2.1.0

* **fix**: Fixed types mismatch between `firestore_cache` and `cloud_firestore`
* **BREAKING**: Added `Map<String, dynamic>` type to `DocumentReference`, `DocumentSnapshot`, `Query` and `QuerySnapshot`

* **BREAKING**: `getDocument` had been updated with the following function signature:
  ```dart
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> docRef, {
    Source source = Source.cache,
    bool isRefreshEmptyCache = true,
  });
  ```

* **BREAKING**: `getDocuments` had been updated with the following function signature:
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

* **chore**: Updated `cloud_firestore: ^2.0.0`
* **chore**: Updated `shared_preferences: ^2.0.0`

## 1.0.0+1

* **docs**: Updated readme

## 1.0.0

* **BREAKING**: Opted into null safety
* **chore**: Updated `cloud_firestore: ">=1.0.3 <1.1.0"`
* **chore**: Updated `shared_preferences: ">=2.0.0 <2.1.0"`

## 0.3.0

* **chore**: Updated `cloud_firestore: ">=0.16.0 <0.17.0"`
* **chore**: Removeed dependency `meta`

## 0.2.0+1

* **chore**: Updated `cloud_firestore: ">=0.14.0 <0.15.0"`
* **chore**: Updated `meta: ">=1.0.0 <1.3.1"`
* **chore**: Updated `shared_preferences: ">=0.5.0 <2.0.0"`
* **chore**: Removed dependency `firebase_core`

## 0.2.0

* **chore**: Updated `cloud_firestore >= 0.14.0`

## 0.1.1

* **feat**: Added option to re-fetch document from the server if the cached document is empty

## 0.1.0 

* Initial release
