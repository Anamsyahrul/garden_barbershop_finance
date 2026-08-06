import docx
import shutil

filepath = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\docs\Proposal Skripsi v2.docx'
backup_path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\docs\Proposal Skripsi v2_backup.docx'
shutil.copy(filepath, backup_path)

doc = docx.Document(filepath)

in_bab_4 = False
for p in doc.paragraphs:
    text = p.text.strip()
    if "BAB IV" in text:
        in_bab_4 = True
        
    if "BAB V" in text:
        break
        
    if not in_bab_4:
        continue
        
    if "HASIL DAN PEMBAHASAN" in text and p.text.strip() == "HASIL DAN PEMBAHASAN":
        p.text = "PEMBAHASAN DAN HASIL"
    elif "Bab ini akan menguraikan secara mendalam mengenai" in text:
        p.text = "Bab ini akan menjelaskan tahapan pengembangan sebuah aplikasi Android pengelolaan pendapatan dan pembagian hasil capster pada Garden Barbershop berbasis Firebase dengan metode pengembangan sistem yang digunakan yaitu metode waterfall. Berikut adalah implementasi Metode waterfall:"
    
    # 4.1
    elif "4.1   Fase Inception" in text or text == "4.1 Fase Inception":
        p.text = "4.1 Analisis Kebutuhan"
    elif "4.1.1  Business Modelling Workflow" in text:
        p.text = "4.1.1 Kebutuhan Fungsional"
    elif "Alur kerja business modelling ini bertujuan" in text:
        p.text = "Kebutuhan fungsional merupakan kebutuhan yang menjelaskan proses atau layanan yang harus disediakan oleh sistem agar dapat berjalan sesuai dengan tujuan yang diharapkan. Adapun kebutuhan fungsional pada aplikasi Garden Barbershop Finance adalah sebagai berikut:"
    elif text.startswith("a. Identifikasi Masalah"):
        p.text = "Identifikasi Masalah"
    elif text.startswith("b. Identifikasi Sistem Berjalan"):
        p.text = "Identifikasi Sistem Berjalan"
    
    elif "4.1.2  Requirement Workflow" in text:
        p.text = "4.1.2 Kebutuhan Non-Fungsional"
    elif "Setelah mengidentifikasi masalah dari sistem berjalan" in text:
        p.text = "Kebutuhan Non-Fungsional dilakukan untuk mengetahui spesifikasi kebutuhan untuk sistem. Spesifikasi kebutuhan melibatkan analisis perangkat keras (hardware) dan perangkat lunak (software)."
    elif text.startswith("a. Analisis Kebutuhan Sistem"):
        p.text = "Analisis Kebutuhan Sistem"
    elif text.startswith("b. Fitur Sistem"):
        p.text = "Fitur Sistem"
        
    # 4.2
    elif "4.2   Fase Elaboration" in text or text == "4.2 Fase Elaboration":
        p.text = "4.2 Desain Sistem"
    elif "4.2.1  Analysis And Design" in text:
        p.text = "Perancangan sistem mencakup arsitektur berbasis framework Flutter dan Firebase, perancangan basis data menggunakan Cloud Firestore, serta perancangan Unified Modeling Language (UML) seperti Use Case Diagram, Activity Diagram, dan Class Diagram untuk menggambarkan alur serta proses sistem yang akan dibangun. Selain itu, perancangan antarmuka menggunakan Flutter untuk menghasilkan tampilan yang responsif pada perangkat Android. Basis data yang dirancang meliputi penyimpanan koleksi dan dokumen semua fitur."
    elif "4.2.1.1 Use Case Diagram" in text:
        p.text = "4.2.1 Use Case Diagram"
    elif "4.2.1.2 Deskripsi Use Case" in text:
        p.text = "Deskripsi Use Case"
    elif "4.2.1.3 Activity Diagram" in text:
        p.text = "4.2.2 Activity Diagram"
    elif "4.2.1.4 Class Diagram" in text:
        p.text = "4.2.3 Class Diagram"
    elif "4.2.1.5 Entity Relationship Diagram" in text:
        p.text = "Entity Relationship Diagram"
    elif "4.2.1.6 Skema Basis Data" in text:
        p.text = "Skema Database"
    elif "4.2.1.7 Rancangan Tabel" in text:
        p.text = "Rancangan Tabel"
    elif "4.2.1.8 Rancangan User Interface" in text:
        p.text = "Rancangan User Interface"
        
    # 4.3
    elif "4.3 Fase Construction" in text:
        p.text = "4.3 Implementasi"
    elif "4.3.1 Implementation Workflow" in text:
        p.text = ""
    elif "4.3.1.1 Implementasi Database" in text:
        p.text = "4.3.1 Implementasi Database"
    elif "4.3.1.2 Implementasi Antarmuka" in text:
        p.text = "4.3.2 Implementasi Sistem"
        
    # 4.4
    elif "4.3.2 Test Workflow" in text:
        p.text = "4.4 Pengujian"
    elif "Pengujian sistem menggunakan Black Box Testing" in text:
        p.insert_paragraph_before("4.4.1 Black Box Testing", p.style)
    elif "4.4 Fase Transition" in text:
        p.text = ""
    elif "4.4.1 Deployment" in text:
        p.text = "Deployment"

doc.save(filepath)
print("Finished rewriting Proposal Skripsi v2.docx")
