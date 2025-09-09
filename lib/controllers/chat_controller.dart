import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

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

class ChatController extends ChangeNotifier {
  final ChatService _chatService;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  List<AttachmentFile> _pendingAttachments = [];
  List<ConversationHistory> _conversationHistory = [];
  String? _currentConversationId;
  bool _isLoading = false;
  String? _error;

  ChatController(this._chatService) {
    _loadInitialMessages();
  }

  // Getters
  List<ChatMessage> get messages => _messages;
  List<AttachmentFile> get pendingAttachments => _pendingAttachments;
  List<ConversationHistory> get conversationHistory => _conversationHistory;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canSendMessage => messageController.text.trim().isNotEmpty || _pendingAttachments.isNotEmpty;

  // Initialize with sample messages and conversation history
  void _loadInitialMessages() {
    _conversationHistory = [
      ConversationHistory(
        id: 'conv1',
        title: 'HeyBobo',
        lastUpdated: DateTime.now().subtract(Duration(minutes: 5)),
        messagePreview: ['Hello! How can I help you today?'],
      ),
      ConversationHistory(
        id: 'conv2',
        title: 'Coding Help',
        lastUpdated: DateTime.now().subtract(Duration(hours: 2)),
        messagePreview: ['Can you help me with Flutter?', 'Sure! I can help with that.'],
      ),
      ConversationHistory(
        id: 'conv3',
        title: 'Previous Discussion',
        lastUpdated: DateTime.now().subtract(Duration(days: 1)),
        messagePreview: ['What\'s the weather like?', 'I can help you find weather information.'],
      ),
      ConversationHistory(
        id: 'conv4',
        title: 'Design Questions',
        lastUpdated: DateTime.now().subtract(Duration(days: 2)),
        messagePreview: ['UI/UX best practices?', 'Here are some design principles...'],
      ),
    ];

    _currentConversationId = 'conv1';
    _messages = [
      ChatMessage(
        id: '1',
        content: 'Hello! How can I help you today?',
        sender: MessageSender.assistant,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      ),
    ];
    notifyListeners();
  }

  void selectConversation(String conversationId) {
    if (_currentConversationId == conversationId) return;

    _currentConversationId = conversationId;

    // Load messages for selected conversation
    // In a real app, you would load from database/storage
    switch (conversationId) {
      case 'conv1':
        _messages = [
          ChatMessage(
            id: '1',
            content: 'Hello! How can I help you today?',
            sender: MessageSender.assistant,
            timestamp: DateTime.now().subtract(Duration(minutes: 5)),
          ),
        ];
        break;
      case 'conv2':
        _messages = [
          ChatMessage(
            id: '2-1',
            content: 'Can you help me with Flutter?',
            sender: MessageSender.user,
            timestamp: DateTime.now().subtract(Duration(hours: 2)),
          ),
          ChatMessage(
            id: '2-2',
            content: 'Sure! I can help with Flutter development. What specific aspect would you like to know about?',
            sender: MessageSender.assistant,
            timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: -1)),
          ),
        ];
        break;
      case 'conv3':
        _messages = [
          ChatMessage(
            id: '3-1',
            content: 'What\'s the weather like?',
            sender: MessageSender.user,
            timestamp: DateTime.now().subtract(Duration(days: 1)),
          ),
          ChatMessage(
            id: '3-2',
            content: 'I can help you find weather information. Could you please specify your location?',
            sender: MessageSender.assistant,
            timestamp: DateTime.now().subtract(Duration(days: 1, minutes: -2)),
          ),
        ];
        break;
      case 'conv4':
        _messages = [
          ChatMessage(
            id: '4-1',
            content: 'What are some UI/UX best practices?',
            sender: MessageSender.user,
            timestamp: DateTime.now().subtract(Duration(days: 2)),
          ),
          ChatMessage(
            id: '4-2',
            content: 'Here are some key UI/UX design principles:\n\n• **Consistency** - Keep design elements uniform\n• **Simplicity** - Don\'t overcomplicate the interface\n• **Accessibility** - Design for all users\n• **Feedback** - Provide clear user feedback',
            sender: MessageSender.assistant,
            timestamp: DateTime.now().subtract(Duration(days: 2, minutes: -3)),
          ),
        ];
        break;
      default:
        _messages = [];
    }

    // Clear any pending attachments and errors
    _pendingAttachments.clear();
    _error = null;
    messageController.clear();

    notifyListeners();
    _scrollToBottom();
  }

  void createNewConversation() {
    final newId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    final newConv = ConversationHistory(
      id: newId,
      title: 'New Chat',
      lastUpdated: DateTime.now(),
      messagePreview: [],
    );

    _conversationHistory.insert(0, newConv);
    _currentConversationId = newId;
    _messages.clear();
    _pendingAttachments.clear();
    _error = null;
    messageController.clear();

    notifyListeners();
  }

  void deleteConversation(String conversationId) {
    if (_conversationHistory.length <= 1) return; // Keep at least one conversation

    _conversationHistory.removeWhere((conv) => conv.id == conversationId);

    if (_currentConversationId == conversationId) {
      // Switch to the first available conversation
      if (_conversationHistory.isNotEmpty) {
        selectConversation(_conversationHistory.first.id);
      } else {
        createNewConversation();
      }
    }

    notifyListeners();
  }

  void renameConversation(String conversationId, String newTitle) {
    final index = _conversationHistory.indexWhere((conv) => conv.id == conversationId);
    if (index != -1) {
      final oldConv = _conversationHistory[index];
      _conversationHistory[index] = ConversationHistory(
        id: oldConv.id,
        title: newTitle,
        lastUpdated: oldConv.lastUpdated,
        messagePreview: oldConv.messagePreview,
      );
      notifyListeners();
    }
  }

  Future<void> sendMessage() async {
    if (!canSendMessage) return;

    final content = messageController.text.trim();
    final attachments = List<AttachmentFile>.from(_pendingAttachments);

    // Create user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      attachments: attachments,
    );

    // Clear input
    messageController.clear();
    _pendingAttachments.clear();

    // Add user message
    _messages.add(userMessage);
    _isLoading = true;
    _error = null;

    // Update conversation history
    _updateConversationHistory(content);

    notifyListeners();
    _scrollToBottom();

    try {
      // Simulate AI response
      await _chatService.sendMessage(userMessage, (response) {
        final existingIndex = _messages.indexWhere((m) => m.id == response.id);
        if (existingIndex != -1) {
          _messages[existingIndex] = response;
        } else {
          _messages.add(response);
        }
        notifyListeners();
        _scrollToBottom();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateConversationHistory(String userMessage) {
    if (_currentConversationId == null) return;

    final index = _conversationHistory.indexWhere((conv) => conv.id == _currentConversationId);
    if (index != -1) {
      final oldConv = _conversationHistory[index];
      final updatedConv = ConversationHistory(
        id: oldConv.id,
        title: oldConv.title == 'New Chat' ? _generateTitle(userMessage) : oldConv.title,
        lastUpdated: DateTime.now(),
        messagePreview: [userMessage, ...oldConv.messagePreview].take(2).toList(),
      );

      // Move to top of list
      _conversationHistory.removeAt(index);
      _conversationHistory.insert(0, updatedConv);
    }
  }

  String _generateTitle(String message) {
    // Simple title generation - take first few words
    final words = message.split(' ').take(4).join(' ');
    return words.length > 30 ? '${words.substring(0, 30)}...' : words;
  }

  Future<void> attachFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        final newAttachments = result.files.map((file) => AttachmentFile(
          id: DateTime.now().millisecondsSinceEpoch.toString() + file.name,
          name: file.name,
          path: file.path ?? '',
          size: file.size,
          type: file.extension ?? 'unknown',
        )).toList();

        _pendingAttachments.addAll(newAttachments);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error picking files: $e';
      notifyListeners();
    }
  }

  void removeAttachment(String attachmentId) {
    _pendingAttachments.removeWhere((attachment) => attachment.id == attachmentId);
    notifyListeners();
  }

  void copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
  }

  Future<void> regenerateResponse(String messageId) async {
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex <= 0) return;

    final userMessage = _messages[messageIndex - 1];

    // Remove the old response
    _messages.removeWhere((m) => m.id == messageId);
    _isLoading = true;
    notifyListeners();

    try {
      await _chatService.sendMessage(userMessage, (response) {
        _messages.add(response);
        notifyListeners();
        _scrollToBottom();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}