path = r'C:\Users\mayang\.gemini\antigravity-ide\brain\4e85e4bf-c579-4527-b171-0814535e3f94\task.md'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("[ ] Memperbarui app_theme.dart (Plus Jakarta Sans, Shadows, Colors)", "[x] Memperbarui app_theme.dart (Plus Jakarta Sans, Shadows, Colors)")
content = content.replace("[ ] Menjalankan flutter pub get", "[x] Menjalankan flutter pub get")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
