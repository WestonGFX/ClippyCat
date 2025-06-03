import json
from pathlib import Path

# Import the predefined themes packaged with the application
from themes import themes as built_in_themes


class ThemeManager:
    """Manage built-in and user-defined themes.

    The manager loads predefined themes from :mod:`themes` and merges them with
    any custom themes stored on disk.  It also exposes helper methods for
    creating, deleting and exporting themes.
    """

    def __init__(self, themes_dir: Path | str = "themes"):
        self.themes_dir = Path(themes_dir)
        self.themes_dir.mkdir(exist_ok=True)

        # Themes that ship with the application remain immutable so we keep a
        # dedicated dictionary for them.
        self.built_in_themes: dict[str, dict] = built_in_themes

        # Custom themes persisted to ``themes_dir``.
        self.custom_themes: dict[str, dict] = {}

        self.load_custom_themes()

    def load_custom_themes(self):
        for theme_file in self.themes_dir.glob("*.json"):
            with open(theme_file) as f:
                theme = json.load(f)
                self.custom_themes[theme["name"]] = theme

    def reload(self) -> None:
        """Reload custom themes from disk."""
        self.custom_themes.clear()
        self.load_custom_themes()

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

    def delete_theme(self, name: str) -> bool:
        """Remove a theme file and its cached entry.

        Parameters
        ----------
        name: str
            Name of the theme to remove.

        Returns
        -------
        bool
            ``True`` if a theme was deleted.
        """
        path = self.themes_dir / f"{name}.json"
        if path.exists():
            path.unlink()
            self.custom_themes.pop(name, None)
            return True
        return False

    def rename_theme(self, old_name: str, new_name: str) -> bool:
        """Rename a custom theme on disk and in memory."""
        old_path = self.themes_dir / f"{old_name}.json"
        new_path = self.themes_dir / f"{new_name}.json"
        if not old_path.exists() or new_path.exists():
            return False
        old_path.rename(new_path)
        theme = self.custom_themes.pop(old_name)
        theme["name"] = new_name
        self.custom_themes[new_name] = theme
        return True

    def export_themes(self, export_path: Path | str) -> None:
        """Export all themes to a single JSON file."""
        data = self.get_all_themes()
        with open(export_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

    def import_theme(self, path: Path | str) -> dict:
        """Load a theme from a JSON file and save it as a custom theme."""
        with open(path, "r", encoding="utf-8") as f:
            theme = json.load(f)
        name = theme["name"]
        colors = theme.get("colors") or {k: v for k, v in theme.items() if k != "name"}
        return self.save_theme(name, colors)

    def get_all_themes(self):
        return {**self.built_in_themes, **self.custom_themes}
