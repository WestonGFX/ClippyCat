# ClippyCat - A Lightweight Clipboard Manager

ClippyCat is a lightweight and feature-rich clipboard manager designed to help you track, organize, and manage your clipboard history. With a modern GUI, support for text and images, and advanced features like search, tagging, and favorites, ClippyCat is the perfect tool for anyone who frequently works with copied content.

## Features

- **Clipboard History**: Automatically logs clipboard content (text and images) for easy access.
- **Search Functionality**: Quickly find clipboard items using a search bar.
- **Favorites**: Mark important clipboard items as favorites for quick access.
- **Tags and Categories**: Organize clipboard items with tags.
- **Modern UI**: A clean and responsive interface with light and dark themes.
- **Hotkey Support**: Use customizable hotkeys for quick actions like pasting or toggling the app.
- **SQLite Storage**: Stores clipboard history in a local SQLite database for persistence.
- **Duplicate Detection**: Prevents duplicate clipboard entries.
- **Preview**: Displays a preview of clipboard content in the GUI.
- **Image Support**: Logs and previews images copied to the clipboard.
- **Export/Import**: Save and load clipboard history for backup or sharing.
- **Tray Icon**: Runs in the system tray for easy access and minimal interruption.
- **Customizable Themes**: Offers a variety of themes to suit your preferences.

## Project Structure

```
clipboard_logger_gui
├── src
│   ├── main.py              # Entry point of the application
│   ├── clipboard_handler.py  # Handles clipboard operations
│   ├── gui.py               # Contains the GUI implementation
│   ├── themes.py            # Defines the available themes
│   └── clippycat_icon.png   # Icon file for the application
├── config
│   └── config.ini           # Configuration file for settings
├── README.md                # Documentation for the project
├── requirements.txt         # List of dependencies
└── clipboard.db             # SQLite database for clipboard history (auto-generated)
```

## Installation

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd clipboard_logger_gui
   ```

2. **Install Dependencies**:
   Ensure you have Python 3.7+ installed. Then, run:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure the Application**:
   Edit the `config/config.ini` file to customize settings such as maximum clipboard size, hotkeys, UI preferences, and database size.

4. **Run the Application**:
   ```bash
   python src/gui.py
   ```

## Usage

1. **Start Logging**:
   - Launch the application. It will start in the system tray.
   - To start monitoring the clipboard, open the app from the tray icon.
   - The clipboard content will be logged and displayed in the GUI.

2. **Search and Manage History**:
   - Use the search bar to find specific clipboard items.
   - Mark items as favorites or organize them with tags.

3. **Quick Paste**:
   - Use the hotkey `Ctrl+Shift+V` to open the quick paste menu.

4. **Stop Logging**:
   - To stop monitoring, close the main window. The app will continue running in the system tray.

5. **Settings**:
   - Access settings from the File menu to customize themes, hotkeys, encryption, and more.

6. **Tray Icon**:
   - Right-click the tray icon to access the menu with options to open the app or exit.

## Dependencies

- **Python Libraries**:
  - `pyperclip`: For clipboard access.
  - `tkinter`: For the graphical user interface.
  - `sqlite3`: For storing clipboard history.
  - `keyboard`: For hotkey support.
  - `ttkthemes`: For modern UI themes.
  - `Pillow`: For handling image clipboard content.
  - `pystray`: For system tray icon functionality.
  - `cryptography`: For content encryption.

Install these dependencies using the `requirements.txt` file.

## Themes

ClippyCat comes with a variety of built-in themes:

- Default
- Dark
- Pastel
- Retro
- High Contrast
- Monokai
- Solarized Light
- Solarized Dark
- Gruvbox Light
- Gruvbox Dark

You can switch between themes in the Settings menu.

## To-Do List

Here are some ideas to improve ClippyCat:

1. **Customizable Themes**: Allow users to create and apply custom themes.
2. **Clipboard Item Editing**: Enable users to edit text clipboard items directly in the app.
3. **Advanced Search**: Add filters for content type, tags, and date ranges.
4. **Clipboard Item Preview**: Show a preview of clipboard items before pasting.
5. **Custom Hotkeys**: Allow users to configure their own hotkeys.
6. **Drag-and-Drop Support**: Enable dragging clipboard items into other applications.
7. **Encrypted Storage**: Add an option to encrypt clipboard history for security.
8. **Auto-Cleanup**: Automatically delete old clipboard items based on user-defined rules.
9. **Rich Text Support**: Handle rich text formats like HTML and Markdown.
10. **Image Compression**: Option to compress images before saving to reduce database size.
11. **Clipboard Templates**: Save frequently used text snippets as templates.
12. **Dark Mode Toggle**: Add a button to quickly switch between light and dark modes.
13. **Performance Optimization**: Improve the app's responsiveness with large clipboard histories.

Extra to-do list for new features:

1.  **OCR Support**: Implement OCR (Optical Character Recognition) to extract text from images copied to the clipboard.
2.  **Context Menu Integration**: Add options to the right-click context menu for quick access to ClippyCat features.
3.  **Regular Expression Support**: Allow users to search clipboard items using regular expressions.
4.  **Automatic Tagging**: Automatically tag clipboard items based on content analysis.
5.  **Global Hotkeys**: Set global hotkeys for specific actions, even when the app is minimized.
6.  **Password Protection**: Require a password to access the clipboard history.
7.  **Network Clipboard**: Share clipboard content across multiple computers on a local network.
8.  **Scripting Support**: Allow users to automate tasks using scripts.
9.  **Version Control Integration**: Integrate with version control systems to track changes to code snippets.
10. **Audio Clip Support**: Add support for logging and playing audio clips copied to the clipboard.

Extra features to come in future releases:

1. **Add Cloud Sync**: Sync clipboard history across devices using cloud storage.
2. **Clipboard Analytics**: Provide insights into clipboard usage patterns.
3. **Clipboard Sharing**: Share clipboard items via email or messaging apps.
4. **Multi-Monitor Support**: Ensure the app works seamlessly across multiple monitors.
5. **Clipboard History Limit**: Allow users to set a maximum number of clipboard items to keep.
6. **Mobile App**: Develop a companion app for Android and iOS.
7. **Portable Mode**: Create a portable version of the app that runs without installation.
8. **Integration with Password Managers**: Prevent sensitive data like passwords from being logged.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.

## Contributing

We welcome contributions! If you'd like to contribute, please fork the repository, make your changes, and submit a pull request. For major changes, please open an issue first to discuss what you'd like to change.

## Screenshots

![ClippyCat Light Theme](https://via.placeholder.com/400x300?text=Light+Theme+Screenshot)
![ClippyCat Dark Theme](https://via.placeholder.com/400x300?text=Dark+Theme+Screenshot)

---

Thank you for using ClippyCat! If you have any questions or feedback, feel free to open an issue or contact us.