import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firestore_cache/firestore_cache.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Cache Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _firestore = FirebaseFirestore.instance;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _futureDoc;
  late Future<QuerySnapshot<Map<String, dynamic>>> _futureSnapshot;

  @override
  void initState() {
    super.initState();
    _futureDoc = _getDoc();
    _futureSnapshot = _getDocs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Cache Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text('Get single document'),
            _buildDoc(),
            const Divider(),
            const Text('Get collection of documents'),
            _buildDocs(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoc() {
    return FutureBuilder<DocumentSnapshot>(
      future: _futureDoc,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('${snapshot.error}');
        } else if (snapshot.hasData) {
          final doc = snapshot.data!;
          final data = doc.data() as Map?;

          return Text(
            '${data!['userId']} isFromCache: ${doc.metadata.isFromCache}',
          );
        }

        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildDocs() {
    return FutureBuilder<QuerySnapshot>(
      future: _futureSnapshot,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('${snapshot.error}');
        } else if (snapshot.hasData) {
          final docs = snapshot.data?.docs;
          return Expanded(
            child: ListView(
              children: docs!.map((DocumentSnapshot doc) {
                final data = doc.data() as Map?;
                return Text(
                  '${data!['postId']} isFromCache: ${doc.metadata.isFromCache}',
                  textAlign: TextAlign.center,
                );
              }).toList(),
            ),
          );
        }

        return const CircularProgressIndicator();
      },
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getDoc() async {
    final docRef = _firestore.doc('users/user');
    final doc = await FirestoreCache.getDocument(docRef);

    return doc;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getDocs() async {
    const cacheField = 'updatedAt';
    final cacheDocRef = _firestore.doc('status/status');
    final query = _firestore.collection('posts');
    final snapshot = await FirestoreCache.getDocuments(
      query: query,
      cacheDocRef: cacheDocRef,
      firestoreCacheField: cacheField,
    );

    return snapshot;
  }
}
