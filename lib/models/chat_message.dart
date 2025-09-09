import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final List<AttachmentFile> attachments;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.attachments = const [],
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: this.id,
      content: content ?? this.content,
      sender: this.sender,
      timestamp: this.timestamp,
      attachments: this.attachments,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

enum MessageSender { user, assistant }

class AttachmentFile {
  final String id;
  final String name;
  final String path;
  final int size;
  final String type;

  AttachmentFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.type,
  });

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
