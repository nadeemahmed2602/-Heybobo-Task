import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/chat_controller.dart';

class MessageInput extends StatelessWidget {
  final ChatController controller;

  const MessageInput({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Uses theme surface color
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment Button
            IconButton(
              onPressed: controller.attachFiles,
              icon: Icon(Icons.attach_file),
              color: colorScheme.onSurfaceVariant, // Theme-aware color
              iconSize: 24,
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: 'Attach files',
            ),

            SizedBox(width: 8),

            // Message Input Field
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(24),
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                child: TextField(
                  controller: controller.messageController,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => controller.sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface, // Theme-aware text color
                  ),
                ),
              ),
            ),

            SizedBox(width: 8),

            // Send Button
            Container(
              decoration: BoxDecoration(
                color: controller.canSendMessage
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: controller.canSendMessage ? controller.sendMessage : null,
                icon: Icon(Icons.send),
                color: controller.canSendMessage
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withOpacity(0.38),
                iconSize: 20,
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                tooltip: 'Send message',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: colorScheme.surface,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                SizedBox(height: 20),

                // Title
                Text(
                  'Choose Attachment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: 24),

                // Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Images option
                    _AttachmentOption(
                      icon: Icons.image,
                      label: 'Images',
                      color: colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImages();
                      },
                    ),

                    // Files option
                    _AttachmentOption(
                      icon: Icons.folder,
                      label: 'Files',
                      color: colorScheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickFiles();
                      },
                    ),
                  ],
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        // Handle the selected images
        // You can call your controller method here
        // controller.handleImages(images);
        print('Selected ${images.length} images');
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        // Handle the selected files
        // You can call your controller method here
        // controller.handleFiles(result.files);
        print('Selected ${result.files.length} files');
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}