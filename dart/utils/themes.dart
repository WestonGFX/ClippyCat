import 'package:flutter/cupertino.dart';

// Define base light/dark themes inspired by macOS
const CupertinoThemeData lightTheme = CupertinoThemeData(
  brightness: Brightness.light,
  primaryColor: CupertinoColors.systemBlue,
  scaffoldBackgroundColor: CupertinoColors.systemGrey6,
  barBackgroundColor: Color(0xF0F9F9F9), // Slightly translucent light bar
  textTheme: CupertinoTextThemeData(
    primaryColor: CupertinoColors.label, // Default text color
  ),
);

const CupertinoThemeData darkTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: CupertinoColors.systemBlue, // Or maybe systemOrange for contrast?
  scaffoldBackgroundColor: Color(0xFF1C1C1E), // Dark grey background
  barBackgroundColor: Color(0xF01C1C1E), // Slightly translucent dark bar
  textTheme: CupertinoTextThemeData(
    primaryColor: CupertinoColors.systemGrey6, // Light text on dark
  ),
);

// --- Custom Themes ---

const CupertinoThemeData draculaTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFFBD93F9), // Purple
    scaffoldBackgroundColor: Color(0xFF282A36), // Background
    barBackgroundColor: Color(0xE0282A36), // Translucent Background
    textTheme: CupertinoTextThemeData(
        primaryColor: Color(0xFFF8F8F2), // Foreground
        navTitleTextStyle: TextStyle(color: Color(0xFFF8F8F2)),
        navLargeTitleTextStyle: TextStyle(color: Color(0xFFF8F8F2)),
         textStyle: TextStyle(color: Color(0xFFF8F8F2)) // Ensure default text is colored
        ),
    primaryContrastingColor: Color(0xFF44475A) // Comments/Contrast
);

const CupertinoThemeData monokaiTheme = CupertinoThemeData(
     brightness: Brightness.dark,
    primaryColor: Color(0xFFA6E22E), // Green
    scaffoldBackgroundColor: Color(0xFF272822), // Background
    barBackgroundColor: Color(0xE0272822),
    textTheme: CupertinoTextThemeData(
        primaryColor: Color(0xFFF8F8F2), // White text
        // ... other text styles if needed
         textStyle: TextStyle(color: Color(0xFFF8F8F2))
    ),
    primaryContrastingColor: Color(0xFF75715E) // Comments
);

// Add Solarized, Nord, Blurple etc. similarly

// --- System Theme ---
// This will adapt based on the system's light/dark mode dynamically
// We handle this logic where the theme is applied in main.dart
const CupertinoThemeData systemTheme = lightTheme; // Placeholder, logic applied elsewhere

// Helper to get theme by name
CupertinoThemeData getThemeByName(String name) {
  switch (name) {
    case 'Light':
      return lightTheme;
    case 'Dark':
      return darkTheme;
    case 'Dracula':
        return draculaTheme;
    case 'Monokai':
        return monokaiTheme;
    // Add other cases
    case 'System':
    default:
      // Determine system brightness here if needed, or rely on MaterialApp/CupertinoApp
      // For simplicity in provider, return a default like light/dark
      // The actual 'System' behavior is best handled by the App's theme/darkTheme props.
      // Return light as a fallback for the provider's initial state.
      return lightTheme;
  }
}

List<String> get themeNames => ['System', 'Light', 'Dark', 'Dracula', 'Monokai']; // Add others