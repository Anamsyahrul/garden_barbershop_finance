-- File ini adalah MOCK/PSEUDO SQL Schema. 
-- Proyek ini menggunakan Firebase (NoSQL), namun file SQL ini disediakan
-- agar bisa digunakan pada tools generator ERD seperti dbdiagram.io, MySQL Workbench, dll.

CREATE TABLE UserModel (
    idUser VARCHAR(255) PRIMARY KEY,
    username VARCHAR(100),
    password VARCHAR(255),
    name VARCHAR(100),
    role VARCHAR(50), 
    status VARCHAR(50),
    idCapster VARCHAR(255) 
);

CREATE TABLE CapsterModel (
    idCapster VARCHAR(255) PRIMARY KEY,
    namaCapster VARCHAR(100),
    noHp VARCHAR(20),
    status VARCHAR(50)
);

CREATE TABLE LayananModel (
    idLayanan VARCHAR(255) PRIMARY KEY,
    kodeLayanan VARCHAR(50),
    namaLayanan VARCHAR(100),
    harga INT,
    kategori VARCHAR(50),
    status VARCHAR(50)
);

CREATE TABLE BukuKasModel (
    idKas VARCHAR(255) PRIMARY KEY,
    tanggal VARCHAR(50),
    uraian TEXT,
    akun VARCHAR(100),
    penerimaan INT,
    pengeluaran INT,
    saldo INT,
    keterangan TEXT,
    idUser VARCHAR(255)
);

CREATE TABLE OperasionalModel (
    idOperasional VARCHAR(255) PRIMARY KEY,
    bulan VARCHAR(20), 
    namaBiaya VARCHAR(100),
    akun VARCHAR(100),
    nominal INT,
    keterangan TEXT,
    idUser VARCHAR(255)
);

CREATE TABLE PendapatanHarianModel (
    idPendapatan VARCHAR(255) PRIMARY KEY,
    tanggal VARCHAR(50),
    idCapster VARCHAR(255),
    namaCapster VARCHAR(100),
    pendapatan INT,
    cs INT,
    cu INT,
    totalCustomer INT,
    idUser VARCHAR(255)
);

CREATE TABLE LaporanBulananModel (
    idLaporan VARCHAR(255) PRIMARY KEY,
    bulan VARCHAR(50),
    idCapster VARCHAR(255),
    namaCapster VARCHAR(100),
    pendapatanKotor INT,
    totalOperasional INT,
    operasionalPerCapster INT,
    pendapatanBersih INT,
    bagianCapster INT,
    bagianPondok INT
);

-- Relasi (Foreign Keys) sesuai dengan garis di Class Diagram
-- UserModel "mencatat" BukuKasModel, OperasionalModel, PendapatanHarianModel
ALTER TABLE BukuKasModel ADD FOREIGN KEY (idUser) REFERENCES UserModel (idUser);
ALTER TABLE OperasionalModel ADD FOREIGN KEY (idUser) REFERENCES UserModel (idUser);
ALTER TABLE PendapatanHarianModel ADD FOREIGN KEY (idUser) REFERENCES UserModel (idUser);

-- CapsterModel "menghasilkan" PendapatanHarianModel, "memiliki" LaporanBulananModel
ALTER TABLE PendapatanHarianModel ADD FOREIGN KEY (idCapster) REFERENCES CapsterModel (idCapster);
ALTER TABLE LaporanBulananModel ADD FOREIGN KEY (idCapster) REFERENCES CapsterModel (idCapster);
