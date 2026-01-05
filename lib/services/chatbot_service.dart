import 'package:flutter_gemini/flutter_gemini.dart';

class ChatBotService {
  final Gemini _gemini = Gemini.instance;

  final String _systemInstruction = """
You are Dr. AI, a helpful medical triage assistant for a college campus health app.
Your goal is to listen to the student's symptoms and recommend ONE of the following specialists:
- General Physician
- Cardiologist
- Dermatologist
- Neurologist
- Orthopedic
- Dentist
- Psychiatrist
- ENT Specialist

Rules:
1. If the symptoms are mild (fever, cold, headache, stomach ache), recommend "General Physician".
2. If the symptoms match a specific field (e.g., skin rash -> Dermatologist), recommend that specialist.
3. Be concise. Explain WHY in 1 sentence, then state the recommendation clearly.
4. If it sounds like a life-threatening emergency (chest pain, unconsciousness, severe bleeding), reply with "EMERGENCY: Please use the SOS button immediately!"
5. Do NOT prescribe medication. Only recommend a doctor.
""";

  Stream<Candidates?> streamResponse(String userMessage) {
    final fullPrompt = "$_systemInstruction\n\nStudent: $userMessage\nDr. AI:";
    return _gemini.promptStream(parts: [Part.text(fullPrompt)]);
  }
  
  Future<String?> getSingleResponse(String userMessage) async {
    final fullPrompt = "$_systemInstruction\n\nStudent: $userMessage\nDr. AI:";
    try {
      final value = await _gemini.prompt(parts: [Part.text(fullPrompt)]);
      return value?.output;
    } catch (e) {
      return "Sorry, I am having trouble connecting. Please check your internet.";
    }
  }
}