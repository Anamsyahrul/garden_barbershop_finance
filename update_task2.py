path = r'C:\Users\mayang\.gemini\antigravity-ide\brain\4e85e4bf-c579-4527-b171-0814535e3f94\task.md'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("[ ] Memperbarui app_page_widgets.dart (Micro-animations pada Cards/Tiles)", "[x] Memperbarui app_page_widgets.dart (Micro-animations pada Cards/Tiles)")
content = content.replace("[ ] Mengoptimalkan dashboard_screen.dart (Staggered animations)", "[x] Mengoptimalkan dashboard_screen.dart (Staggered animations)")
content = content.replace("[ ] Verifikasi hasil akhir (Walkthrough)", "[x] Verifikasi hasil akhir (Walkthrough)")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
