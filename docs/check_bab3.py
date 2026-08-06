import docx

doc_path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\docs\Proposal Skripsi v2_updated.docx'
doc = docx.Document(doc_path)

in_bab_3 = False
for p in doc.paragraphs:
    text = p.text.strip()
    if 'BAB III' in text or 'BAB 3' in text:
        in_bab_3 = True
    if 'BAB IV' in text or 'BAB 4' in text:
        break
    
    if in_bab_3 and ('Gambar' in text or 'Rancangan' in text or 'Antarmuka' in text or 'Mockup' in text):
        print(text)
