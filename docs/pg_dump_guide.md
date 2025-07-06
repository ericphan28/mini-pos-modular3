# PostgreSQL pg_dump Guide for POS Mini Modular 3

## 📋 **Mục đích của file này:**
- Hướng dẫn backup database schema + data cho project
- Cung cấp file schema reference cho GitHub Copilot
- Standardize backup workflow cho development team
- Tích hợp với project development lifecycle

---

## 🔧 **1. Environment Setup**

### **Connection Settings:**
```powershell
# Supabase Database Credentials
$env:PGPASSWORD = "Ex8bngfrY9PVaHt5"
$SUPABASE_HOST = "aws-0-ap-southeast-1.pooler.supabase.com"
$SUPABASE_PORT = "6543"
$SUPABASE_USER = "postgres.oxtsowfvjchelqdxcbhs"
$SUPABASE_DB = "postgres"
```

### **Base Command Template:**
```powershell
pg_dump --host=$SUPABASE_HOST --port=$SUPABASE_PORT --username=$SUPABASE_USER --dbname=$SUPABASE_DB
```

---

## 📊 **2. Schema Export Commands**

### **A. Schema Only (cho Copilot reference):**
```powershell
# Export schema structure only (functions, tables, types)
$env:PGPASSWORD = "Ex8bngfrY9PVaHt5"
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema=auth --schema-only --no-owner --no-privileges --file=docs/schema/database_schema_reference.sql

# Chỉ export tables và functions (không có data)
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema-only --no-owner --no-privileges --file=docs/schema/public_schema_only.sql
```

### **B. Tables Structure Only:**
```powershell
# Export table definitions only (useful for new environments)
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema=auth --table=public.pos_mini_modular3_* --table=auth.users --schema-only --no-owner --no-privileges --file=docs/schema/tables_structure.sql
```

---

## 💾 **3. Data Export Commands**

### **A. Full Backup (Schema + Data) - Production Ready:**
```powershell
# Complete backup with schema and data (pg_dump format)
$env:PGPASSWORD = "Ex8bngfrY9PVaHt5"
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema=auth --table=public.pos_mini_modular3_* --table=auth.users --no-owner --no-privileges --file=backups/full_backup_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").sql

# Alternative: Custom format (smaller, faster)
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema=auth --table=public.pos_mini_modular3_* --table=auth.users --format=custom --no-owner --no-privileges --file=backups/full_backup_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").dump
```

### **B. Data Only (cho data migration):**
```powershell
# Export data only với INSERT statements (Supabase SQL Editor compatible)
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema=auth --table=public.pos_mini_modular3_* --table=auth.users --data-only --inserts --no-owner --no-privileges --file=backups/data_only_inserts_$(Get-Date -Format "yyyy-MM-dd").sql

# Export data với COPY format (nhanh hơn, dùng với psql)
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema=auth --table=public.pos_mini_modular3_* --table=auth.users --data-only --no-owner --no-privileges --file=backups/data_only_copy_$(Get-Date -Format "yyyy-MM-dd").sql
```

### **C. Specific Tables Only:**
```powershell
# Export specific tables cho testing
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --table=public.pos_mini_modular3_businesses --table=public.pos_mini_modular3_user_profiles --table=auth.users --inserts --no-owner --no-privileges --file=backups/core_tables_$(Get-Date -Format "yyyy-MM-dd").sql
```

---

## 🔄 **4. Restore Commands**

### **A. Restore with psql:**
```powershell
# Restore from SQL file
$env:PGPASSWORD = "Ex8bngfrY9PVaHt5"
psql --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --file=backups/backup_file.sql

# Restore from custom format
pg_restore --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --no-owner --no-privileges backups/backup_file.dump
```

### **B. Restore via Supabase SQL Editor:**
```sql
-- Copy nội dung từ file .sql có --inserts flag
-- Paste vào Supabase Dashboard > SQL Editor > Run
-- Hoặc sử dụng API Export SQL feature (recommended)
```

---

## 🚀 **5. Automated Backup Scripts**

### **A. Daily Schema Backup cho Copilot:**
```powershell
# scripts/backup_schema_for_copilot.ps1
$env:PGPASSWORD = "Ex8bngfrY9PVaHt5"

# Schema backup cho Copilot reference
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema-only --no-owner --no-privileges --file=docs/schema/current_schema_$(Get-Date -Format "yyyy-MM-dd").sql

# Copy latest schema cho Copilot
Copy-Item "docs/schema/current_schema_$(Get-Date -Format "yyyy-MM-dd").sql" "docs/schema/latest_schema_reference.sql"

Write-Host "✅ Schema backup completed for Copilot reference"
```

### **B. Production Backup Script:**
```powershell
# scripts/production_backup.ps1
$BackupDir = "backups/production"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$env:PGPASSWORD = "Ex8bngfrY9PVaHt5"

# Create backup directory
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir
}

# Full backup
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema=auth --table=public.pos_mini_modular3_* --table=auth.users --format=custom --no-owner --no-privileges --file="$BackupDir/full_backup_$Timestamp.dump"

# Schema only backup
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema=auth --schema-only --no-owner --no-privileges --file="$BackupDir/schema_backup_$Timestamp.sql"

Write-Host "✅ Production backup completed: $Timestamp"
```

---

## 📁 **6. File Organization**

### **Directory Structure:**
```
project/
├── docs/
│   └── schema/
│       ├── latest_schema_reference.sql    # 👈 Copilot reference file
│       ├── database_schema_reference.sql  # Full schema với functions
│       ├── tables_structure.sql           # Chỉ table definitions
│       └── changelog.md                   # Schema change history
├── backups/
│   ├── production/                        # Production backups
│   ├── development/                       # Development snapshots
│   └── migration/                         # Migration data files
└── scripts/
    ├── backup_schema_for_copilot.ps1      # Auto schema backup
    ├── production_backup.ps1              # Production backup
    └── restore_development.ps1            # Development restore
```

---

## 🎯 **7. Best Practices cho Project**

### **A. Development Workflow:**
1. **Before major feature development:**
   ```powershell
   # Update schema reference cho Copilot
   ./scripts/backup_schema_for_copilot.ps1
   ```

2. **Before deployment:**
   ```powershell
   # Create production backup
   ./scripts/production_backup.ps1
   ```

3. **After schema changes:**
   ```powershell
   # Update Copilot reference
   pg_dump --schema-only --> docs/schema/latest_schema_reference.sql
   ```

### **B. Copilot Integration:**
- **File reference:** `docs/schema/latest_schema_reference.sql`
- **Purpose:** Copilot sẽ hiểu database structure khi generate code
- **Update frequency:** Sau mỗi schema change
- **Format:** Pure SQL với comments

### **C. CI/CD Integration:**
```yaml
# .github/workflows/backup.yml
name: Database Schema Backup
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  push:
    paths:
      - 'supabase/migrations/**'

jobs:
  backup-schema:
    runs-on: ubuntu-latest
    steps:
      - name: Backup Schema for Copilot
        run: |
          pg_dump --schema-only > docs/schema/latest_schema_reference.sql
          git add docs/schema/latest_schema_reference.sql
          git commit -m "Auto-update: Schema reference for Copilot"
```

---

## ⚡ **8. Quick Commands Reference**

### **Essential Commands:**
```powershell
# 1. Schema cho Copilot (daily)
pg_dump --schema-only --file=docs/schema/latest_schema_reference.sql

# 2. Full backup (weekly)
pg_dump --format=custom --file=backups/weekly_backup.dump

# 3. Data migration (as needed)
pg_dump --data-only --inserts --file=migration_data.sql

# 4. Restore (emergency)
psql --file=backup_file.sql
```

### **Troubleshooting:**
```powershell
# Test connection
pg_dump --host=... --username=... --dbname=... --schema-only --dry-run

# Verify backup
pg_restore --list backup_file.dump

# Check file size
Get-ChildItem backups/ | Sort-Object Length -Descending
```

---

## 📝 **9. Integration với Project Features**

### **A. Với API Export SQL Feature:**
```typescript
// components/backup/backup-manager.tsx
// Sử dụng API Export thay vì pg_dump cho Supabase SQL Editor compatibility
const exportSQL = async () => {
  const response = await fetch('/api/admin/backup/export-sql');
  // File này đã có format INSERT statements, sẵn sàng cho SQL Editor
};
```

### **B. Với Migration System:**
```sql
-- supabase/migrations/
-- Sử dụng schema reference để hiểu current state trước khi viết migration
-- File: docs/schema/latest_schema_reference.sql làm baseline
```

### **C. Với Development:**
```markdown
# Khi Copilot suggest code cho database operations:
1. Copilot sẽ reference docs/schema/latest_schema_reference.sql
2. Hiểu table structure, relationships, functions
3. Generate code phù hợp với schema hiện tại
4. Suggest proper RLS policies, function calls
```

---

## 🎉 **10. Kết luận**

### **Lợi ích cho Project:**
- ✅ **Copilot có context đầy đủ** về database schema
- ✅ **Backup strategy rõ ràng** cho production
- ✅ **Development workflow** chuẩn hoá
- ✅ **Schema versioning** với git history
- ✅ **Emergency recovery** procedures
- ✅ **Integration** với existing features

### **Next Steps:**
1. Run schema backup để tạo reference file cho Copilot
2. Setup automated scripts trong development workflow
3. Integrate với CI/CD pipeline
4. Train team về backup procedures

---

**File này giúp Copilot hiểu rõ database structure và đưa ra suggestions chính xác khi phát triển tính năng mới! 🚀**
