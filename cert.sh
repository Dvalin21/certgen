#!/bin/sh

# Execute as root user in documenso container and run the following commands
docker compose exec --user root documenso sh -c "
# Navigate to the certs directory
cd /app/certs

# Generate private key
openssl genrsa -out private.key 2048

# Generate certificate (adjust the subject as needed)
openssl req -new -x509 -key private.key -out certificate.crt -days 1460

# Create PKCS12 certificate with compatible format (NO PASSWORD)
openssl pkcs12 -export -out cert.p12 \\
  -inkey private.key \\
  -in certificate.crt \\
  -name \"documenso\" \\
  -passout pass: \\
  -keypbe PBE-SHA1-3DES \\
  -certpbe PBE-SHA1-3DES \\
  -macalg sha1

# Set correct ownership (container runs as UID 1001)
chown 1001:1001 cert.p12 certificate.crt private.key
chmod 644 cert.p12 certificate.crt private.key
"
