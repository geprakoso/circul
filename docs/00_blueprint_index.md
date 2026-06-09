# Circul — Blueprint Documentation

> **Versi**: 2.0  
> **Terakhir diupdate**: 2026-06-09  
> **Untuk**: Tim development Circul  

---

## Daftar Dokumen

| # | Dokumen | Isi | Status |
|---|---|---|---|
| 01 | [Architecture](01_architecture.md) | Layer diagram, dependency rules, design decisions | ✅ |
| 02 | [App Flow & Navigation](02_app_flow.md) | User flow, screen map, navigation rules, route table | ✅ |
| 03 | [Project Structure](03_project_structure.md) | Folder structure, naming conventions, file ownership | ✅ |
| 04 | [Data Model & Database](04_data_model.md) | SQLite schema, Supabase tables, entity definitions | ✅ |
| 05 | [Feature Guide](05_feature_guide.md) | Per-feature documentation, responsibilities, dependencies | ✅ |
| 06 | [Auth & Security](06_auth_security.md) | Auth flow, Supabase config, RLS policies, email verification | ✅ |
| 07 | [Contributing & Conventions](07_contributing.md) | Coding standards, PR checklist, how to add a new feature | ✅ |

---

## Cara Pakai

- **Developer baru?** Baca `01_architecture.md` → `03_project_structure.md` → `07_contributing.md`
- **Mau tambah fitur?** Baca `05_feature_guide.md` → `07_contributing.md`
- **Mau debug data?** Baca `04_data_model.md`
- **Mau ubah auth?** Baca `06_auth_security.md`
- **Mau paham alur user?** Baca `02_app_flow.md`

---

## Konvensi Dokumen

- Semua path relatif terhadap `lib/`
- Kode contoh diambil langsung dari codebase aktual
- Dokumen diupdate bersamaan dengan perubahan kode besar
- Setiap dokumen self-contained — bisa dibaca tanpa baca yang lain
