import docx

path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\docs\Proposal Skripsi v2_final.docx'
doc = docx.Document(path)

# Find the section and replace texts
for p in doc.paragraphs:
    if "Implementasi repositori data dikonfigurasi melalui panel kontrol web Firebase Console. Berikut adalah hasil implementasi struktur database yang telah dibuat:" in p.text:
        p.text = "Implementasi basis data pada sistem ini dikonfigurasi melalui panel kontrol web Firebase Console menggunakan layanan Firestore (NoSQL). Berbeda dengan database relasional (SQL) seperti MySQL yang menggunakan format tabel kaku, data pada Firestore disimpan secara dinamis dalam bentuk Collections (Koleksi) dan Documents berformat JSON. Pendekatan ini memungkinkan sinkronisasi data secara real-time antar perangkat pada aplikasi seluler.\n\nBerikut adalah hasil implementasi struktur database (Collections) yang ada di dalam Firebase Console:"
    
    # Change "Database" to "Koleksi (Collection)" in the image captions for this section
    if "Gambar 4.14 Database Users" in p.text:
        p.text = p.text.replace("Database Users", "Koleksi (Collection) Users pada Firestore")
    if "Gambar 4.15 Database Capster" in p.text:
        p.text = p.text.replace("Database Capster", "Koleksi (Collection) Capster pada Firestore")
    if "Gambar 4.16 Database Layanan" in p.text:
        p.text = p.text.replace("Database Layanan", "Koleksi (Collection) Layanan pada Firestore")
    if "Gambar 4.17 Database Buku Kas Umum" in p.text:
        p.text = p.text.replace("Database Buku Kas Umum", "Koleksi (Collection) Buku Kas Umum pada Firestore")
    if "Gambar 4.18 Database Operasional" in p.text:
        p.text = p.text.replace("Database Operasional", "Koleksi (Collection) Operasional pada Firestore")
    if "Gambar 4.19 Database Pendapatan Harian" in p.text:
        p.text = p.text.replace("Database Pendapatan Harian", "Koleksi (Collection) Pendapatan Harian pada Firestore")

doc.save(path)
print("Teks Implementasi Database berhasil diperbarui!")
