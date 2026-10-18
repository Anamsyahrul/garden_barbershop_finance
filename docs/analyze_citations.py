import docx
import re

print("Loading document...")
doc = docx.Document("Skripsi_bener_revisi_final.docx")

apa_pattern = re.compile(r'\([A-Za-z\s]+(?:et al\.?)?,?\s*\d{4}\)')
ieee_pattern = re.compile(r'\[\d+(?:(?:,|-)\d+)*\]')

apa_citations = []
ieee_citations = []

daftar_pustaka_found = False
bibliography_items = []

for p in doc.paragraphs:
    text = p.text.strip()
    
    if text.lower() in ["daftar pustaka", "referensi", "bibliography"]:
        daftar_pustaka_found = True
        continue
        
    if daftar_pustaka_found:
        if text:
            bibliography_items.append(text)
    else:
        # Find citations in text
        for match in apa_pattern.findall(text):
            apa_citations.append(match)
        for match in ieee_pattern.findall(text):
            ieee_citations.append(match)

print(f"Found {len(apa_citations)} potential APA citations.")
if apa_citations:
    print("Sample APA:", apa_citations[:5])
    
print(f"Found {len(ieee_citations)} potential IEEE citations.")
if ieee_citations:
    print("Sample IEEE:", ieee_citations[:5])
    
print(f"Daftar Pustaka found: {daftar_pustaka_found}")
print(f"Bibliography items count: {len(bibliography_items)}")
if bibliography_items:
    print("Sample items:")
    for item in bibliography_items[:3]:
        print("-", item[:100])
