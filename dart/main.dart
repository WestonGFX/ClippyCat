import 'dart:io';
import 'package:clipcat/providers/settings_provider.dart';
import 'package:clipcat/providers/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb, kDebugMode
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart'; // Import hotkey manager

import 'models/clipboard_item.dart';
import 'providers/clipboard_provider.dart';
import 'screens/home_screen.dart';
import 'utils/themes.dart'; // Import themes

// --- Configuration ---
const String appTitle = 'ClipCat';
// Define your main activation hotkey (Example: Command+Shift+V on macOS, Ctrl+Shift+V on Win/Linux)
final HotKey activateWindowHotKey = HotKey(
    kIsWeb // Hotkeys not really applicable in web builds
        ? KeyCode.keyV
        : Platform.isMacOS
            ? KeyCode.keyV
            : KeyCode.keyV,
    modifiers: kIsWeb
        ? [KeyModifier.alt, KeyModifier.shift]
        : Platform.isMacOS
            ? [KeyModifier.meta, KeyModifier.shift] // Meta = Command
            : [KeyModifier.control, KeyModifier.shift],
    scope: HotKeyScope.system // Global hotkey
    );

// Optional: Direct Paste Hotkeys (Example: Cmd/Ctrl+Alt+Number)
List<HotKey> directPasteHotKeys = List.generate(9, (index) {
     KeyCode numKey;
     switch (index + 1) {
         case 1: numKey = KeyCode.digit1; break;
         case 2: numKey = KeyCode.digit2; break;
         case 3: numKey = KeyCode.digit3; break;
         case 4: numKey = KeyCode.digit4; break;
         case 5: numKey = KeyCode.digit5; break;
         case 6: numKey = KeyCode.digit6; break;
         case 7: numKey = KeyCode.digit7; break;
         case 8: numKey = KeyCode.digit8; break;
         case 9: numKey = KeyCode.digit9; break;
         default: numKey = KeyCode.digit0; // Should not happen
     }
     return HotKey(
         numKey,
         modifiers: Platform.isMacOS
            ? [KeyModifier.meta, KeyModifier.alt]
            : [KeyModifier.control, KeyModifier.alt],
        scope: HotKeyScope.system,
        identifier: 'paste_item_${index + 1}' // Unique ID
     );
});


Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // --- Window Manager Setup ---
  // Must be called early for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();

       // Define default window options (adjust size as needed)
       WindowOptions windowOptions = const WindowOptions(
         size: Size(800, 450), // Long, not too tall
         center: true,
         backgroundColor: Color(0x00FFFFFF), // Transparent background initially
         skipTaskbar: false, // Show in taskbar/dock initially
         titleBarStyle: TitleBarStyle.hidden, // Hide default title bar for custom look
         windowButtonVisibility: false, // Hide standard buttons on macOS initially
       );

       // Setup how the window behaves when interacting with it
       windowManager.waitUntilReadyToShow(windowOptions, () async {
         // await windowManager.setAsFrameless(); // If using fully custom title bar/buttons
         await windowManager.setAlignment(Alignment.topCenter, animate: false); // Position like Spotlight
         await windowManager.hide(); // Start hidden, show with hotkey
          if (Platform.isMacOS) {
             await windowManager.setWindowButtonVisibility(show: false);
          }
       });
  }

  // --- Isar Database Setup ---
  final dir = await getApplicationSupportDirectory(); // Good place for app data
  final isar = await Isar.open(
    [ClipboardItemSchema], // Add schemas here
    directory: dir.path,
    name: 'ClipCatDB', // Database instance name
    // TODO: Add encryption key here based on settings provider *after* it's loaded
    // encryptionKey: settingsProvider.encryptDatabase ? getEncryptionKey() : null,
  );

  // --- Initialize Providers ---
  // Important: SettingsProvider needs to be created early if its values
  // affect initialization of other things (like Isar encryption or hotkeys)
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings(); // Load settings before dependents use them

   final clipboardProvider = ClipboardProvider(isar: isar, settingsProvider: settingsProvider);
   final themeProvider = ThemeProvider(); // Theme provider depends on loaded settings potentially

  // --- Hotkey Setup ---
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await hotKeyManager.unregisterAll(); // Clear previous session's hotkeys if any
      // Register main activation hotkey
      await hotKeyManager.register(
           activateWindowHotKey,
           keyDownHandler: (hotKey) async {
              bool isVisible = await windowManager.isVisible();
               if (isVisible) {
                 await windowManager.hide();
               } else {
                 await windowManager.show();
                 await windowManager.focus();
               }
           },
      );

      // TODO: Register direct paste hotkeys based on settings
      // if (settingsProvider.directPasteHotkeysEnabled) {
      //    for (int i = 0; i < directPasteHotKeys.length; i++) {
      //        await hotKeyManager.register(
      //             directPasteHotKeys[i],
      //             keyDownHandler: (hotkey) async {
      //                 final history = clipboardProvider.history; // Get current history
      //                 if (history.length > i) {
      //                    await clipboardProvider.copyToClipboard(history[i]);
      //                    // Optional: try to hide window after paste action
      //                    // await Future.delayed(Duration(milliseconds: 100));
      //                    // await windowManager.hide();
      //                    print("Direct Paste Hotkey: Copied item ${i + 1}");
      //                    // Note: Simulating actual paste is hard. User usually does Cmd/Ctrl+V.
      //                 }
      //             }
      //        );
      //    }
      // }
  }

   // --- System Tray Setup ---
   AppWindow? mainAppWindow; // Hold reference if needed for tray actions
   if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
       final systemTray = SystemTray();
       // TODO: Use a proper icon path
       String iconPath = Platform.isWindows ? 'assets/icons/tray_icon.ico' : 'assets/icons/tray_icon.png';

       try {
           await systemTray.initSystemTray(
                // title: "ClipCat", // Optional title shown next to icon (macOS)
                iconPath: iconPath,
                toolTip: appTitle, // Hover tooltip
           );

           // Create Menu
           final menu = Menu();
           await menu.buildFrom([
               MenuItemLabel(label: 'Show', onClicked: (menuItem) async => await windowManager.show()),
               MenuItemLabel(label: 'Settings', onClicked: (menuItem) async {
                   // Need BuildContext to navigate. How to get it here?
                   // Option 1: Use a global navigator key (less clean)
                   // Option 2: Bring window to front and maybe send a message/event to open settings
                   await windowManager.show(); // Bring window to front first
                   // This won't directly open settings, need app-level communication if window hidden
                   print("Tray Settings Click: Showing window. Navigate in-app.");
               }),
               MenuSeparator(),
               MenuItemLabel(label: 'Quit', onClicked: (menuItem) async => await windowManager.destroy()), // Full quit
           ]);

           await systemTray.setContextMenu(menu);

           // Handle tray icon clicks
            systemTray.registerSystemTrayEventHandler((eventName) {
              if (eventName == kSystemTrayEventClick) {
                 // Toggle window visibility on single click
                 windowManager.isVisible().then((visible) {
                     if (visible) {
                        windowManager.hide();
                     } else {
                        windowManager.show();
                        windowManager.focus();
                     }
                 });
              } else if (eventName == kSystemTrayEventRightClick) {
                  // Optional: Show context menu on right click explicitly if needed
                 // systemTray.popUpContextMenu();
              }
            });

       } catch (e) {
           print("System Tray initialization failed: $e");
       }

        // --- Window Closing Hook ---
       mainAppWindow = AppWindow();
       mainAppWindow.setPreventClose(true); // Intercept close event
       mainAppWindow.onClose = () async {
           // Read the setting *now* to decide action
           bool shouldHide = settingsProvider.closeToTray;
           if (shouldHide) {
              await windowManager.hide();
              print("Window hidden to tray.");
           } else {
              // Quit the app fully
              await hotKeyManager.unregisterAll(); // Clean up hotkeys
              await windowManager.destroy(); // Close window and exit app
              // No need for exit(0) usually with destroy
           }
       };
   }


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: clipboardProvider),
      ],
      child: const ClipCatApp(),
    ),
  );
}

class ClipCatApp extends StatelessWidget {
  const ClipCatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to theme provider changes
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

     // Determine theme based on provider's state
     CupertinoThemeData currentTheme;
     if (themeProvider.themeName == 'System') {
        // Use system brightness
        final Brightness platformBrightness = MediaQuery.platformBrightnessOf(context);
        currentTheme = platformBrightness == Brightness.dark ? darkTheme : lightTheme;
     } else {
        currentTheme = themeProvider.themeData;
     }

      // Apply font settings to the theme dynamically
      final baseTextStyle = currentTheme.textTheme.textStyle;
      final scaledTextStyle = baseTextStyle?.copyWith(
           fontSize: (baseTextStyle.fontSize ?? 14.0) * settings.fontSizeModifier,
           fontFamily: settings.fontFamily == 'SystemDefault' ? null : settings.fontFamily, // Use null for system default
      );
       // Apply to other text styles as needed (nav bar, etc.) - requires more detailed theme customization
       final customizedTheme = currentTheme.copyWith(
            textTheme: currentTheme.textTheme.copyWith(
                 textStyle: scaledTextStyle,
                 // Example: Apply scaling to nav titles too
                 navLargeTitleTextStyle: currentTheme.textTheme.navLargeTitleTextStyle.copyWith(
                       fontSize: (currentTheme.textTheme.navLargeTitleTextStyle.fontSize ?? 34.0) * settings.fontSizeModifier,
                       fontFamily: settings.fontFamily == 'SystemDefault' ? null : settings.fontFamily,
                 ),
                  navTitleTextStyle: currentTheme.textTheme.navTitleTextStyle.copyWith(
                       fontSize: (currentTheme.textTheme.navTitleTextStyle.fontSize ?? 17.0) * settings.fontSizeModifier,
                        fontFamily: settings.fontFamily == 'SystemDefault' ? null : settings.fontFamily,
                 ),
                  // ... customize other text styles similarly
            ),
       );


    return CupertinoApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
       theme: customizedTheme, // Apply the selected/customized theme
      home: const HomeScreen(),
    );
  }
}