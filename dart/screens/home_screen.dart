import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart'; // Import window_manager
import '../providers/clipboard_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/clipboard_list_item.dart';
import 'settings_screen.dart'; // Import settings screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to search input changes
    _searchController.addListener(() {
      Provider.of<ClipboardProvider>(context, listen: false)
          .setSearchQuery(_searchController.text);
    });

    // Optional: Add listener to scroll controller if needed (e.g., load more)
  }

   @override
   void dispose() {
      _scrollController.dispose();
      _searchController.dispose();
      super.dispose();
   }


  @override
  Widget build(BuildContext context) {
    // Watch clipboard provider for updates to the history list
    final clipboardProvider = Provider.of<ClipboardProvider>(context);
    final settings = Provider.of<SettingsProvider>(context); // For padding etc.
     final theme = CupertinoTheme.of(context);


    return CupertinoPageScaffold(
      // Use a NavigationBar that looks like a toolbar
       navigationBar: CupertinoNavigationBar(
          // leading: Padding( // Optional App Icon/Title
          //    padding: const EdgeInsets.all(8.0),
          //    child: Icon(CupertinoIcons.doc_on_clipboard), // Placeholder Icon
          //  ),
          middle: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0 * settings.paddingScale),
              child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Search History...',
              ),
          ),
          trailing: CupertinoButton(
               padding: EdgeInsets.zero,
               child: Icon(CupertinoIcons.settings, size: 24 * settings.fontSizeModifier),
               onPressed: () {
                  // Navigate to Settings
                   Navigator.of(context).push(CupertinoPageRoute(
                       builder: (context) => const SettingsScreen(),
                   ));
               },
          ),
           // Apply background blur/color from theme
          backgroundColor: theme.barBackgroundColor.withOpacity(0.85),
          border: null, // Remove bottom border for cleaner look
       ),

      child: SafeArea( // Ensures content is not under status bar etc.
        bottom: false, // We want list to go to bottom edge potentially
        child: Container(
            // Optional: Add slight padding if list items don't have enough margin
            // padding: EdgeInsets.only(top: 8.0 * settings.paddingScale),
            child: clipboardProvider.isInitialized
                ? clipboardProvider.history.isEmpty
                    ? Center(
                        child: Text(
                          clipboardProvider.searchQuery.isEmpty
                            ? 'Clipboard history is empty.\nStart copying!'
                            : 'No results found.',
                           textAlign: TextAlign.center,
                           style: theme.textTheme.tabLabelTextStyle.copyWith(fontSize: 14 * settings.fontSizeModifier),
                         )
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: clipboardProvider.history.length,
                        itemBuilder: (context, index) {
                          final item = clipboardProvider.history[index];
                          return ClipboardListItem(
                             item: item,
                             index: index, // Pass index
                             key: ValueKey(item.id), // Use unique key for better updates
                           );
                        },
                      )
                : const Center(child: CupertinoActivityIndicator()), // Loading state
        ),
      ),
    );
  }
}