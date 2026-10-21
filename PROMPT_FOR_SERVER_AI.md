# PANDUAN INTEGRASI & KONTRAK SERVER: MODUL TRANSPORTER (3 AREA PABRIK)

Dokumen ini ditujukan sebagai **panduan & prompt instruksi** untuk developer maupun AI backend yang mengelola `gs-visit-main-server` agar selaras dan konsisten 100% dengan aplikasi desktop **Garudashield Transporter** (`GS-VISIT-TRANSPORT`).

---

## 1. Latar Belakang & Segmentasi 3 Area Pabrik
Pabrik Garudafood (khususnya cabang Sumedang - `SMD`) memiliki **3 area fisik** utama yang dilewati armada transporter:
1. **`GARUDAFOOD` / `GF`**
   - **Tabel `areas`**: `code: "GF"`, `name: "Garudafood"`, `sort_order: 0`
   - Plant produksi utama dan penerimaan bahan baku utama.
2. **`DC` (Distribution Center)**
   - **Tabel `areas`**: `code: "DC"`, `name: "DC"`, `sort_order: 1`
   - Gudang logistik & pusat distribusi finished goods / muatan produk.
3. **`MBR`**
   - **Tabel `areas`**: `code: "MBR"`, `name: "MBR"`, `sort_order: 2`
   - Area operasional logistik MBR.

> **PENTING**: Nomor antrean (`queue_number`) transporter wajib terisolasi **per area, per cabang, per tanggal kunjungan (`visit_date`)**. Truk di DC memiliki urutan antrean #1, #2, #3 sendiri terpisah dari antrean di GF maupun MBR.

---

## 2. Struktur Database & Model SQLAlchemy

### 2.1. Tabel `areas` (`app/models.py`)
```python
class Area(Base):
    __tablename__ = "areas"
    __table_args__ = (UniqueConstraint("branch_id", "code", name="uq_area_branch_code"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    branch_id: Mapped[int] = mapped_column(ForeignKey("branches.id"), index=True)
    code: Mapped[str] = mapped_column(String(20))       # "GF" | "DC" | "MBR"
    name: Mapped[str] = mapped_column(String(150))      # "Garudafood" | "DC" | "MBR"
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
```

### 2.2. Relasi di `visit_plans` (`app/models.py`)
```python
class VisitPlan(Base):
    __tablename__ = "visit_plans"
    __table_args__ = (
        Index("idx_visit_plans_area_queue", "branch_id", "area_id", "visit_date", "queue_number"),
    )
    ...
    branch_id: Mapped[int] = mapped_column(ForeignKey("branches.id"))
    area_id: Mapped[int | None] = mapped_column(ForeignKey("areas.id"), nullable=True, default=None)
    visitor_type: Mapped[str] = mapped_column(String(20), default="transporter")
    visit_date: Mapped[datetime.date | None] = mapped_column(Date, nullable=True, default=None)
    vehicle_plate: Mapped[str] = mapped_column(String(20), default="")
    vehicle_type: Mapped[str] = mapped_column(String(50), default="")
    load_type: Mapped[str] = mapped_column(String(20), default="bongkar")  # "bongkar" | "muat"
    queue_number: Mapped[int | None] = mapped_column(Integer, nullable=True, default=None)
    status: Mapped[str] = mapped_column(String(30), default="planned") # "planned" | "checked_in" | "checked_out"
    area: Mapped["Area"] = relationship()
```

---

## 3. Logika Nomor Antrean Transporter Per-Area
Pada saat armada melakukan check-in (baik melalui kamera pengenal wajah maupun input konfirmasi gerbang), nomor antrean dihitung dengan rumus:

```python
# app/services/visit_service.py & app/routers/visit_plans.py:
if (plan.visitor_type == "transporter" or plan.load_type) and plan.queue_number is None:
    today = plan.visit_date or active_guest_service.local_today()

    query_max = (
        db.query(func.max(VisitPlan.queue_number))
        .filter(
            VisitPlan.branch_id == plan.branch_id,
            VisitPlan.visit_date == today,
            VisitPlan.queue_number.isnot(None),
        )
    )
    if plan.area_id is not None:
        query_max = query_max.filter(VisitPlan.area_id == plan.area_id)
    else:
        query_max = query_max.filter(VisitPlan.area_id.is_(None))

    max_q = query_max.scalar() or 0
    plan.queue_number = max_q + 1
```

---

## 4. Spesifikasi Kontrak API

### 4.1. `GET /api/areas?branch_id={id}`
Mengembalikan daftar area aktif di cabang yang bersangkutan.
**Response JSON**:
```json
{
  "areas": [
    {"id": 1, "branch_id": 1, "code": "GF", "name": "Garudafood", "active": true, "sort_order": 0},
    {"id": 2, "branch_id": 1, "code": "DC", "name": "DC", "active": true, "sort_order": 1},
    {"id": 3, "branch_id": 1, "code": "MBR", "name": "MBR", "active": true, "sort_order": 2}
  ]
}
```

### 4.2. `GET /api/active-guests/today?branch_id={id}&area_id={optional}`
Papan armada real-time yang sedang berada di area.
Mendukung parameter query opsional `area_id` untuk menyaring armada langsung di server:
- Jika `area_id` tidak disertakan, kembalikan semua armada aktif di cabang tersebut.
- Setiap objek armada dalam `guests` WAJIB menyertakan:
  - `area_id`: `int | null`
  - `area_name`: `string` ("Garudafood", "DC", "MBR")
  - `area_code`: `string` ("GF", "DC", "MBR")
  - `queue_number`: `int | null` (nomor urut antrean di area tersebut)
  - `load_type`: `"bongkar"` | `"muat"`
  - `vehicle_plate`: `string`
  - `company`: `string` (nama ekspedisi)

### 4.3. `POST /api/transporter/confirm-checkin`
Digunakan oleh aplikasi desktop untuk mencatat armada masuk di gerbang satpam:
**Request JSON Payload**:
```json
{
  "driver_name": "Budi Santoso",
  "plate_number": "B 9123 GF",
  "transporter_company": "PT Sumber Logistik",
  "do_number": "SJ-2026/06/1029",
  "load_type": "bongkar",
  "load_description": "8 Pallet Kacang Garuda, total 4.2 Ton",
  "notes": "Kondisi terpal aman",
  "officer_name": "satpam.sumedang@garudafood.co.id",
  "officer_signature_b64": "<base64_png>",
  "branch_id": 1,
  "area_id": 2,
  "area_code": "DC",
  "area_name": "DC"
}
```
**Perilaku Server**:
1. Temukan atau buat profil `Visitor` berjenis `transporter`.
2. Temukan atau buat `VisitPlan` untuk tanggal hari ini (`visit_date = today`).
3. Set status ke `"checked_in"`, simpan `area_id` tujuan.
4. Terbitkan nomor antrean per area (`plan.queue_number`).
5. Simpan baris barang muatan ke tabel `transporter_loads`.
6. Simpan tanda tangan digital petugas satpam ke folder signatures.
7. Return HTTP 200 dengan JSON:
```json
{
  "success": true,
  "message": "Konfirmasi masuk B 9123 GF berhasil. Antrean #1 (DC)",
  "plan_id": 105,
  "queue_number": 1,
  "area_name": "DC"
}
```

### 4.4. `POST /api/transporter/confirm-checkout`
Digunakan untuk mencatat armada keluar dari area:
**Request JSON Payload**:
```json
{
  "plan_id": 105,
  "visitor_id": 50,
  "officer_name": "satpam.sumedang@garudafood.co.id",
  "officer_signature_b64": "<base64_png>",
  "notes": "Segel dan dokumen lengkap",
  "verification": {
    "docs_checked": true,
    "load_checked": true,
    "seal_checked": true
  }
}
```
**Perilaku Server**:
1. Update `plan.status = "checked_out"`.
2. Update record kunjungan `Visit.checkout_time = utcnow`.
3. Simpan tanda tangan digital petugas satpam keluar.
4. Return HTTP 200:
```json
{
  "success": true,
  "message": "Armada B 9123 GF berhasil check-out."
}
```

---

## 5. Ringkasan Keselarasan Frontend & Backend
- **Frontend** (`GS-VISIT-TRANSPORT`):
  - Telah mengelompokkan armada menjadi 3 kartu tab: `GARUDAFOOD` (GF), `DC`, dan `MBR`.
  - Papan Penuh Armada, Dashboard Real-time, Konfirmasi Masuk, dan Konfirmasi Keluar telah diselaraskan dengan enum `PlantAreaCategory`.
  - Menu khusus **"Akun Sopir"** (`TransporterDriversPage`) telah dibuat untuk memantau sopir terdaftar, verifikasi masa aktif SIM, dan toggle status aktif/non-aktif akun.
- **Backend** (`gs-visit-main-server`):
  - Endpoint `GET /api/active-guests/today` mendukung filter `area_id`.
  - Endpoint `POST /api/transporter/confirm-checkin` & `confirm-checkout` sudah terhubung pada `transporter_router`.
  - Penomoran antrean dipartisi per `(branch_id, area_id, visit_date)`.
  - Endpoint `GET /api/transporter/drivers` & `PATCH /api/transporter/drivers/{id}/toggle-active` aktif dan terdaftar di `board_token_service.SCOPE`.
  - Check-in (wajah maupun konfirmasi manual) otomatis menolak sopir berstatus `is_active = false`.

---

## 6. Manajemen Akun Sopir & Status Aktif/Nonaktif (`is_active`)

### 6.1. Kolom Database & Migrasi
Pada tabel `visitors`, field `is_active` (`Boolean`, default `1` / `True`) menentukan apakah sopir diizinkan masuk atau diblokir:
```python
class Visitor(Base):
    ...
    visitor_type: Mapped[str] = mapped_column(String(20), default="tamu", index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
```
Migrasi di `app/migrations.py`:
```python
("visitors", "is_active", "ALTER TABLE visitors ADD COLUMN is_active BOOLEAN DEFAULT 1"),
```

### 6.2. `GET /api/transporter/drivers`
Mengambil daftar akun sopir transporter yang terdaftar di sistem.
- **Query Params**:
  - `search` (opsional): cari berdasarkan nama sopir, perusahaan ekspedisi, no SIM, atau ID sopir.
  - `is_active` (opsional): filter boolean `true` atau `false`.
  - `limit`: default 100.
  - `offset`: default 0.
- **Response JSON**:
```json
{
  "success": true,
  "total": 1,
  "drivers": [
    {
      "id": 15,
      "visitor_code": "V-0015",
      "full_name": "Budi Santoso",
      "company": "PT Sumber Rejeki Express",
      "phone": "081234567890",
      "sim_number": "SIM-12345678",
      "sim_expires_at": "2027-05-20",
      "is_active": true,
      "created_at": "2026-10-21T08:00:00Z",
      "photo_url": "/photos/v_0015.jpg",
      "total_trips": 14,
      "last_visit": "2026-10-21"
    }
  ]
}
```

### 6.3. `PATCH /api/transporter/drivers/{visitor_id}/toggle-active`
Mengubah status keaktifan akun sopir (aktif atau nonaktif).
- **Request JSON Payload**:
```json
{
  "is_active": false,
  "reason": "SIM kedaluwarsa / pelanggaran SOP keselamatan"
}
```
- **Response JSON**:
```json
{
  "success": true,
  "message": "Akun sopir Budi Santoso berhasil dinonaktifkan.",
  "visitor_id": 15,
  "is_active": false
}
```

### 6.4. Aturan Validasi Check-In untuk Sopir Nonaktif
Bila akun sopir berstatus `is_active == False`:
- **`POST /api/transporter/confirm-checkin`**: Mengembalikan HTTP 403 Forbidden:
  ```json
  {
    "success": false,
    "message": "Akun sopir 'Budi Santoso' berstatus NONAKTIF / dinonaktifkan oleh admin. Masuk ditolak."
  }
  ```
- **`POST /api/visits/checkin`** (Face ID gate): Mengembalikan `VisitOutcome(ok=False, message="Akun Budi Santoso berstatus NONAKTIF...")`.

