DO 5dff9ac3b254:/tmp/create_app_user.sql
DECLARE
  pw text;
BEGIN
  pw := pg_read_file('/run/secrets/shopsnports_app_user_password');
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='app_user') THEN
    EXECUTE format('CREATE ROLE app_user WITH LOGIN PASSWORD %L', pw);
  ELSE
    EXECUTE format('ALTER ROLE app_user WITH PASSWORD %L', pw);
  END IF;
END
5dff9ac3b254:/tmp/create_app_user.sql;

GRANT CONNECT ON DATABASE shopsnports TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
