import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firestore_cache/firestore_cache.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Cache Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _firestore = FirebaseFirestore.instance;
  late Future<DocumentSnapshot> _futureDoc;
  late Future<QuerySnapshot> _futureSnapshot;

  @override
  void initState() {
    super.initState();
    _futureDoc = _getDoc();
    _futureSnapshot = _getDocs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore Cache Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _buildDoc(),
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

        return CircularProgressIndicator();
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

        return CircularProgressIndicator();
      },
    );
  }

  Future<DocumentSnapshot> _getDoc() async {
    final docRef = _firestore.doc('users/user');
    final doc = await FirestoreCache.getDocument(docRef);

    return doc;
  }

  Future<QuerySnapshot> _getDocs() async {
    final cacheDocRef = _firestore.doc('status/status');
    final cacheField = 'updatedAt';
    final query = _firestore.collection('posts');
    final snapshot = await FirestoreCache.getDocuments(
      query: query,
      cacheDocRef: cacheDocRef,
      firestoreCacheField: cacheField,
    );

    return snapshot;
  }
}
