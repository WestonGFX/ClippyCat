import sqlite3
import json
import base64
from datetime import datetime, timedelta
from PIL import ImageGrab, Image
import io
import configparser
import hashlib
from cryptography.fernet import Fernet
import os
import logging

def get_clean_int(config, section, key, fallback):
    val = config.get(section, key, fallback=fallback)
    return int(val.split(';')[0].strip())

class ClipboardHandler:
    def __init__(self, db_path="clipboard.db", max_size=512 * 1024 * 1024):  # Default 512MB
        self.config = configparser.ConfigParser()
        self.config.read('config/config.ini')
        self.max_size = max_size
        self.max_db_size = get_clean_int(self.config, 'General', 'max_db_size', fallback='104857600')
        self.setup_database(db_path)

    def setup_database(self, db_path):
        try:
            self.conn = sqlite3.connect(db_path)
            self.cursor = self.conn.cursor()
            self.cursor.execute('''
                CREATE TABLE IF NOT EXISTS clips (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    content TEXT,
                    content_type TEXT,
                    timestamp DATETIME,
                    is_favorite BOOLEAN DEFAULT 0,
                    tags TEXT,
                    hash TEXT UNIQUE,
                    preview TEXT
                )
            ''')
            self.conn.commit()
        except sqlite3.Error as e:
            logging.exception("Database setup failed: %s", e)
            raise

    def read_clipboard(self):
        try:
            import pyperclip
            content = pyperclip.paste()
            if content:
                return {'type': 'text', 'content': content}
        except Exception as e:
            logging.error("Failed to read clipboard: %s", e)
        return None

    def log_clipboard(self, clip_data):
        if not clip_data:
            return None

        content = clip_data['content']
        content_type = clip_data['type']

        if content_type == 'text' and len(content) >= self.max_size:
            logging.warning("Content too large, not saved.")
            return "Content too large, not saved."

        content = self.process_content(content, content_type)

        content_hash = hashlib.md5(str(content).encode()).hexdigest()

        try:
            preview = content[:100] if content_type == 'text' else 'Image'
            self.cursor.execute('''
                INSERT INTO clips (content, content_type, timestamp, hash, preview)
                VALUES (?, ?, ?, ?, ?)
            ''', (str(content), content_type, datetime.now(), content_hash, preview))
            self.conn.commit()
            self.cleanup_old_clips()
            return f"Saved: {content_type} clip"
        except sqlite3.IntegrityError:
            logging.warning("Duplicate clip not saved.")
            return "Duplicate clip not saved"
        except sqlite3.Error as e:
            logging.error(f"Failed to log clipboard data: {e}")
            return "Failed to save clip"

    def get_history(self, limit=100, search=None, tag=None, start_date=None, end_date=None):
        try:
            query = "SELECT * FROM clips WHERE 1=1"
            params = []
            if search:
                query += " AND preview LIKE ?"
                params.append(f"%{search}%")
            if tag:
                query += " AND tags LIKE ?"
                params.append(f"%{tag}%")
            if start_date:
                query += " AND timestamp >= ?"
                params.append(start_date)
            if end_date:
                query += " AND timestamp <= ?"
                params.append(end_date)
            query += " ORDER BY timestamp DESC LIMIT ?"
            params.append(limit)

            return self.cursor.execute(query, params).fetchall()
        except sqlite3.Error as e:
            logging.error(f"Failed to fetch history: {e}")
            return []

    def toggle_favorite(self, clip_id):
        try:
            self.cursor.execute('''
                UPDATE clips 
                SET is_favorite = ((is_favorite | 1) - (is_favorite & 1))
                WHERE id = ?
            ''', (clip_id,))
            self.conn.commit()
        except sqlite3.Error as e:
            logging.error(f"Failed to toggle favorite: {e}")

    def process_content(self, content, content_type):
        try:
            if self.config.getboolean('Security', 'enable_encryption', fallback=False):
                content = self.encrypt_content(content)

            if content_type == 'image' and self.config.getboolean('Image', 'enable_image_compression', fallback=False):
                content = self.compress_image(content)

            return content
        except Exception as e:
            logging.error(f"Failed to process content: {e}")
            return content

    def encrypt_content(self, content):
        try:
            key = self.config.get('Security', 'encryption_key', fallback='default_key').encode()
            salt = hashlib.sha256(key).digest()[:16]  # Use SHA256 to generate a 16-byte salt
            kdf = Fernet(base64.urlsafe_b64encode(hashlib.pbkdf2_hmac('sha256', key, salt, 100000)))
            encrypted_content = kdf.encrypt(str(content).encode())
            return encrypted_content.decode()
        except Exception as e:
            logging.error(f"Failed to encrypt content: {e}")
            return content

    def decrypt_content(self, content):
        try:
            key = self.config.get('Security', 'encryption_key', fallback='default_key').encode()
            salt = hashlib.sha256(key).digest()[:16]  # Use SHA256 to generate a 16-byte salt
            kdf = Fernet(base64.urlsafe_b64encode(hashlib.pbkdf2_hmac('sha256', key, salt, 100000)))
            decrypted_content = kdf.decrypt(content.encode()).decode()
            return decrypted_content
        except Exception as e:
            logging.error(f"Failed to decrypt content: {e}")
            return content

    def compress_image(self, image):
        try:
            img_byte_arr = io.BytesIO()
            image.save(img_byte_arr, format='PNG', quality=self.config.getint('Image', 'compression_level', fallback=75))
            img_byte_arr = img_byte_arr.getvalue()
            return base64.b64encode(img_byte_arr).decode()
        except Exception as e:
            logging.error(f"Failed to compress image: {e}")
            return image

    def cleanup_old_clips(self):
        try:
            if self.config.getboolean('Cleanup', 'enable_auto_cleanup', fallback=False):
                interval = self.config.getint('Cleanup', 'cleanup_interval', fallback=7)
                cutoff_date = datetime.now() - timedelta(days=interval)
                self.cursor.execute("DELETE FROM clips WHERE timestamp < ?", (cutoff_date,))
                self.conn.commit()
            self.enforce_max_db_size()
        except sqlite3.Error as e:
            logging.error(f"Failed to clean up old clips: {e}")

    def enforce_max_db_size(self):
        try:
            db_size = os.path.getsize("clipboard.db")
            if db_size > self.max_db_size:
                overage = db_size - self.max_db_size
                logging.warning(f"Database size exceeded. Deleting oldest clips to reduce size by {overage} bytes.")

                self.cursor.execute("DELETE FROM clips WHERE id IN (SELECT id FROM clips ORDER BY timestamp ASC LIMIT 1)")
                self.conn.commit()
                self.enforce_max_db_size()
        except sqlite3.Error as e:
            logging.error(f"Failed to enforce max database size: {e}")