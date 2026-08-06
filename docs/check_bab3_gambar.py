import docx

doc_path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\docs\Proposal Skripsi v2_updated.docx'
doc = docx.Document(doc_path)

for p in doc.paragraphs:
    text = p.text.strip()
    if 'Gambar 3.' in text or 'Gambar 3' in text:
        print(text)
