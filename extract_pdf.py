import sys
try:
    from PyPDF2 import PdfReader
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pypdf2"])
    from PyPDF2 import PdfReader

reader = PdfReader(r'c:\laragon\www\garden barbershop\6 LAPORAN KEUANGAN GARDEN BARBERSHOP PERIODE JULI 2026.pdf')
text = ""
for i, page in enumerate(reader.pages):
    text += f"\n--- PAGE {i+1} ---\n"
    text += page.extract_text()

print(text)
