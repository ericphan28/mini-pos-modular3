$env:PGPASSWORD = "Ex8bngfrY9PVaHt5"
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --no-owner --no-privileges --file=backup_public_tables.sql

$env:PGPASSWORD = "Ex8bngfrY9PVaHt5"
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema=auth --table=public.* --table=auth.users --data-only --no-owner --no-privileges --file=backup_tables_data.sql

