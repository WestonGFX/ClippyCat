import sys
import os
import tkinter as tk
from tkinter import ttk, simpledialog, filedialog, messagebox, font
import keyboard
from ttkthemes import ThemedTk
import json
import logging
import threading
import time
import pyperclip
import configparser
import pystray
from PIL import Image

# Add the parent directory to the Python path to resolve the 'src' module
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from themes import themes  # Import the themes

def get_int(config, section, key, fallback):
    val = config.get(section, key, fallback=fallback)
    return int(val.split(';')[0].strip())

class ClipboardLoggerGUI:
    def __init__(self):
        try:
            # Initialize root first
            self.root = tk.Tk()
            self.root.title("ClippyCat")
            self.root.configure(background="#282a36")

            # Get base paths and setup configs
            self.base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
            self.config_dir = os.path.join(self.base_dir, 'config')
            self.config_path = os.path.join(self.config_dir, 'config.ini')
            self.log_path = os.path.join(self.base_dir, 'clipboard_log.txt')

            # Create required directories
            os.makedirs(self.config_dir, exist_ok=True)

            self.config = configparser.ConfigParser()
            if os.path.exists(self.config_path):
                self.config.read(self.config_path)

            self.ensure_config_sections()

            # Setup the rest of the GUI
            self.load_theme()
            self.setup_styles()
            self.setup_ui()
            self.bind_hotkeys()
            self.logging_active = False
            self.last_copied = ""
            self.tray_icon = None
            self.setup_tray_icon()
        except Exception as e:
            logging.exception("Failed to initialize GUI: %s", e)
            messagebox.showerror("Error", f"Failed to initialize GUI: {e}")
            sys.exit(1)

    def setup_config(self):
        """Setup configuration file with defaults if it doesn't exist."""
        self.config = configparser.ConfigParser()
        
        # Try to read existing config
        if os.path.exists(self.config_path):
            self.config.read(self.config_path)
        
        self.ensure_config_sections()

    def ensure_config_sections(self):
        """Ensure required sections exist in the configuration file."""
        required_sections = {
            'UI': {
                'theme': 'default',
                'dark_mode': 'false',
                'window_width': '400',
                'window_height': '600',
                'preview_length': '100'
            },
            'Hotkeys': {
                'quick_paste': 'ctrl+shift+v',
                'toggle_window': 'ctrl+shift+space',
                'clear_history': 'ctrl+shift+x'
            },
            'General': {
                'max_size': '104857600',
                'max_db_size': '104857600',
                'history_limit': '1000',
                'enable_images': 'true',
                'enable_formatting': 'true'
            },
            'Security': {
                'enable_encryption': 'false',
                'encryption_key': 'default_key'
            },
            'Image': {
                'enable_image_compression': 'false',
                'compression_level': '75'
            },
            'Cleanup': {
                'enable_auto_cleanup': 'false',
                'cleanup_interval': '30'
            }
        }

        # Add missing sections and their default values
        for section, options in required_sections.items():
            if not self.config.has_section(section):
                self.config.add_section(section)
            for option, value in options.items():
                if not self.config.has_option(section, option):
                    self.config.set(section, option, value)

        # Save the config file using absolute path
        try:
            with open(self.config_path, 'w', encoding='utf-8') as configfile:
                self.config.write(configfile)
        except Exception as e:
            logging.error(f"Failed to save config file: {e}")
            messagebox.showerror("Error", f"Failed to save configuration: {e}")

    def load_theme(self):
        theme_name = self.config.get('UI', 'theme', fallback='default')
        self.current_theme = themes.get(theme_name, themes['default'])
        self.root.configure(bg=self.current_theme['bg'])

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')  # Use a modern theme
        
        # Configure styles for different elements
        style.configure("TFrame", background=self.current_theme['bg'], padding=(10, 5))
        style.configure("TLabel", background=self.current_theme['bg'], foreground=self.current_theme['fg'], padding=(5, 2))
        style.configure("TButton", background=self.current_theme['button_bg'], foreground=self.current_theme['button_fg'], padding=(8, 3), borderwidth=0, relief="flat", font=('Arial', 10))
        style.configure("Search.TEntry", padding=5, background=self.current_theme['entry_bg'], foreground=self.current_theme['entry_fg'], borderwidth=0, relief="flat")
        style.configure("Clip.TFrame", background=self.current_theme['bg'], padding=(10, 5), borderwidth=0, relief="flat")
        style.configure("Drop.TFrame", background=self.current_theme.get('drop_bg', self.current_theme['bg']), padding=(10, 5), borderwidth=0, relief="flat")

        # Configure Combobox style
        style.configure("TCombobox", background=self.current_theme['entry_bg'], foreground=self.current_theme['entry_fg'], padding=5, borderwidth=0, relief="flat")
        style.map("TCombobox",
            fieldbackground=[("readonly", self.current_theme['entry_bg'])],
            background=[("readonly", self.current_theme['entry_bg'])],
            foreground=[("readonly", self.current_theme['entry_fg'])])

    def apply_theme(self, theme):
        self.current_theme = theme
        self.root.configure(bg=self.current_theme['bg'])
        self.setup_styles()

        for widget in self.clips_container.winfo_children():
            widget.destroy()
        self.load_clips()

    def setup_ui(self):
        try:
            # Menu Bar
            self.menu_bar = tk.Menu(self.root)
            self.file_menu = tk.Menu(self.menu_bar, tearoff=0)
            self.file_menu.add_command(label="Settings", command=self.open_settings)
            self.file_menu.add_separator()
            self.file_menu.add_command(label="Exit", command=self.root.quit)
            self.menu_bar.add_cascade(label="File", menu=self.file_menu)

            self.theme_menu = tk.Menu(self.menu_bar, tearoff=0)
            for theme_name, theme in themes.items():
                self.theme_menu.add_command(label=theme['name'], command=lambda t=theme: self.apply_theme(t))
            self.menu_bar.add_cascade(label="Themes", menu=self.theme_menu)

            self.root.config(menu=self.menu_bar)

            # Search bar
            self.search_frame = ttk.Frame(self.root, padding=(10, 10))
            self.search_frame.pack(fill='x')

            self.search_var = tk.StringVar()
            self.search_entry = ttk.Entry(self.search_frame, textvariable=self.search_var, style="Search.TEntry")
            self.search_entry.pack(side='left', fill='x', expand=True)
            self.search_var.trace('w', self.on_search)

            # Clips list
            self.clips_frame = ttk.Frame(self.root, padding=(10, 0))
            self.clips_frame.pack(fill='both', expand=True)

            self.clips_canvas = tk.Canvas(self.clips_frame, highlightthickness=0, bg=self.current_theme['bg'])
            self.scrollbar = ttk.Scrollbar(self.clips_frame, orient='vertical', command=self.clips_canvas.yview)
            self.clips_canvas.config(yscrollcommand=self.scrollbar.set)

            self.clips_container = ttk.Frame(self.clips_canvas, style="Clip.TFrame", padding=(5, 5))
            self.canvas_window = self.clips_canvas.create_window((0, 0), window=self.clips_container, anchor='nw')

            def on_frame_configure(event):
                if self.clips_canvas.winfo_exists():
                    self.clips_canvas.configure(scrollregion=self.clips_canvas.bbox("all"))

            def on_canvas_configure(event):
                if self.clips_canvas.winfo_exists():
                    width = event.width
                    self.clips_canvas.itemconfig(self.canvas_window, width=width)

            self.clips_container.bind('<Configure>', on_frame_configure)
            self.clips_canvas.bind('<Configure>', on_canvas_configure)

            self.clips_canvas.pack(side="left", fill="both", expand=True)
            self.scrollbar.pack(side="right", fill="y")

            # Start and Stop buttons
            button_frame = ttk.Frame(self.root, padding=(10, 10))
            button_frame.pack(fill='x')

            self.start_button = ttk.Button(button_frame, text="Start Logging", command=self.start_logging)
            self.start_button.pack(side=tk.LEFT, padx=(0, 5))

            self.stop_button = ttk.Button(button_frame, text="Stop Logging", command=self.stop_logging)
            self.stop_button.pack(side=tk.LEFT, padx=(5, 0))

            self.load_clips()
        except Exception as e:
            logging.exception("Failed to set up UI: %s", e)
            messagebox.showerror("Error", f"Failed to set up UI: {e}")

    def load_clips(self):
        # Load clips from the database and display them
        pass

    def bind_hotkeys(self):
        keyboard.add_hotkey(self.config.get('Hotkeys', 'quick_paste', fallback='ctrl+shift+v'), self.show_quick_paste)
        keyboard.add_hotkey(self.config.get('Hotkeys', 'toggle_window', fallback='ctrl+shift+space'), self.toggle_window)

    def create_clip_widget(self, clip_data):
        frame = ttk.Frame(self.clips_container, style="Clip.TFrame", padding=(5,5))
        frame.pack(fill='x', pady=2)

        if clip_data.get('type') == 'text':
            preview = clip_data.get('preview', '')
            label = ttk.Label(frame, text=preview, wraplength=500, style="TLabel", padding=(5,5))
            label.pack(side='left', fill='x', expand=True)
            label.bind("<Button-1>", lambda event, data=clip_data.get('content', ''): self.preview_clip(data))
        else:
            # Handle image preview
            pass

        button_style = ttk.Style()
        button_style.configure("Small.TButton", padding=(3, 1), font=('Arial', 8))

        star_button = ttk.Button(frame, text="☆", command=lambda: self.toggle_favorite(clip_data.get('id')), style="Small.TButton")
        star_button.pack(side='right', padx=(0, 2))

        edit_button = ttk.Button(frame, text="Edit", command=lambda: self.edit_clip(clip_data), style="Small.TButton")
        edit_button.pack(side='right', padx=(2, 0))

    def preview_clip(self, data):
        # Show a preview of the full clip content
        PreviewWindow(self.root, data, self.current_theme)

    def edit_clip(self, clip_data):
        # Edit the clip content
        EditClipDialog(self.root, clip_data, self.apply_theme)

    def show_quick_paste(self):
        # Quick paste menu implementation
        pass

    def toggle_window(self):
        # Window show/hide implementation
        pass

    def on_search(self, *args):
        # Search implementation
        pass

    def start_logging(self):
        self.logging_active = True
        threading.Thread(target=self.log_clipboard).start()

    def stop_logging(self):
        self.logging_active = False

    def log_clipboard(self):
        poll_interval = 0.5  # Reduced interval for responsiveness
        while self.logging_active:
            try:
                current = pyperclip.paste()
                if current != self.last_copied:
                    self.last_copied = current
                    logging.info(f"Clipboard: {current}")
                    clip_data = {'type': 'text', 'preview': current, 'content': current, 'id': len(current)}
                    self.create_clip_widget(clip_data)
                time.sleep(poll_interval)
            except Exception as e:
                logging.error(f"Error logging clipboard: {e}")

    def open_settings(self):
        SettingsWindow(self.root, self.config, self.apply_theme, self.update_max_db_size)

    def save_settings(self):
        try:
            self.config.set('UI', 'theme', self.theme_var.get())
            self.config.set('UI', 'dark_mode', str(self.dark_mode_var.get()))
            self.config.set('Hotkeys', 'quick_paste', self.hotkey_var.get())
            self.config.set('Security', 'enable_encryption', str(self.encryption_var.get()))
            self.config.set('Image', 'enable_image_compression', str(self.compression_var.get()))
            new_size_mb = int(self.max_db_size_var.get())
            new_size = new_size_mb * 1024 * 1024
            self.config.set('General', 'max_db_size', str(new_size))
            with open(self.config_path, 'w', encoding='utf-8') as configfile:
                self.config.write(configfile)

            selected_theme = themes.get(self.theme_var.get(), themes['default'])
            self.apply_theme_func(selected_theme)
        except ValueError:
            messagebox.showerror("Error", "Invalid database size. Please enter a number.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save settings: {e}")

        self.destroy()

    def update_max_db_size(self, new_size):
        self.config.set('General', 'max_db_size', str(new_size))
        try:
            with open(self.config_path, 'w', encoding='utf-8') as configfile:
                self.config.write(configfile)
            print(f"Max DB size updated to {new_size}")
        except Exception as e:
            logging.error(f"Failed to update max DB size: {e}")
            messagebox.showerror("Error", f"Failed to update database size: {e}")

    def setup_tray_icon(self):
        try:
            icon = Image.open("src/clippycat_icon.png")
        except FileNotFoundError:
            # Create a simple default icon - a 64x64 colored square with 'CC' text
            icon = Image.new('RGB', (64, 64), color='dodgerblue')
            from PIL import ImageDraw, ImageFont
            draw = ImageDraw.Draw(icon)
            try:
                # Try to load a system font
                font = ImageFont.truetype("arial.ttf", 32)
            except:
                # Fallback to default font
                font = ImageFont.load_default()
            
            # Draw 'CC' text in white
            text = "CC"
            text_bbox = draw.textbbox((0, 0), text, font=font)
            text_width = text_bbox[2] - text_bbox[0]
            text_height = text_bbox[3] - text_bbox[1]
            x = (64 - text_width) // 2
            y = (64 - text_height) // 2
            draw.text((x, y), text, font=font, fill='white')
            
            logging.warning("Icon file not found. Using default icon.")

        menu = pystray.Menu(
            pystray.MenuItem("Open ClippyCat", self.show_window),
            pystray.MenuItem("Exit", self.quit_app)
        )

        self.tray_icon = pystray.Icon("ClippyCat", icon, "ClippyCat", menu)
        threading.Thread(target=self.tray_icon.run, daemon=True).start()
        self.root.withdraw()

    def show_window(self):
        self.root.after(0, self.root.deiconify)

    def quit_app(self):
        self.tray_icon.stop()
        self.root.destroy()

    def on_closing(self):
        self.root.withdraw()

class PreviewWindow(simpledialog.Dialog):
    def __init__(self, parent, data, theme):
        self.data = data
        self.theme = theme
        super().__init__(parent, title="Clip Preview")

    def body(self, master):
        self.text = tk.Text(master, wrap=tk.WORD, bg=self.theme['bg'], fg=self.theme['fg'])
        self.text.insert(tk.END, self.data)
        self.text.pack(fill=tk.BOTH, expand=True)
        return self.text

    def buttonbox(self):
        self.ok_button = tk.Button(self, text="OK", width=5, command=self.ok, default=tk.ACTIVE, bg=self.theme['button_bg'], fg=self.theme['button_fg'])
        self.ok_button.pack(side=tk.RIGHT, padx=5, pady=5)
        self.bind("<Return>", self.ok)
        self.bind("<Escape>", self.cancel)

class EditClipDialog(simpledialog.Dialog):
    def __init__(self, parent, clip_data, apply_theme):
        self.clip_data = clip_data
        self.apply_theme_func = apply_theme
        super().__init__(parent, title="Edit Clip")

    def body(self, master):
        self.text = tk.Text(master, wrap=tk.WORD)
        self.text.insert(tk.END, self.clip_data['content'])
        self.text.pack(fill=tk.BOTH, expand=True)
        return self.text

    def apply_current_theme(self):
        pass

    def buttonbox(self):
        self.ok_button = tk.Button(self, text="Save", width=5, command=self.save, default=tk.ACTIVE)
        self.ok_button.pack(side=tk.RIGHT, padx=5, pady=5)
        self.cancel_button = tk.Button(self, text="Cancel", width=5, command=self.cancel)
        self.cancel_button.pack(side=tk.RIGHT, padx=5, pady=5)
        self.bind("<Return>", self.save)
        self.bind("<Escape>", self.cancel)

    def save(self):
        new_content = self.text.get("1.0", tk.END)
        print(f"Saving edited content: {new_content}")
        self.ok()

class SettingsWindow(tk.Toplevel):
    def __init__(self, parent, config, apply_theme_func, update_max_db_size_func):
        super().__init__(parent)
        self.title("Settings")
        self.config = config
        self.apply_theme_func = apply_theme_func
        self.update_max_db_size_func = update_max_db_size_func
        self.theme = themes['default']
        self.setup_ui()

    def setup_ui(self):
        theme_label = ttk.Label(self, text="Theme:")
        theme_label.grid(row=0, column=0, padx=5, pady=5)
        self.theme_var = tk.StringVar(value=self.config.get('UI', 'theme', fallback='default'))
        theme_dropdown = ttk.Combobox(self, textvariable=self.theme_var, values=list(themes.keys()))
        theme_dropdown.grid(row=0, column=1, padx=5, pady=5)

        dark_mode_label = ttk.Label(self, text="Dark Mode:")
        dark_mode_label.grid(row=1, column=0, padx=5, pady=5)
        self.dark_mode_var = tk.BooleanVar(value=self.config.getboolean('UI', 'dark_mode', fallback=False))
        dark_mode_check = tk.Checkbutton(self, variable=self.dark_mode_var)
        dark_mode_check.grid(row=1, column=1, padx=5, pady=5)

        hotkey_label = ttk.Label(self, text="Quick Paste Hotkey:")
        hotkey_label.grid(row=2, column=0, padx=5, pady=5)
        self.hotkey_var = tk.StringVar(value=self.config.get('Hotkeys', 'quick_paste', fallback='ctrl+shift+v'))
        hotkey_entry = ttk.Entry(self, textvariable=self.hotkey_var)
        hotkey_entry.grid(row=2, column=1, padx=5, pady=5)

        encryption_label = ttk.Label(self, text="Enable Encryption:")
        encryption_label.grid(row=3, column=0, padx=5, pady=5)
        self.encryption_var = tk.BooleanVar(value=self.config.getboolean('Security', 'enable_encryption', fallback=False))
        encryption_check = tk.Checkbutton(self, variable=self.encryption_var)
        encryption_check.grid(row=3, column=1, padx=5, pady=5)

        compression_label = ttk.Label(self, text="Enable Image Compression:")
        compression_label.grid(row=4, column=0, padx=5, pady=5)
        self.compression_var = tk.BooleanVar(value=self.config.getboolean('Image', 'enable_image_compression', fallback=False))
        compression_check = tk.Checkbutton(self, variable=self.compression_var)
        compression_check.grid(row=4, column=1, padx=5, pady=5)

        max_db_size_label = ttk.Label(self, text="Max Database Size (MB):")
        max_db_size_label.grid(row=5, column=0, padx=5, pady=5)
        default_size_mb = int(self.config.get('General', 'max_db_size', fallback='104857600')) // (1024 * 1024)
        self.max_db_size_var = tk.StringVar(value=str(default_size_mb))
        max_db_size_entry = ttk.Entry(self, textvariable=self.max_db_size_var)
        max_db_size_entry.grid(row=5, column=1, padx=5, pady=5)

        save_button = ttk.Button(self, text="Save", command=self.save_settings)
        save_button.grid(row=6, column=0, columnspan=2, padx=5, pady=10)

        advanced_row = 7
        create_theme_button = ttk.Button(self, text="Create Custom Theme", command=self.open_theme_creator)
        create_theme_button.grid(row=advanced_row, column=0, columnspan=2, padx=5, pady=10)

    def open_theme_creator(self):
        from theme_creator import ThemeCreator
        themes_dir = os.path.join(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')), "themes")
        ThemeCreator(self, themes_dir)

    def save_settings(self):
        try:
            self.config.set('UI', 'theme', self.theme_var.get())
            self.config.set('UI', 'dark_mode', str(self.dark_mode_var.get()))
            self.config.set('Hotkeys', 'quick_paste', self.hotkey_var.get())
            self.config.set('Security', 'enable_encryption', str(self.encryption_var.get()))
            self.config.set('Image', 'enable_image_compression', str(self.compression_var.get()))
            new_size_mb = int(self.max_db_size_var.get())
            new_size = new_size_mb * 1024 * 1024
            self.config.set('General', 'max_db_size', str(new_size))
            with open(self.config_path, 'w', encoding='utf-8') as configfile:
                self.config.write(configfile)

            selected_theme = themes.get(self.theme_var.get(), themes['default'])
            self.apply_theme_func(selected_theme)
        except ValueError:
            messagebox.showerror("Error", "Invalid database size. Please enter a number.")
        except configparser.Error as e:
            messagebox.showerror("Error", f"Failed to save settings: {e}")

        self.destroy()

if __name__ == "__main__":
    try:
        base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
        log_path = os.path.join(base_dir, 'clipboard_log.txt')
        logging.basicConfig(
            filename=log_path,
            level=logging.INFO,
            format='%(asctime)s - %(message)s',
            encoding='utf-8'
        )
        gui = ClipboardLoggerGUI()
        gui.root.protocol("WM_DELETE_WINDOW", gui.on_closing)
        gui.root.mainloop()
    except Exception as e:
        print(f"Fatal error: {e}")
        logging.exception("Fatal error occurred")