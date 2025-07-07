param(
    [switch]$Verbose
)

# ==================================================================================
# SUPABASE SCHEMA BACKUP FOR COPILOT REFERENCE
# ==================================================================================
# Purpose: Export complete database schema for accurate Copilot code generation
# Output: docs/schema/latest_schema_reference.sql
# Usage: .\scripts\backup_schema_for_copilot.ps1 -Verbose
# ==================================================================================

# Configuration
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
$SCHEMA_DIR = Join-Path $PROJECT_ROOT "docs/schema"
$OUTPUT_FILE = Join-Path $SCHEMA_DIR "latest_schema_reference.sql"
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Display banner
if ($Verbose) {
    Write-Host "🎯 POS MINI MODULAR 3 - SCHEMA BACKUP FOR COPILOT" -ForegroundColor Cyan
    Write-Host "================================================================================================" -ForegroundColor Gray
    Write-Host "📅 Migration Era: Enhanced Auth System and Reorganized Migrations" -ForegroundColor Green
    Write-Host "🎯 Purpose: Generate accurate schema reference for GitHub Copilot" -ForegroundColor Yellow
    Write-Host "📁 Output: $OUTPUT_FILE" -ForegroundColor Blue
    Write-Host "" -ForegroundColor Gray
}

# Create directories if not exist
if (-not (Test-Path $SCHEMA_DIR)) {
    New-Item -ItemType Directory -Path $SCHEMA_DIR -Force | Out-Null
    if ($Verbose) { Write-Host "📁 Created schema directory: $SCHEMA_DIR" -ForegroundColor Green }
}

# Supabase connection details - Update these with your actual values
$SUPABASE_HOST = "db.wffuqkmdncfhkglbhlkx.supabase.co"
$SUPABASE_PORT = "5432"
$SUPABASE_USER = "postgres"
$SUPABASE_DB = "postgres"

# Check if pg_dump is available
try {
    $pgDumpVersion = & pg_dump --version 2>$null
    if ($Verbose) { Write-Host "✅ PostgreSQL tools available: $pgDumpVersion" -ForegroundColor Green }
} catch {
    Write-Host "❌ ERROR: pg_dump not found. Please install PostgreSQL client tools." -ForegroundColor Red
    Write-Host "   Download from: https://www.postgresql.org/download/" -ForegroundColor Yellow
    exit 1
}

# Prompt for password if not set in environment
if (-not $env:SUPABASE_PASSWORD) {
    Write-Host "🔐 Please enter your Supabase database password:" -ForegroundColor Yellow
    $SecurePassword = Read-Host -AsSecureString
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))
} else {
    $env:PGPASSWORD = $env:SUPABASE_PASSWORD
}

if ($Verbose) {
    Write-Host "🔄 Starting schema export..." -ForegroundColor Cyan
    Write-Host "   Host: $SUPABASE_HOST" -ForegroundColor Gray
    Write-Host "   Database: $SUPABASE_DB" -ForegroundColor Gray
    Write-Host "   User: $SUPABASE_USER" -ForegroundColor Gray
}

# Export schema with comprehensive options
$pgDumpArgs = @(
    "--host=$SUPABASE_HOST"
    "--port=$SUPABASE_PORT"
    "--username=$SUPABASE_USER"
    "--dbname=$SUPABASE_DB"
    "--schema-only"
    "--no-owner"
    "--no-privileges"
    "--verbose"
    "--file=$OUTPUT_FILE"
    # Include multiple schemas
    "--schema=public"
    "--schema=auth"
    "--schema=storage"
    # Include functions and procedures
    "--routines"
    # Include comments
    "--include-comments"
)

try {
    if ($Verbose) { Write-Host "🚀 Executing pg_dump..." -ForegroundColor Cyan }
    
    & pg_dump @pgDumpArgs 2>&1 | ForEach-Object {
        if ($Verbose -and $_ -match "pg_dump:") {
            Write-Host "   $_" -ForegroundColor DarkGray
        }
    }
    
    if ($LASTEXITCODE -eq 0) {
        if ($Verbose) { Write-Host "✅ Schema export completed successfully!" -ForegroundColor Green }
    } else {
        throw "pg_dump failed with exit code: $LASTEXITCODE"
    }
} catch {
    Write-Host "❌ ERROR: Failed to export schema" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "" -ForegroundColor Gray
    Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Verify Supabase connection details" -ForegroundColor Gray
    Write-Host "   2. Check database password" -ForegroundColor Gray
    Write-Host "   3. Ensure network connectivity to Supabase" -ForegroundColor Gray
    Write-Host "   4. Verify pg_dump is installed and in PATH" -ForegroundColor Gray
    exit 1
}

# Add custom header to schema file
$headerContent = @"
-- ==================================================================================
-- SUPABASE SCHEMA REFERENCE FOR GITHUB COPILOT
-- ==================================================================================
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Project: POS Mini Modular 3
-- Purpose: Complete schema reference for accurate code generation
-- 
-- This file contains:
-- ✅ All table definitions with accurate column names and types
-- ✅ All functions and procedures currently deployed  
-- ✅ All constraints, indexes, and relationships
-- ✅ Auth schema (auth.users, auth.identities, etc.)
-- ✅ Public schema (all pos_mini_modular3_* tables)
-- ✅ Comments and documentation
--
-- Use this file as reference when:
-- - Writing database queries in TypeScript
-- - Creating new migrations
-- - Debugging column name errors
-- - Understanding table relationships
-- ==================================================================================

"@

# Prepend header to schema file
$originalContent = Get-Content $OUTPUT_FILE -Raw
$newContent = $headerContent + $originalContent
Set-Content -Path $OUTPUT_FILE -Value $newContent -Encoding UTF8

# Generate summary
if (Test-Path $OUTPUT_FILE) {
    $fileSize = (Get-Item $OUTPUT_FILE).Length
    $fileSizeKB = [Math]::Round($fileSize / 1KB, 2)
    
    if ($Verbose) {
        Write-Host "" -ForegroundColor Gray
        Write-Host "📊 EXPORT SUMMARY" -ForegroundColor Cyan
        Write-Host "================================================================================================" -ForegroundColor Gray
        Write-Host "✅ Schema file created: $OUTPUT_FILE" -ForegroundColor Green
        Write-Host "📏 File size: $fileSizeKB KB" -ForegroundColor Blue
        Write-Host "🕐 Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Blue
        Write-Host "" -ForegroundColor Gray
        
        # Count tables and functions
        $content = Get-Content $OUTPUT_FILE -Raw
        $tableCount = ($content | Select-String "CREATE TABLE" -AllMatches).Matches.Count
        $functionCount = ($content | Select-String "CREATE.*FUNCTION" -AllMatches).Matches.Count
        
        Write-Host "📋 Content Summary:" -ForegroundColor Yellow
        Write-Host "   Tables: $tableCount" -ForegroundColor Gray
        Write-Host "   Functions: $functionCount" -ForegroundColor Gray
        
        # Check for key tables
        $keyTables = @(
            "pos_mini_modular3_user_profiles",
            "pos_mini_modular3_businesses", 
            "pos_mini_modular3_business_types",
            "pos_mini_modular3_role_permissions",
            "auth.users"
        )
        
        Write-Host "" -ForegroundColor Gray
        Write-Host "🔍 Key Tables Verification:" -ForegroundColor Yellow
        foreach ($table in $keyTables) {
            $found = $content -match "CREATE TABLE.*$table"
            $status = if ($found) { "✅" } else { "❌" }
            Write-Host "   $status $table" -ForegroundColor $(if ($found) { "Green" } else { "Red" })
        }
        
        Write-Host "" -ForegroundColor Gray
        Write-Host "🎯 NEXT STEPS FOR COPILOT:" -ForegroundColor Cyan
        Write-Host "1. Use this schema file as reference when writing database code" -ForegroundColor Gray
        Write-Host "2. Fix migration 004 based on actual column names" -ForegroundColor Gray
        Write-Host "3. Verify all function signatures match deployed versions" -ForegroundColor Gray
        Write-Host "4. Update TypeScript interfaces to match real schema" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Schema file was not created" -ForegroundColor Red
    exit 1
}

# Cleanup password from environment
$env:PGPASSWORD = $null

if ($Verbose) {
    Write-Host "" -ForegroundColor Gray
    Write-Host "🚀 Schema backup completed! Ready for enhanced Copilot code generation." -ForegroundColor Green
    Write-Host "================================================================================================" -ForegroundColor Gray
}