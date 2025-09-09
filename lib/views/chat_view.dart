import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/chat_service.dart';
import '../widgets/message_list.dart';
import '../widgets/message_input.dart';
import '../widgets/attachment_preview.dart';

class ChatView extends StatefulWidget {
  final ThemeController themeController;

  const ChatView({Key? key, required this.themeController}) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController(ChatService());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final currentConv = _controller.conversationHistory
                .where((conv) => conv.id == _controller.currentConversationId)
                .firstOrNull;
            return Text(currentConv?.title ?? 'ChatGPT Clone');
          },
        ),
        centerTitle: true,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
                widget.themeController.isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode
            ),
            onPressed: widget.themeController.toggleTheme,
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            children: [
              // Error Banner
              if (_controller.error != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.red.shade50
                      : Colors.red.shade900.withOpacity(0.3),
                  child: Row(
                    children: [
                      Icon(
                          Icons.error_outline,
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.red.shade700
                              : Colors.red.shade300,
                          size: 20
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _controller.error!,
                          style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.red.shade700
                                  : Colors.red.shade300,
                              fontSize: 14
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _controller.clearError,
                        child: Text('Dismiss'),
                      ),
                    ],
                  ),
                ),

              // Message List
              Expanded(
                child: MessageList(
                  controller: _controller,
                ),
              ),

              // Attachment Preview
              AttachmentPreview(
                attachments: _controller.pendingAttachments,
                onRemoveAttachment: _controller.removeAttachment,
              ),

              // Message Input
              MessageInput(
                controller: _controller,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header
          Container(
            height: 104,
            width: double.infinity,
            padding: EdgeInsets.only(top: 40, left: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _controller.createNewConversation();
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.edit_square, size: 18),
                  label: Text('New Chat'),
                )

              ],
            ),
          ),


          // Conversation History List
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (_controller.conversationHistory.isEmpty) {
                  return Center(
                    child: Text(
                      'No conversations yet',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _controller.conversationHistory.length,
                  itemBuilder: (context, index) {
                    final conversation = _controller.conversationHistory[index];
                    final isSelected = conversation.id == _controller.currentConversationId;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.15)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _controller.selectConversation(conversation.id);
                          Navigator.of(context).pop();
                        },
                        onLongPressStart: (details) {
                          _showDropdownMenu(
                              context,
                              details.globalPosition,
                              conversation.id,
                              conversation.title
                          );
                        },
                        child: ListTile(
                          dense: true,
                          title: Text(
                            conversation.title,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (conversation.messagePreview.isNotEmpty)
                                Text(
                                  conversation.messagePreview.first,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                _formatDate(conversation.lastUpdated),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                ),
                SizedBox(width: 8),
                Text(
                  'User Account',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDropdownMenu(BuildContext context, Offset position, String conversationId, String conversationTitle) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    ).then((String? value) {
      if (value != null) {
        _handleConversationAction(context, conversationId, value, conversationTitle);
      }
    });
  }

  void _handleConversationAction(BuildContext context, String conversationId, String action, String currentTitle) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context, conversationId, currentTitle);
        break;
      case 'delete':
        _showDeleteConfirmation(context, conversationId);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, String conversationId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter new title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                _controller.renameConversation(conversationId, newTitle);
              }
              Navigator.of(context).pop();
            },
            child: Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Conversation'),
        content: Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.deleteConversation(conversationId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.clear_all),
              title: Text('Clear All Conversations'),
              onTap: () {
                Navigator.of(context).pop();
                _showClearAllConfirmation(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to settings
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Conversations'),
        content: Text('Are you sure you want to delete all conversations? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear all and create new conversation
              _controller.createNewConversation();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}