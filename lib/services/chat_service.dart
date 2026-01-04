import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> getChatRoomId({
    required String studentId,
    required String studentName,
    required String doctorId,
    required String doctorName,
  }) async {
    final chatId = '${studentId}_$doctorId';
    final docRef = _db.collection('chats').doc(chatId);

    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'studentId': studentId,
        'studentName': studentName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'lastMessage': 'Chat started',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [studentId, doctorId], 
      });
    }
    return chatId;
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    if (text.trim().isEmpty) return;

    final batch = _db.batch();
    
    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final roomRef = _db.collection('chats').doc(chatId);
    batch.update(roomRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<ChatRoomModel>> getUserChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteChat(String chatId) async {
    await _db.collection('chats').doc(chatId).delete();
  }
}