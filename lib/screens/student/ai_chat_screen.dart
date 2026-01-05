import 'package:campus_health/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/chatbot_service.dart';

class AIChatScreen extends HookConsumerWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = useState<List<Map<String, String>>>([]);
    final controller = useTextEditingController();
    final isLoading = useState(false);
    final scrollController = useScrollController();
    final detectedSpecialist = useState<String?>(null);
    final specialists = AppConstants.specialists;

    void scrollToBottom() {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      }
    }

    Future<void> sendMessage() async {
      final text = controller.text.trim();
      if (text.isEmpty) return;

      messages.value = [...messages.value, {'role': 'user', 'text': text}];
      controller.clear();
      isLoading.value = true;
      scrollToBottom();

      try {
        final response = await ChatBotService().getSingleResponse(text);
        final aiText = response ?? "I'm having trouble thinking right now.";

        messages.value = [...messages.value, {'role': 'ai', 'text': aiText}];
        
        detectedSpecialist.value = null; 
        for (final spec in specialists) {
          if (aiText.contains(spec)) {
            detectedSpecialist.value = spec;
            break; 
          }
        }

      } catch (e) {
        messages.value = [...messages.value, {'role': 'ai', 'text': "Connection Error."}];
      } finally {
        isLoading.value = false;
        scrollToBottom();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text("Dr. AI Assistant"),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.yellow[100],
            width: double.infinity,
            child: const Text(
              "(AI can make mistakes. For emergencies, use the SOS button on the home screen.)",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.value.length,
              itemBuilder: (ctx, i) {
                final msg = messages.value[i];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo[100] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: const Offset(0, 1))],
                    ),
                    child: Text(msg['text']!),
                  ),
                );
              },
            ),
          ),

          if (detectedSpecialist.value != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              color: Colors.white,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/student/bookAppointment', extra: {'category': detectedSpecialist.value});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.calendar_month),
                label: Text("Book Appointment with ${detectedSpecialist.value}"),
              ),
            ),

          if (isLoading.value) const LinearProgressIndicator(),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Describe your symptoms...",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: sendMessage,
                  backgroundColor: Colors.indigo,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}