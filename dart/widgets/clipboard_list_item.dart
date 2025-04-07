import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/clipboard_item.dart';
import '../providers/clipboard_provider.dart';
import '../providers/settings_provider.dart'; // For padding/font scale

class ClipboardListItem extends StatelessWidget {
  final ClipboardItem item;
  final int index; // Index for potential hotkey mapping

  const ClipboardListItem({required this.item, required this.index, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clipboardProvider = Provider.of<ClipboardProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context);
    final theme = CupertinoTheme.of(context);

    // Apply scaling
    final double padding = 8.0 * settings.paddingScale;
    final double fontSize = (theme.textTheme.textStyle?.fontSize ?? 14.0) * settings.fontSizeModifier;

    Widget content;
    if (item.isImage && item.imageData != null) {
      content = Row(
        children: [
          SizedBox(
            width: 40 * settings.paddingScale, // Scaled preview size
            height: 40 * settings.paddingScale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0 * settings.paddingScale),
              child: Image.memory(
                Uint8List.fromList(item.imageData!),
                fit: BoxFit.cover,
                gaplessPlayback: true, // Avoid flicker on list updates
                errorBuilder: (context, error, stackTrace) => Icon(
                  CupertinoIcons.photo,
                  color: theme.textTheme.textStyle?.color?.withOpacity(0.5),
                ),
              ),
            ),
          ),
          SizedBox(width: padding),
          Expanded(
            child: Text(
              item.title ?? item.preview ?? '[Image]',
              style: theme.textTheme.textStyle?.copyWith(fontSize: fontSize),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      // Text item
      content = Text(
        item.title ?? item.preview ?? item.textData ?? '',
        style: theme.textTheme.textStyle?.copyWith(fontSize: fontSize),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    return GestureDetector(
       onTap: () {
         // Single tap: Copy to system clipboard
         clipboardProvider.copyToClipboard(item);
         // Optional: Show a quick confirmation (SnackBar/Toast)
          _showFeedback(context, "Copied!");
       },
       onDoubleTap: () {
            // Double tap: Copy & potentially try to hide window (or paste via hotkey simulation)
            clipboardProvider.copyToClipboard(item);
             _showFeedback(context, "Copied!");
            // Future.delayed(Duration(milliseconds: 150), () {
            //    windowManager.hide(); // Requires import and setup
            // });
       },
       child: Container(
          padding: EdgeInsets.all(padding),
          margin: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
          decoration: BoxDecoration(
             color: theme.brightness == Brightness.light
                    ? CupertinoColors.white.withOpacity(0.6)
                    : CupertinoColors.darkBackgroundGray.withOpacity(0.6),
             borderRadius: BorderRadius.circular(8.0 * settings.paddingScale), // Scaled corners
          ),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               content,
               SizedBox(height: padding / 2),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     DateFormat('MMM d, HH:mm').format(item.timestamp), // Format date
                     style: theme.textTheme.tabLabelTextStyle.copyWith(
                         fontSize: fontSize * 0.8, // Smaller font for metadata
                         color: theme.textTheme.tabLabelTextStyle.color?.withOpacity(0.7)
                     ),
                   ),
                   // --- Actions ---
                   Row(
                      mainAxisSize: MainAxisSize.min,
                     children: [
                        // Optional: Index display for direct paste hotkeys
                        if (index < 9) // Show for first 9 items
                            Text("#${index + 1} ", style: theme.textTheme.tabLabelTextStyle.copyWith(
                                 fontSize: fontSize * 0.8,
                                 color: theme.primaryColor.withOpacity(0.8))),

                        CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 20,
                            child: Icon(CupertinoIcons.pencil, size: fontSize * 1.1, color: theme.primaryColor),
                            onPressed: () {
                                // TODO: Implement Edit Dialog/Screen
                                print("Edit item: ${item.id}");
                                // Show dialog or navigate
                            },
                        ),
                        SizedBox(width: padding / 2),
                        CupertinoButton(
                             padding: EdgeInsets.zero,
                             minSize: 20,
                             child: Icon(CupertinoIcons.delete, size: fontSize * 1.1, color: CupertinoColors.systemRed),
                             onPressed: () {
                                 // Optional: Show confirmation dialog
                                 clipboardProvider.deleteItem(item);
                             },
                         ),
                     ],
                   ),
                 ],
               ),
             ],
           ),
       ),
    );
  }

    // Helper to show simple feedback
  void _showFeedback(BuildContext context, String message) {
     // Use Overlay for less intrusive feedback than SnackBar if desired
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0,
        left: MediaQuery.of(context).size.width * 0.3,
        right: MediaQuery.of(context).size.width * 0.3,
        child: Material( // Need Material for visual styling of toast
          color: CupertinoColors.darkBackgroundGray.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
     Overlay.of(context).insert(entry);
     Future.delayed(const Duration(seconds: 1, milliseconds: 500)).then((_) => entry.remove());
  }

}