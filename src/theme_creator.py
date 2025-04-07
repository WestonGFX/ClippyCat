import tkinter as tk
from tkinter import ttk, colorchooser, messagebox
import json
import os
import logging

class ThemeCreator(tk.Toplevel):
    def __init__(self, master, themes_dir):
        super().__init__(master)
        self.title("Custom Theme Creator")
        self.themes_dir = themes_dir
        self.setup_ui()

    def setup_ui(self):
        ttk.Label(self, text="Theme Name:").grid(row=0, column=0, padx=5, pady=5)
        self.name_entry = ttk.Entry(self)
        self.name_entry.grid(row=0, column=1, padx=5, pady=5)

        self.colors = {
            "bg": "#282a36",
            "fg": "#f8f8f2",
            "entry_bg": "#44475a",
            "entry_fg": "#f8f8f2",
            "button_bg": "#6272a4",
            "button_fg": "#f8f8f2"
        }
        row = 1
        self.color_buttons = {}
        for key, value in self.colors.items():
            ttk.Label(self, text=f"{key}:").grid(row=row, column=0, padx=5, pady=5)
            btn = ttk.Button(self, text=value, command=lambda k=key: self.choose_color(k))
            btn.grid(row=row, column=1, padx=5, pady=5)
            self.color_buttons[key] = btn
            row += 1

        save_btn = ttk.Button(self, text="Save Theme", command=self.save_theme)
        save_btn.grid(row=row, column=0, columnspan=2, pady=10)

    def choose_color(self, key):
        color_code = colorchooser.askcolor(title=f"Choose color for {key}")[1]
        if color_code:
            self.colors[key] = color_code
            self.color_buttons[key].config(text=color_code)

    def save_theme(self):
        try:
            theme_name = self.name_entry.get().strip()
            if not theme_name:
                messagebox.showerror("Error", "Theme name cannot be empty.")
                return
            theme_data = {
                "name": theme_name,
                "bg": self.colors["bg"],
                "fg": self.colors["fg"],
                "entry_bg": self.colors["entry_bg"],
                "entry_fg": self.colors["entry_fg"],
                "button_bg": self.colors["button_bg"],
                "button_fg": self.colors["button_fg"]
            }
            theme_path = os.path.join(self.themes_dir, f"{theme_name}.json")
            with open(theme_path, "w") as f:
                json.dump(theme_data, f, indent=4)
            messagebox.showinfo("Success", "Theme saved successfully!")
            self.destroy()
        except Exception as e:
            logging.exception("Failed to save theme: %s", e)
            messagebox.showerror("Error", f"Failed to save theme: {e}")
