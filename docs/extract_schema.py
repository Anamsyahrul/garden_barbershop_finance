import docx

doc_path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\docs\Proposal Skripsi v2.docx'
doc = docx.Document(doc_path)
found = False
for p in doc.paragraphs:
    if 'Skema Database' in p.text or 'Rancangan Tabel' in p.text:
        found = True
    if '4.3 Implementasi' in p.text:
        break
    if found and p.text.strip():
        print(p.text)
