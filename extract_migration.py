import pandas as pd
import json
from datetime import datetime
import uuid
import sys

# Load Excel
file_path = r'c:\laragon\www\garden barbershop\Migrasi AGUSTUS 26.xlsx'
try:
    xls = pd.ExcelFile(file_path)
except Exception as e:
    print(f"Error loading Excel file: {e}")
    sys.exit(1)

# Parse Pendapatan Harian
df_pend = pd.read_excel(xls, sheet_name='PEND. HARIAN', header=None)

capsters = [
    {'name': 'MUHAMAD DIVA SYARRI', 'id': 'C001', 'col_offset': 1},
    {'name': 'UMAR FAUZI', 'id': 'C002', 'col_offset': 17},
    {'name': 'M. KHADIK', 'id': 'C003', 'col_offset': 33}
]

pendapatan_list = []

for c in capsters:
    offset = c['col_offset']
    # Data rows are from index 6 to 36 (approx 31 days)
    for i in range(6, 37):
        try:
            date_val = df_pend.iloc[i, offset + 1] # Tanggal
            if pd.isna(date_val):
                continue
                
            # Parse date safely
            if isinstance(date_val, datetime):
                date_str = date_val.strftime('%Y-%m-%d')
            else:
                try:
                    date_str = pd.to_datetime(date_val).strftime('%Y-%m-%d')
                except:
                    continue

            # Extract numeric fields
            def get_num(idx):
                val = df_pend.iloc[i, offset + idx - 1]
                if pd.isna(val) or val == '': return 0
                try: return int(val)
                except: return 0

            pendapatan = get_num(13) # Pendapatan
            if pendapatan <= 0:
                continue

            cs = get_num(14) # CS
            cu = get_num(15) # CU

            entry = {
                "idPendapatan": f"P{str(uuid.uuid4())[:8]}",
                "tanggal": f"{date_str}T00:00:00.000",
                "idCapster": c['id'],
                "namaCapster": c['name'],
                "jumlahLayanan": get_num(3) + get_num(4) + get_num(5) + get_num(6) + get_num(7) + get_num(8) + get_num(9) + get_num(10) + get_num(11) + get_num(12),
                "SN": get_num(3),
                "RC": get_num(4),
                "PC": get_num(5),
                "GC": get_num(6),
                "CJ": get_num(7),
                "KR": get_num(8),
                "CH": get_num(9),
                "HS": get_num(10),
                "PR": get_num(11),
                "KM": get_num(12),
                "pendapatan": pendapatan,
                "cs": cs,
                "cu": cu,
                "totalCustomer": cs + cu
            }
            pendapatan_list.append(entry)
        except Exception as e:
            print(f"Error on row {i} for {c['name']}: {e}")

# Parse Operasional from BKU
df_bku = pd.read_excel(xls, sheet_name='BKU, LB, & PG', header=None)
operasional_list = []

for i in range(7, df_bku.shape[0]):
    try:
        uraian = df_bku.iloc[i, 3]
        akun = df_bku.iloc[i, 4]
        pengeluaran = df_bku.iloc[i, 6]
        
        if pd.isna(pengeluaran) or pd.isna(uraian) or pd.isna(akun):
            continue
            
        try:
            nominal = int(pengeluaran)
        except:
            continue
            
        if nominal <= 0:
            continue

        entry = {
            "idOperasional": f"O{str(uuid.uuid4())[:8]}",
            "bulan": "2026-08",
            "namaBiaya": str(uraian).strip(),
            "akun": str(akun).strip(),
            "nominal": nominal,
            "keterangan": "Hasil Migrasi Excel"
        }
        operasional_list.append(entry)
    except Exception as e:
        pass # Ignore empty or non-numeric rows

output = {
    "pendapatan": pendapatan_list,
    "operasional": operasional_list
}

with open('assets/migration_data.json', 'w') as f:
    json.dump(output, f, indent=2)

print(f"Migration JSON created in assets. Pendapatan: {len(pendapatan_list)}, Operasional: {len(operasional_list)}")
