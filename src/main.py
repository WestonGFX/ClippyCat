import tkinter as tk
from tkinter import scrolledtext, messagebox
import threading
import time
import logging
from clipboard_handler import ClipboardHandler

class ClipboardLoggerGUI:
    def __init__(self, master):
        self.master = master
        master.title("Clipboard Logger")

        self.log_area = scrolledtext.ScrolledText(master, wrap=tk.WORD, width=50, height=20)
        self.log_area.pack(pady=10)

        self.start_button = tk.Button(master, text="Start Logging", command=self.start_logging)
        self.start_button.pack(pady=5)

        self.stop_button = tk.Button(master, text="Stop Logging", command=self.stop_logging, state=tk.DISABLED)
        self.stop_button.pack(pady=5)

        self.clipboard_handler = ClipboardHandler(self.log_area)
        self.logging_thread = None
        self.is_logging = False

    def start_logging(self):
        if not self.is_logging:
            self.is_logging = True
            self.start_button.config(state=tk.DISABLED)
            self.stop_button.config(state=tk.NORMAL)
            self.logging_thread = threading.Thread(target=self.clipboard_handler.start_logging)
            self.logging_thread.start()

    def stop_logging(self):
        if self.is_logging:
            self.is_logging = False
            self.start_button.config(state=tk.NORMAL)
            self.stop_button.config(state=tk.DISABLED)
            self.clipboard_handler.stop_logging()

if __name__ == "__main__":
    root = tk.Tk()
    app = ClipboardLoggerGUI(root)
    root.mainloop()