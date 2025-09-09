class ConversationHistory {
  final String id;
  final String title;
  final DateTime lastUpdated;
  final List<String> messagePreview;

  ConversationHistory({
    required this.id,
    required this.title,
    required this.lastUpdated,
    required this.messagePreview,
  });
}