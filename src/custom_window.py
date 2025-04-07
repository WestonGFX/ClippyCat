import tkinter as tk
from tkinter import ttk
import darkdetect

class BorderlessWindow(tk.Tk):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Remove window decorations
        self.overrideredirect(True)
        
        # Make window draggable
        self.bind("<Button-1>", self.start_move)
        self.bind("<ButtonRelease-1>", self.stop_move)
        self.bind("<B1-Motion>", self.do_move)

        # Add minimize/close buttons
        self.setup_title_bar()
        
        # Center window
        self.center_window()
        
    def setup_title_bar(self):
        self.title_bar = ttk.Frame(self)
        self.title_bar.pack(fill='x', side='top')
        
        # Close button
        self.close_button = ttk.Button(self.title_bar, text='×', width=3, 
                                     command=self.quit)
        self.close_button.pack(side='right')
        
        # Minimize button
        self.min_button = ttk.Button(self.title_bar, text='-', width=3,
                                   command=self.minimize)
        self.min_button.pack(side='right')

    def start_move(self, event):
        self.x = event.x
        self.y = event.y

    def stop_move(self, event):
        self.x = None
        self.y = None

    def do_move(self, event):
        deltax = event.x - self.x
        deltay = event.y - self.y
        x = self.winfo_x() + deltax
        y = self.winfo_y() + deltay
        self.geometry(f"+{x}+{y}")

    def center_window(self):
        screen_width = self.winfo_screenwidth()
        screen_height = self.winfo_screenheight()
        window_width = 800  # Default width
        window_height = 500  # Default height
        x = (screen_width - window_width) // 2
        y = (screen_height - window_height) // 2
        self.geometry(f"{window_width}x{window_height}+{x}+{y}")
