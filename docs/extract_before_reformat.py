import docx
doc_path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\docs\Proposal Skripsi v2_updated.docx'
doc = docx.Document(doc_path)
found = False
for p in doc.paragraphs:
    if '4.2.5' in p.text or 'Entity Relationship Diagram' in p.text:
        found = True
    if 'Rancangan User Interface' in p.text:
        break
    if found and p.text.strip():
        print(p.text)
