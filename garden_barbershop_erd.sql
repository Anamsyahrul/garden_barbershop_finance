-- File ini adalah Schema SQL untuk Entity Relationship Diagram (ERD).
-- Format penamaan disesuaikan dengan standar Database (snake_case)
-- yang merepresentasikan collection (tabel) pada Firebase.

CREATE TABLE users (
    id_user VARCHAR(255) PRIMARY KEY,
    username VARCHAR(100),
    password VARCHAR(255),
    name VARCHAR(100),
    role VARCHAR(50), 
    status VARCHAR(50),
    id_capster VARCHAR(255) 
);

CREATE TABLE capster (
    id_capster VARCHAR(255) PRIMARY KEY,
    nama_capster VARCHAR(100),
    no_hp VARCHAR(20),
    status VARCHAR(50)
);

CREATE TABLE layanan (
    id_layanan VARCHAR(255) PRIMARY KEY,
    kode_layanan VARCHAR(50),
    nama_layanan VARCHAR(100),
    harga INT,
    kategori VARCHAR(50),
    status VARCHAR(50)
);

CREATE TABLE buku_kas_umum (
    id_kas VARCHAR(255) PRIMARY KEY,
    id_user VARCHAR(255),
    tanggal VARCHAR(50),
    uraian TEXT,
    akun VARCHAR(100),
    penerimaan INT,
    pengeluaran INT,
    saldo INT,
    keterangan TEXT
);

CREATE TABLE operasional (
    id_operasional VARCHAR(255) PRIMARY KEY,
    id_user VARCHAR(255),
    bulan VARCHAR(20), 
    nama_biaya VARCHAR(100),
    akun VARCHAR(100),
    nominal INT,
    keterangan TEXT
);

CREATE TABLE pendapatan_harian (
    id_pendapatan VARCHAR(255) PRIMARY KEY,
    id_user VARCHAR(255),
    id_capster VARCHAR(255),
    tanggal VARCHAR(50),
    nama_capster VARCHAR(100),
    pendapatan INT,
    cs INT,
    cu INT,
    total_customer INT
);

-- Relasi (Foreign Keys) ERD
-- Satu User mencatat banyak entri di Buku Kas, Operasional, dan Pendapatan Harian (1 to Many)
ALTER TABLE buku_kas_umum_umum ADD FOREIGN KEY (id_user) REFERENCES users (id_user);
ALTER TABLE operasional ADD FOREIGN KEY (id_user) REFERENCES users (id_user);
ALTER TABLE pendapatan_harian ADD FOREIGN KEY (id_user) REFERENCES users (id_user);

-- Satu Capster (Tukang Cukur) terhubung ke akun User dan menghasilkan banyak Pendapatan Harian
ALTER TABLE users ADD FOREIGN KEY (id_capster) REFERENCES capster (id_capster);
ALTER TABLE pendapatan_harian ADD FOREIGN KEY (id_capster) REFERENCES capster (id_capster);


CREATE TABLE laporan_bulanan (
    id_laporan VARCHAR(255) PRIMARY KEY,
    bulan VARCHAR(20),
    tahun VARCHAR(4),
    total_pendapatan INT,
    total_pengeluaran INT,
    laba_bersih INT
);

CREATE TABLE rekap_customer (
    id_rekap VARCHAR(255) PRIMARY KEY,
    id_capster VARCHAR(255),
    periode VARCHAR(50),
    total_cs INT,
    total_cu INT,
    total_keseluruhan INT,
    FOREIGN KEY (id_capster) REFERENCES capster(id_capster)
);
