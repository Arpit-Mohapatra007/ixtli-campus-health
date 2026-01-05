import 'package:campus_health/providers/auth_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatMessagesProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatServiceProvider).getMessages(chatId);
});

final myChatsProvider = StreamProvider.autoDispose<List<ChatRoomModel>>((ref) {
  final user = ref.watch(authStateProvider).value; 
  if (user == null) return const Stream.empty();
  
  return ref.read(chatServiceProvider).getUserChats(user.uid);
});