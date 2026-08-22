import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get queriesCollection => _firestore.collection('queries');
  CollectionReference get responsesCollection => _firestore.collection('responses');
  CollectionReference get revealsCollection => _firestore.collection('reveals');
  CollectionReference get reportsCollection => _firestore.collection('reports');

  // --- USER PROFILE OPERATIONS ---

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String role, // 'JUNIOR' | 'SENIOR' | 'ADMIN'
    String? branch,
    int? graduationYear,
    String? bio,
    List<String>? skills,
  }) async {
    await usersCollection.doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'branch': branch ?? '',
      'graduationYear': graduationYear,
      'bio': bio ?? '',
      'skills': skills ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await usersCollection.doc(uid).get();
  }

  Stream<DocumentSnapshot> streamUserProfile(String uid) {
    return usersCollection.doc(uid).snapshots();
  }

  // --- QUERY / QUESTION FEED OPERATIONS ---

  Future<String> createQuery({
    required String authorUid,
    required String authorName,
    required String title,
    required String content,
    required String category,
    required String targetBranch,
    required int targetGraduationYear,
    bool isAnonymous = true,
  }) async {
    DocumentReference docRef = await queriesCollection.add({
      'authorUid': authorUid,
      'authorName': isAnonymous ? 'Anonymous Junior' : authorName,
      'title': title,
      'content': content,
      'category': category,
      'targetBranch': targetBranch,
      'targetGraduationYear': targetGraduationYear,
      'isAnonymous': isAnonymous,
      'responseCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<QuerySnapshot> streamQueries({String? category, String? branch}) {
    Query query = queriesCollection.orderBy('createdAt', descending: true);
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (branch != null && branch.isNotEmpty) {
      query = query.where('targetBranch', isEqualTo: branch);
    }
    return query.snapshots();
  }

  // --- RESPONSE OPERATIONS ---

  Future<String> addResponse({
    required String queryId,
    required String authorUid,
    required String authorName,
    required String content,
    bool isAnonymous = false,
  }) async {
    DocumentReference docRef = await responsesCollection.add({
      'queryId': queryId,
      'authorUid': authorUid,
      'authorName': isAnonymous ? 'Anonymous Senior' : authorName,
      'content': content,
      'isAnonymous': isAnonymous,
      'upvotes': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment response counter on query document
    await queriesCollection.doc(queryId).update({
      'responseCount': FieldValue.increment(1),
    });

    return docRef.id;
  }

  Stream<QuerySnapshot> streamResponsesForQuery(String queryId) {
    return responsesCollection
        .where('queryId', isEqualTo: queryId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
