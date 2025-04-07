import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:super_clipboard/super_clipboard.dart'; // Use super_clipboard
import '../models/clipboard_item.dart';
import 'settings_provider.dart'; // To access max items limit

class ClipboardProvider with ChangeNotifier {
  final Isar isar;
  final SettingsProvider settingsProvider;
  List<ClipboardItem> _history = [];
  StreamSubscription? _clipboardSubscription;
  bool _isInitialized = false;
  String _searchQuery = '';
  // Add filter states here (date range, type etc.) if implementing advanced filters

  List<ClipboardItem> get history {
     // Apply search filter
     final filtered = _searchQuery.isEmpty
        ? _history
        : _history.where((item) {
            final query = _searchQuery.toLowerCase();
            if (item.isText && item.textData != null) {
              return item.textData!.toLowerCase().contains(query) ||
                     (item.title?.toLowerCase().contains(query) ?? false);
            } else if (item.isImage) {
                // Search title or maybe eventually OCR results/metadata?
                 return item.preview!.toLowerCase().contains(query) ||
                        (item.title?.toLowerCase().contains(query) ?? false);
            }
            return false;
          }).toList();

    // Apply other filters here (date, type) before returning
    return filtered;
  }


  bool get isInitialized => _isInitialized;
  String get searchQuery => _searchQuery;

  ClipboardProvider({required this.isar, required this.settingsProvider}) {
    _init();
    // Listen to changes in settings provider to react to maxHistoryItems changes
    settingsProvider.addListener(_checkHistoryLimit);
  }

  Future<void> _init() async {
    await _loadHistoryFromDb();
    _startMonitoring();
    _isInitialized = true;
    notifyListeners();
    // Run initial cleanup check
    await performAutoCleanup();
    _checkHistoryLimit(); // Ensure initial load respects limit
  }

  Future<void> _loadHistoryFromDb() async {
    final items = await isar.clipboardItems
        .where()
        .sortByTimestampDesc() // Load newest first
        .limit(settingsProvider.maxHistoryItems) // Limit initial load
        .findAll();
    _history = items;
    // print("Loaded ${_history.length} items from DB");
  }

  void _startMonitoring() {
    // super_clipboard approach
    _clipboardSubscription = ClipboardMonitor.instance?.clipboardChanges.listen(_onClipboardChange);
    if (kDebugMode) {
        if (ClipboardMonitor.instance == null) {
            print("ClipboardMonitor not available on this platform or not initialized.");
        } else {
             print("Clipboard monitoring started.");
        }
    }
  }

  Future<void> _onClipboardChange(dynamic _) async { // Use dynamic type as event data might vary
    final reader = await ClipboardReader.readClipboard();
    if (reader.canProvide(Formats.plainText) || reader.canProvide(Formats.png) || reader.canProvide(Formats.jpeg) ) {
       // Optional: Debounce or check against last added item to avoid duplicates if copied rapidly
       // if (_history.isNotEmpty) {
       //    final lastItem = _history.first;
       //    // Add comparison logic here if needed
       // }

       ClipboardItem? newItem;

       // Prioritize images if both are present somehow? Or handle specific types.
       if (reader.canProvide(Formats.png)) {
          final data = await reader.readValue(Formats.png);
          if (data != null) {
             newItem = ClipboardItem.image(data);
          }
       } else if (reader.canProvide(Formats.jpeg)) {
           final data = await reader.readValue(Formats.jpeg);
           if (data != null) {
             newItem = ClipboardItem.image(data);
           }
       } else if (reader.canProvide(Formats.plainText)) {
          final text = await reader.readValue(Formats.plainText);
          if (text != null && text.trim().isNotEmpty) {
             newItem = ClipboardItem.text(text);
          }
       }

       if (newItem != null) {
           // Check for exact duplicate of the most recent item
          if (_history.isNotEmpty && _isDuplicate(_history.first, newItem)) {
             print("Skipping duplicate clipboard item.");
             return;
          }
          await _addClipboardItem(newItem);
       }
    }
  }

  bool _isDuplicate(ClipboardItem existing, ClipboardItem potentialNew) {
      if (existing.type != potentialNew.type) return false;
      if (existing.isText) {
          return existing.textData == potentialNew.textData;
      } else if (existing.isImage) {
          // Simple byte comparison (might be slow for large images)
          return listEquals(existing.imageData, potentialNew.imageData);
      }
      return false;
  }


  Future<void> _addClipboardItem(ClipboardItem item) async {
    // --- Optional: Image Compression ---
    if (item.isImage && settingsProvider.compressImages && item.imageData != null) {
      // Placeholder: Add image compression logic using 'package:image'
      // final img.Image? decodedImage = img.decodeImage(Uint8List.fromList(item.imageData!));
      // if (decodedImage != null) {
      //   final compressedData = img.encodeJpg(decodedImage, quality: settingsProvider.imageCompressionQuality);
      //   item.imageData = compressedData;
      // }
       print("Image compression placeholder - skipping actual compression");
    }

     // Add to the beginning of the list
    _history.insert(0, item);

    // Persist to DB
    await isar.writeTxn(() async {
      await isar.clipboardItems.put(item);
    });

     // Enforce history limit immediately after adding
    _checkHistoryLimit(); // This now handles DB removal too

    // --- Database Size Check ---
    // TODO: Implement DB size check (might need platform channel or Isar feature)
    // if (settingsProvider.warnDbSize) { checkDatabaseSize(); }

    // --- Item Count Warning ---
    _checkItemCountWarning();


    notifyListeners();
  }

   Future<void> _checkHistoryLimit() async {
    final maxItems = settingsProvider.maxHistoryItems;
    if (_history.length > maxItems) {
      final itemsToRemove = _history.sublist(maxItems);
      _history = _history.sublist(0, maxItems); // Trim memory list

      // Remove excess items from DB
      final idsToRemove = itemsToRemove.map((item) => item.isarId).toList();
      if (idsToRemove.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.clipboardItems.deleteAll(idsToRemove);
        });
        print("Removed ${idsToRemove.length} oldest items from DB due to limit.");
      }
       notifyListeners(); // Update UI if trimming happened
    }
  }


  void _checkItemCountWarning() {
     if (settingsProvider.warnItemCount) {
       final maxItems = settingsProvider.maxHistoryItems;
       final threshold = (maxItems * 0.85).floor();
       if (_history.length >= threshold) {
         print("Warning: Clipboard history approaching limit (${_history.length}/$maxItems items).");
         // TODO: Show a user-facing warning (e.g., SnackBar)
       }
     }
  }

   // TODO: Implement checkDatabaseSize()

  Future<void> deleteItem(ClipboardItem item) async {
    _history.removeWhere((i) => i.id == item.id);
    await isar.writeTxn(() async {
      await isar.clipboardItems.delete(item.isarId);
    });
    notifyListeners();
  }

  Future<void> updateItem(ClipboardItem updatedItem) async {
      final index = _history.indexWhere((i) => i.id == updatedItem.id);
      if (index != -1) {
          _history[index] = updatedItem;
          // Persist changes to DB
          await isar.writeTxn(() async {
            await isar.clipboardItems.put(updatedItem);
          });
          notifyListeners();
      }
  }


  Future<void> clearHistory() async {
    _history.clear();
    await isar.writeTxn(() async {
      await isar.clipboardItems.clear();
    });
    notifyListeners();
  }

   Future<void> performAutoCleanup() async {
     if (!settingsProvider.autoCleanupEnabled) return;

     final cutoffDate = DateTime.now().subtract(Duration(days: settingsProvider.autoCleanupDays));
     await isar.writeTxn(() async {
        final count = await isar.clipboardItems
                          .filter()
                          .timestampLessThan(cutoffDate)
                          .deleteAll();
        if (count > 0) {
            print("Auto-Cleanup: Deleted $count items older than ${settingsProvider.autoCleanupDays} days.");
        }
     });
     // Reload history after cleanup to reflect changes
     await _loadHistoryFromDb();
     notifyListeners();
   }

   void setSearchQuery(String query) {
       _searchQuery = query;
       notifyListeners(); // Trigger UI update with filtered list
   }

   // Method to copy item back to system clipboard
   Future<void> copyToClipboard(ClipboardItem item) async {
       final writer = ClipboardWriter.instance;
       if (item.isText && item.textData != null) {
           await writer.write(DataReader().addText(item.textData!));
           print("Copied text item to clipboard.");
           // Optional: Show feedback to user
       } else if (item.isImage && item.imageData != null) {
           final bytes = Uint8List.fromList(item.imageData!);
           // Determine format (super_clipboard might need specific format like PNG)
           // For simplicity, let's assume PNG. Real app might store original format.
           await writer.write(DataReader().addFormat(Formats.png, bytes));
            print("Copied image item to clipboard.");
           // Optional: Show feedback to user
       }
   }


  @override
  void dispose() {
    _clipboardSubscription?.cancel();
    settingsProvider.removeListener(_checkHistoryLimit);
    super.dispose();
  }
}