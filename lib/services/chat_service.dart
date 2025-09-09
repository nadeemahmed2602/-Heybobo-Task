import 'dart:async';
import '../models/chat_message.dart';

class ChatService {
  // Simulate streaming response from AI
  Future<void> sendMessage(
      ChatMessage userMessage,
      Function(ChatMessage) onMessageUpdate
      ) async {
    const mockResponses = [
      "This is a simulated AI response demonstrating the **streaming capability** of our chat interface. The UI smoothly handles real-time updates as the message is being generated.",
      "I can help you with various tasks including answering questions, writing code, creating content, and much more. The interface supports *markdown formatting* and `code highlighting`.",
      "Here's an example of how the chat handles longer responses with multiple paragraphs.\n\nThis second paragraph demonstrates line breaks and formatting. The interface automatically scrolls to keep the latest content visible.",
    ];

    final responseText = mockResponses[userMessage.content.length % mockResponses.length];
    final responseId = '${userMessage.id}_response';
    final words = responseText.split(' ');

    String currentContent = '';

    for (int i = 0; i < words.length; i++) {
      await Future.delayed(Duration(milliseconds: 80));

      currentContent += (i > 0 ? ' ' : '') + words[i];

      final streamingMessage = ChatMessage(
        id: responseId,
        content: currentContent,
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
        isStreaming: i < words.length - 1,
      );

      onMessageUpdate(streamingMessage);
    }
  }
}