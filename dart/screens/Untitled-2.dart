import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/themes.dart'; // For theme names

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Consumer for specific rebuilds, or watch the whole provider
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = CupertinoTheme.of(context);

    // Helper for scaling
    double scale(double value) => value * settings.paddingScale;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
        // Optional: Add a "Done" button if presented modally
        // trailing: CupertinoButton(child: Text("Done"), onPressed: () => Navigator.pop(context)),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // --- General Settings ---
            CupertinoListSection.insetGrouped(
               header: const Text('GENERAL'),
               children: [
                 _buildSwitchTile(
                   context: context,
                   label: 'Minimize to Tray on Close',
                   value: settings.closeToTray,
                   onChanged: (value) => settings.setCloseToTray(value),
                 ),
                 // TODO: Add Launch on Startup (requires platform-specific package/code)
                  _buildPickerTile(
                      context: context,
                      label: 'Theme',
                      value: themeProvider.themeName,
                      items: themeNames,
                      onChanged: (newValue) {
                          if (newValue != null) {
                             themeProvider.setTheme(newValue);
                          }
                      }
                  ),
               ],
             ),

            // --- History Settings ---
            CupertinoListSection.insetGrouped(
              header: const Text('HISTORY'),
              children: [
                _buildSliderTile(
                  context: context,
                  label: 'Max History Items: ${settings.maxHistoryItems}',
                  value: settings.maxHistoryItems.toDouble(),
                  min: 10,
                  max: 1000,
                  divisions: (1000 - 10) ~/ 10, // Steps of 10
                  onChanged: (value) => settings.setMaxHistoryItems(value.toInt()),
                ),
                 _buildSliderTile(
                  context: context,
                  label: 'Database Size Limit (MB): ${settings.databaseSizeLimitMB.toStringAsFixed(0)}',
                  value: settings.databaseSizeLimitMB,
                  min: 50,
                  max: 2048, // 2GB example max
                  divisions: (2048 - 50) ~/ 50, // Steps of 50MB
                  onChanged: (value) => settings.setDatabaseSizeLimitMB(value),
                ),
                _buildSwitchTile(
                   context: context,
                   label: 'Warn near item limit (85%)',
                   value: settings.warnItemCount,
                   onChanged: (v) => {}, // settings.setWarnItemCount(v) - Implement setter
                 ),
                 _buildSwitchTile(
                   context: context,
                   label: 'Warn near size limit (85%)',
                   value: settings.warnDbSize,
                   onChanged: (v) => {},// settings.setWarnDbSize(v) - Implement setter
                 ),
                // TODO: Add Image Compression Toggle + Quality Slider
                // TODO: Add Edit AutoSave Toggle + Timer Input
              ],
            ),

              // --- Appearance Settings ---
            CupertinoListSection.insetGrouped(
               header: const Text('APPEARANCE'),
               children: [
                 // TODO: Add Font Family Picker (requires font loading/system font access)
                 // _buildPickerTile(context: context, label: 'Font', ...)
                 _buildSliderTile(
                    context: context,
                    label: 'Font Size Scale: ${settings.fontSizeModifier.toStringAsFixed(1)}x',
                    value: settings.fontSizeModifier,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7, // e.g., steps of 0.1
                    onChanged: (value) => settings.setFontSizeModifier(value),
                 ),
                  _buildSliderTile(
                    context: context,
                    label: 'Padding Scale: ${settings.paddingScale.toStringAsFixed(1)}x',
                    value: settings.paddingScale,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7, // e.g., steps of 0.1
                    onChanged: (value) => settings.setPaddingScale(value),
                 ),
                  // TODO: Add Corner Radius Slider?
                  // TODO: Add Background Blur Toggle?
               ],
             ),

            // --- Auto-Cleanup Settings ---
            CupertinoListSection.insetGrouped(
              header: const Text('AUTO-CLEANUP'),
              children: [
                _buildSwitchTile(
                   context: context,
                   label: 'Enable Auto-Cleanup',
                   value: settings.autoCleanupEnabled,
                   onChanged: (v) => {},// settings.setAutoCleanupEnabled(v) - Implement setter
                 ),
                if (settings.autoCleanupEnabled) // Only show if enabled
                  _buildTextFieldTile(
                      context: context,
                      label: 'Delete items older than (days):',
                      initialValue: settings.autoCleanupDays.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                          final days = int.tryParse(value);
                          if (days != null && days > 0) {
                              // settings.setAutoCleanupDays(days); // Implement setter
                          }
                      }
                  ),
              ],
            ),

            // --- Hotkeys ---
             CupertinoListSection.insetGrouped(
                 header: const Text('HOTKEYS'),
                 footer: const Text('Configure global shortcuts (requires app restart to apply changes potentially).'),
                 children: [
                    // TODO: List hotkeys and provide way to edit (complex UI)
                    _buildInfoTile(context, 'Activate Window Hotkey', '[Configured Hotkey]'), // Placeholder
                    _buildInfoTile(context, 'Paste Item #1 Hotkey', '[Configured Hotkey]'), // Placeholder
                     _buildSwitchTile(context: context, label: 'Enable Direct Paste Hotkeys (1-9)', value: false, onChanged: (v){}), // Placeholder
                 ]
             ),

              // --- Security ---
             CupertinoListSection.insetGrouped(
                 header: const Text('SECURITY'),
                 children: [
                      _buildSwitchTile(
                         context: context,
                         label: 'Encrypt Database (Requires Restart)',
                         value: settings.encryptDatabase,
                         onChanged: (v) {
                              // TODO: Implement encryption setup/password prompt
                              // settings.setEncryptDatabase(v);
                              print("Encryption Toggle - Implementation needed");
                         }),
                 ]
             ),


            // --- Actions ---
             CupertinoListSection.insetGrouped(
               children: [
                  CupertinoListTile(
                      title: const Text('Clear History', style: TextStyle(color: CupertinoColors.systemRed)),
                      leading: const Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed),
                      onTap: () async {
                         // Show confirmation dialog
                         final confirm = await showCupertinoDialog<bool>(
                             context: context,
                             builder: (context) => CupertinoAlertDialog(
                               title: const Text('Clear History?'),
                               content: const Text('This will permanently delete all clipboard history. This action cannot be undone.'),
                               actions: [
                                 CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
                                 CupertinoDialogAction(isDestructiveAction: true, child: const Text('Clear'), onPressed: () => Navigator.pop(context, true)),
                               ],
                             ),
                          );
                         if (confirm == true) {
                           // ignore: use_build_context_synchronously
                           await Provider.of<ClipboardProvider>(context, listen: false).clearHistory();
                         }
                      },
                   ),
               ]
             ),
             SizedBox(height: scale(30)), // Bottom padding
          ],
        ),
      ),
    );
  }

  // Helper widgets for consistent setting tiles
  Widget _buildSwitchTile({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = CupertinoTheme.of(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return CupertinoListTile(
      title: Text(label, style: TextStyle(fontSize: 15 * settings.fontSizeModifier)),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.primaryColor,
      ),
      padding: EdgeInsets.symmetric(vertical: 10 * settings.paddingScale, horizontal: 16 * settings.paddingScale),
    );
  }

  Widget _buildSliderTile({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
     final settings = Provider.of<SettingsProvider>(context, listen: false);
     final theme = CupertinoTheme.of(context);
    return CupertinoListTile(
      title: Text(label, style: TextStyle(fontSize: 14 * settings.fontSizeModifier)),
      subtitle: CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        activeColor: theme.primaryColor,
      ),
       padding: EdgeInsets.symmetric(vertical: 8 * settings.paddingScale, horizontal: 16 * settings.paddingScale),
    );
  }

   Widget _buildPickerTile<T>({
     required BuildContext context,
     required String label,
     required T value,
     required List<T> items,
     required ValueChanged<T?> onChanged,
   }) {
       final settings = Provider.of<SettingsProvider>(context, listen: false);
       final theme = CupertinoTheme.of(context);
       return CupertinoListTile(
         title: Text(label, style: TextStyle(fontSize: 15 * settings.fontSizeModifier)),
         trailing: Text(value.toString(), style: theme.textTheme.tabLabelTextStyle.copyWith(fontSize: 14* settings.fontSizeModifier)),
         onTap: () {
           showCupertinoModalPopup(
             context: context,
             builder: (_) => Container(
                height: 250 * settings.paddingScale,
                color: theme.scaffoldBackgroundColor, // Use theme background
                child: CupertinoPicker(
                   scrollController: FixedExtentScrollController(
                        initialItem: items.indexOf(value) !=-1 ? items.indexOf(value) : 0,
                    ),
                   itemExtent: 32.0 * settings.paddingScale,
                   onSelectedItemChanged: (int index) {
                      onChanged(items[index]);
                   },
                   children: items.map((item) => Center(child: Text(item.toString(), style: TextStyle(fontSize: 18 * settings.fontSizeModifier)))).toList(),
                ),
             ),
           );
         },
          padding: EdgeInsets.symmetric(vertical: 10 * settings.paddingScale, horizontal: 16 * settings.paddingScale),
       );
   }

    Widget _buildTextFieldTile({
      required BuildContext context,
      required String label,
      required String initialValue,
      ValueChanged<String>? onChanged,
      TextInputType keyboardType = TextInputType.text,
    }) {
       final settings = Provider.of<SettingsProvider>(context, listen: false);
       // Use a stateful widget internally or a controller if needed for complex updates
       return CupertinoListTile(
           title: Text(label, style: TextStyle(fontSize: 15 * settings.fontSizeModifier)),
           trailing: SizedBox(
              width: 80 * settings.paddingScale, // Adjust width as needed
              child: CupertinoTextField(
                 controller: TextEditingController(text: initialValue), // Basic controller
                 onChanged: onChanged,
                 keyboardType: keyboardType,
                 textAlign: TextAlign.end,
                 style: TextStyle(fontSize: 14 * settings.fontSizeModifier),
                 padding: EdgeInsets.symmetric(vertical: 4 * settings.paddingScale, horizontal: 6 * settings.paddingScale),
                  decoration: BoxDecoration(
                     color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                     borderRadius: BorderRadius.circular(4 * settings.paddingScale),
                  ),
               ),
           ),
           padding: EdgeInsets.symmetric(vertical: 10 * settings.paddingScale, horizontal: 16 * settings.paddingScale),
       );
    }

    Widget _buildInfoTile(BuildContext context, String label, String valueText) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        final theme = CupertinoTheme.of(context);
        return CupertinoListTile(
             title: Text(label, style: TextStyle(fontSize: 15 * settings.fontSizeModifier)),
             trailing: Text(valueText, style: theme.textTheme.tabLabelTextStyle.copyWith(fontSize: 14* settings.fontSizeModifier)),
              padding: EdgeInsets.symmetric(vertical: 10 * settings.paddingScale, horizontal: 16 * settings.paddingScale),
        );
    }
}