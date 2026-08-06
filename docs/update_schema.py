import docx

doc_path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\docs\Proposal Skripsi v2.docx'
doc = docx.Document(doc_path)

replacements = {
    "5. Collection operasional_costs.": "5. Collection operasional.",
    "6. Collection daily_incomes.": "6. Collection pendapatan_harian.",
    "1. Collection 'users': Merupakan tempat penyimpanan entitas autentikasi sekunder pengguna. Terdiri dari field `idUser`, `username`, `password` (untuk login mandiri), `name`, `role`, dan tautan `idCapster` jika user tersebut bertindak sebagai capster.": "1. Collection 'users': Merupakan tempat penyimpanan entitas autentikasi sekunder pengguna. Terdiri dari field `id_user`, `username`, `password` (untuk login mandiri), `name`, `role`, `status`, dan tautan `id_capster` jika user tersebut bertindak sebagai capster.",
    "2. Collection 'capsters': Tempat bernaung data identitas primer para pekerja cukur. Terdiri dari `idCapster`, `namaCapster`, `noHp`, dan `status` keaktifan.": "2. Collection 'capsters': Tempat bernaung data identitas primer para pekerja cukur. Terdiri dari `id_capster`, `nama_capster`, `no_hp`, dan `status` keaktifan.",
    "3. Collection 'layanan': Tabel harga produk jasa. Menyimpan rincian seperti `idLayanan`, `kodeLayanan`, `namaLayanan`, nilai `harga`, dan grup `kategori`.": "3. Collection 'layanan': Tabel harga produk jasa. Menyimpan rincian seperti `id_layanan`, `kode_layanan`, `nama_layanan`, nilai `harga`, grup `kategori`, dan `status`.",
    "4. Collection 'buku_kas': Buku besar yang melacak masuk dan keluarnya seluruh kas. Terdapat `idKas`, `tanggal`, `uraian` transaksi, nilai `penerimaan` / `pengeluaran`, dan `saldo` mutasi akhir.": "4. Collection 'buku_kas': Buku besar yang melacak masuk dan keluarnya seluruh kas. Terdapat `id_kas`, `id_user`, `tanggal`, `uraian` transaksi, `akun`, nilai `penerimaan` / `pengeluaran`, `saldo` mutasi akhir, dan `keterangan`.",
    "5. Collection 'operasional_costs': Gudang record khusus biaya operasional bulanan, seperti bayar listrik atau sewa. Mencatat rentang `bulan`, `namaBiaya`, serta `nominal` pengeluaran.": "5. Collection 'operasional': Gudang record khusus biaya operasional bulanan, seperti bayar listrik atau sewa. Mencatat `id_operasional`, `id_user`, rentang `bulan`, `nama_biaya`, `akun`, `nominal` pengeluaran, dan `keterangan`.",
    "6. Collection 'daily_incomes': Penyimpanan utama setoran harian. Memuat penanda unik `idPendapatan`, `tanggal`, mengikat `idCapster` (Foreign Key), mencatat kinerja (seperti layanan `cs`, `cu`, total tamu), serta jumlah `pendapatan` aktual uang tunai.": "6. Collection 'pendapatan_harian': Penyimpanan utama setoran harian. Memuat penanda unik `id_pendapatan`, `id_user`, `tanggal`, mengikat `id_capster` (Foreign Key), `nama_capster`, mencatat kinerja (seperti layanan `cs`, `cu`, `total_customer`), serta jumlah `pendapatan` aktual uang tunai."
}

updated_count = 0
for p in doc.paragraphs:
    original_text = p.text.strip()
    if original_text in replacements:
        p.text = replacements[original_text]
        updated_count += 1

if updated_count > 0:
    doc.save(doc_path)
    print(f"Successfully updated {updated_count} paragraphs in the document.")
else:
    print("No matching paragraphs found. Check if the text matches exactly.")
