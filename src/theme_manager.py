import json
import os
from pathlib import Path

class ThemeManager:
    def __init__(self):
        self.themes_dir = Path("themes")
        self.themes_dir.mkdir(exist_ok=True)
        self.custom_themes = {}
        self.load_custom_themes()

    def load_custom_themes(self):
        for theme_file in self.themes_dir.glob("*.json"):
            with open(theme_file) as f:
                theme = json.load(f)
                self.custom_themes[theme["name"]] = theme

    def save_theme(self, name, colors):
        theme = {
            "name": name,
            "colors": colors,
            "custom": True
        }
        
        with open(self.themes_dir / f"{name}.json", "w") as f:
            json.dump(theme, f, indent=4)
            
        self.custom_themes[name] = theme
        return theme

    def get_all_themes(self):
        return {**self.built_in_themes, **self.custom_themes}
