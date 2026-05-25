ALTER SYSTEM SET ssl = 'on';
ALTER SYSTEM SET ssl_cert_file = '/run/secrets/postgres/server.crt';
ALTER SYSTEM SET ssl_key_file = '/run/secrets/postgres/server.key';
