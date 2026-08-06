import docx
from docx.enum.text import WD_ALIGN_PARAGRAPH

doc_path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\docs\Proposal Skripsi v2_updated.docx'
doc = docx.Document(doc_path)

# State flags
in_implementasi = False

# We will collect paragraphs to delete, and find the insertion point
paragraphs_to_clear = []
insert_before_p = None

for p in doc.paragraphs:
    text = p.text.strip()
    if text.startswith('4.3 Implementasi'):
        in_implementasi = True
        
    if in_implementasi:
        if text.startswith('4.4 Pengujian'):
            in_implementasi = False
            insert_before_p = p
        else:
            paragraphs_to_clear.append(p)

# Clear old implementasi text
for p in paragraphs_to_clear:
    p.clear()

if insert_before_p:
    # Insert new Implementasi content
    p1 = insert_before_p.insert_paragraph_before('4.3 Implementasi')
    p1.runs[0].bold = True
    
    insert_before_p.insert_paragraph_before('Tahapan ini merupakan proses mengubah desain menjadi kode program menggunakan bahasa pemrograman Dart dengan framework Flutter, serta didukung oleh basis data NoSQL Firebase Firestore. Setiap modul dikembangkan sesuai dengan spesifikasi hasil analisis.')
    
    p2 = insert_before_p.insert_paragraph_before('4.3.1 Implementasi Database')
    p2.runs[0].bold = True
    
    insert_before_p.insert_paragraph_before('Implementasi repositori data dikonfigurasi melalui panel kontrol web Firebase Console. Berikut adalah hasil implementasi struktur database yang telah dibuat:')
    
    db_images = [
        'Gambar 4.14 Database Users',
        'Gambar 4.15 Database Capsters',
        'Gambar 4.16 Database Layanan',
        'Gambar 4.17 Database Buku Kas',
        'Gambar 4.18 Database Operasional',
        'Gambar 4.19 Database Pendapatan Harian'
    ]
    for img in db_images:
        p_img = insert_before_p.insert_paragraph_before(img)
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        
    p3 = insert_before_p.insert_paragraph_before('4.3.2 Implementasi Sistem')
    p3.runs[0].bold = True
    
    systems = [
        ('1. Implementasi Halaman Login', 'Halaman Login digunakan untuk masuk ke dalam sistem informasi Garden Barbershop, dengan mengisi username dan password pengguna dapat mengakses akun.', 'Gambar 4.20 Halaman Login'),
        ('2. Implementasi Halaman Dashboard', 'Halaman dashboard digunakan untuk menampilkan berbagai informasi ringkasan data sistem seperti total pendapatan, jumlah customer, dan grafik laporan.', 'Gambar 4.21 Halaman Dashboard'),
        ('3. Implementasi Halaman Kelola Data Capster', 'Halaman ini digunakan untuk mengisi informasi dan mengelola data capster yang bekerja.', 'Gambar 4.22 Halaman Kelola Data Capster'),
        ('4. Implementasi Halaman Kelola Data Layanan', 'Halaman layanan digunakan untuk mengelola data jenis jasa pangkas beserta harga yang ditawarkan.', 'Gambar 4.23 Halaman Kelola Data Layanan'),
        ('5. Implementasi Halaman Buku Kas Umum', 'Halaman ini digunakan untuk mencatat dan mengelola riwayat seluruh transaksi penerimaan dan pengeluaran kas.', 'Gambar 4.24 Halaman Buku Kas Umum'),
        ('6. Implementasi Halaman Operasional', 'Halaman ini digunakan untuk mencatat setiap biaya operasional pengeluaran usaha.', 'Gambar 4.25 Halaman Operasional'),
        ('7. Implementasi Halaman Pendapatan Harian', 'Halaman ini digunakan untuk mencatat setoran harian dari masing-masing capster setelah shift selesai.', 'Gambar 4.26 Halaman Pendapatan Harian'),
        ('8. Implementasi Halaman Laporan Bulanan', 'Halaman laporan digunakan untuk melihat rekapitulasi data pendapatan dan pengeluaran bersih selama satu bulan.', 'Gambar 4.27 Halaman Laporan Bulanan')
    ]
    
    for sys_title, sys_desc, sys_img in systems:
        pt = insert_before_p.insert_paragraph_before(sys_title)
        # Assuming we don't bold the sub-points to match example
        pd = insert_before_p.insert_paragraph_before(sys_desc)
        pi = insert_before_p.insert_paragraph_before(sys_img)
        pi.alignment = WD_ALIGN_PARAGRAPH.CENTER

doc.save(doc_path)
print('Implementasi section updated successfully.')
