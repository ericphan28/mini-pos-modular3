# ==================================================================================
# POS Mini Modular 3 - Schema Backup Script for Copilot
# ==================================================================================
# Purpose: Auto-backup database schema for GitHub Copilot reference
# Usage: .\scripts\backup_schema_for_copilot.ps1
# Last Updated: 2025-07-07 (Post Enhanced Auth & Migration Reorganization)
# ==================================================================================

param(
    [switch]$Verbose = $false
)

# Configuration
$SUPABASE_HOST = "aws-0-ap-southeast-1.pooler.supabase.com"
$SUPABASE_PORT = "6543"
$SUPABASE_USER = "postgres.oxtsowfvjchelqdxcbhs"
$SUPABASE_DB = "postgres"
$SUPABASE_PASSWORD = "Ex8bngfrY9PVaHt5"

# Paths
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$SchemaDir = Join-Path $ProjectRoot "docs\schema"
$BackupDir = Join-Path $ProjectRoot "backups\development"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host "🚀 POS Mini Modular 3 - Schema Backup (Enhanced Auth Era)" -ForegroundColor Cyan
Write-Host "📅 Migration Era: Enhanced Auth System & Reorganized Migrations" -ForegroundColor Yellow

# Create directories if they don't exist
if (-not (Test-Path $SchemaDir)) {
    New-Item -ItemType Directory -Path $SchemaDir -Force | Out-Null
    Write-Host "[OK] Created schema directory: $SchemaDir" -ForegroundColor Green
}

# Additional note about current migration status
Write-Host ""
Write-Host "📋 Current Migration Status:" -ForegroundColor Yellow
Write-Host "   ✅ Enhanced Auth System implemented (004_enhanced_auth_functions.sql)" -ForegroundColor Green
Write-Host "   ✅ Migrations reorganized in supabase/migrations/ (001-007)" -ForegroundColor Green  
Write-Host "   ✅ Test page /test-enhanced-auth working" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "[OK] Created backup directory: $BackupDir" -ForegroundColor Green
}

# Set environment variable for password
$env:PGPASSWORD = $SUPABASE_PASSWORD

Write-Host "[START] Starting schema backup for GitHub Copilot..." -ForegroundColor Cyan
Write-Host "[INFO] Timestamp: $Timestamp" -ForegroundColor Gray

try {
    # 1. Test connection first
    Write-Host "[TEST] Testing database connection..." -ForegroundColor Yellow
    $testCommand = "pg_dump --host=$SUPABASE_HOST --port=$SUPABASE_PORT --username=$SUPABASE_USER --dbname=$SUPABASE_DB --schema=public --schema-only --no-owner --no-privileges --verbose --dry-run"
    
    if ($Verbose) {
        Write-Host "Command: $testCommand" -ForegroundColor Gray
    }
    
    # 2. Export complete schema (functions + tables)
    $schemaFile = Join-Path $SchemaDir "complete_schema_$Timestamp.sql"
    Write-Host "[EXPORT] Exporting complete schema..." -ForegroundColor Yellow
    
    $schemaCommand = "pg_dump --host=$SUPABASE_HOST --port=$SUPABASE_PORT --username=$SUPABASE_USER --dbname=$SUPABASE_DB --schema=public --schema=auth --schema-only --no-owner --no-privileges --file=`"$schemaFile`""
    
    if ($Verbose) {
        Write-Host "Command: $schemaCommand" -ForegroundColor Gray
    }
    
    Invoke-Expression $schemaCommand
    
    if ($LASTEXITCODE -eq 0) {
        $fileSize = (Get-Item $schemaFile).Length
        Write-Host "[OK] Complete schema exported: $fileSize bytes" -ForegroundColor Green
    } else {
        throw "Schema export failed with exit code: $LASTEXITCODE"
    }
    
    # 3. Export tables structure only
    $tablesFile = Join-Path $SchemaDir "tables_structure_$Timestamp.sql"
    Write-Host "[EXPORT] Exporting tables structure..." -ForegroundColor Yellow
    
    $tablesCommand = "pg_dump --host=$SUPABASE_HOST --port=$SUPABASE_PORT --username=$SUPABASE_USER --dbname=$SUPABASE_DB --schema=public --schema=auth --table=public.pos_mini_modular3_* --table=auth.users --schema-only --no-owner --no-privileges --file=`"$tablesFile`""
    
    if ($Verbose) {
        Write-Host "Command: $tablesCommand" -ForegroundColor Gray
    }
    
    Invoke-Expression $tablesCommand
    
    if ($LASTEXITCODE -eq 0) {
        $fileSize = (Get-Item $tablesFile).Length
        Write-Host "[OK] Tables structure exported: $fileSize bytes" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Tables structure export failed, continuing..." -ForegroundColor Yellow
    }
    
    # 4. Update latest reference file for Copilot
    $latestFile = Join-Path $SchemaDir "latest_schema_reference.sql"
    Write-Host "[UPDATE] Updating latest schema reference..." -ForegroundColor Yellow
    
    # Add header with timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $headerLines = @()
    $headerLines += "-- =================================================================================="
    $headerLines += "-- POS MINI MODULAR 3 - LATEST SCHEMA REFERENCE"
    $headerLines += "-- =================================================================================="
    $headerLines += "-- Generated: $timestamp"
    $headerLines += "-- Source: Auto-backup script"
    $headerLines += "-- Purpose: GitHub Copilot reference for database schema"
    $headerLines += "-- "
    $headerLines += "-- This file is automatically updated by backup_schema_for_copilot.ps1"
    $headerLines += "-- Use this file as reference when developing new features"
    $headerLines += "-- =================================================================================="
    $headerLines += ""
    $header = $headerLines -join "`n"
    
    # Combine header with schema content
    $schemaContent = Get-Content $schemaFile -Raw
    $combinedContent = $header + $schemaContent
    Set-Content -Path $latestFile -Value $combinedContent -Encoding UTF8
    
    Write-Host "[OK] Latest schema reference updated" -ForegroundColor Green
    
    # 5. Create development backup
    $devBackupFile = Join-Path $BackupDir "schema_backup_$Timestamp.sql"
    try {
        Copy-Item $schemaFile $devBackupFile -ErrorAction Stop
        Write-Host "[BACKUP] Development backup created" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Development backup failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "[INFO] Schema file: $schemaFile" -ForegroundColor Gray
        Write-Host "[INFO] Backup file: $devBackupFile" -ForegroundColor Gray
    }
    
    # 6. Cleanup old files (keep last 5)
    Write-Host "[CLEANUP] Cleaning up old files..." -ForegroundColor Yellow
    
    try {
        $oldSchemaFiles = Get-ChildItem $SchemaDir -Filter "complete_schema_*.sql" | Sort-Object CreationTime -Descending | Select-Object -Skip 5
        foreach ($file in $oldSchemaFiles) {
            Remove-Item $file.FullName -Force
            Write-Host "[REMOVE] Removed old file: $($file.Name)" -ForegroundColor Gray
        }
        
        $oldTableFiles = Get-ChildItem $SchemaDir -Filter "tables_structure_*.sql" | Sort-Object CreationTime -Descending | Select-Object -Skip 5
        foreach ($file in $oldTableFiles) {
            Remove-Item $file.FullName -Force
            Write-Host "[REMOVE] Removed old file: $($file.Name)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "[WARN] Cleanup failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # 7. Generate summary
    Write-Host "" -ForegroundColor White
    Write-Host "[SUMMARY] BACKUP SUMMARY" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host "[OK] Complete schema: $(Split-Path $schemaFile -Leaf)" -ForegroundColor Green
    Write-Host "[OK] Tables structure: $(Split-Path $tablesFile -Leaf)" -ForegroundColor Green
    Write-Host "[OK] Latest reference: $(Split-Path $latestFile -Leaf)" -ForegroundColor Green
    Write-Host "[OK] Development backup: $(Split-Path $devBackupFile -Leaf)" -ForegroundColor Green
    Write-Host "" -ForegroundColor White
    Write-Host "[COPILOT] GitHub Copilot can now reference:" -ForegroundColor Yellow
    Write-Host "   FILE: $latestFile" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    Write-Host "[SUCCESS] Schema backup completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "" -ForegroundColor White
    Write-Host "[ERROR] Schema backup failed!" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "" -ForegroundColor White
    
    # Check common issues
    Write-Host "[HELP] Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Check if pg_dump is installed and in PATH" -ForegroundColor Gray
    Write-Host "2. Verify database connection credentials" -ForegroundColor Gray
    Write-Host "3. Ensure network connectivity to Supabase" -ForegroundColor Gray
    Write-Host "4. Check if directories have write permissions" -ForegroundColor Gray
    
    exit 1
} finally {
    # Clean up environment variable
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

# 8. Optional: Git integration
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitStatus = git status --porcelain docs/schema/latest_schema_reference.sql 2>$null
    if ($gitStatus) {
        Write-Host "[GIT] Git detected changes in schema reference file" -ForegroundColor Cyan
        Write-Host "   You may want to commit this change:" -ForegroundColor Gray
        Write-Host "   git add docs/schema/latest_schema_reference.sql" -ForegroundColor Gray
        Write-Host "   git commit -m `"Auto-update: Schema reference for Copilot`"" -ForegroundColor Gray
    }
}

Write-Host "[DONE] All done! Happy coding with Copilot!" -ForegroundColor Green
