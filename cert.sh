#!/bin/bash

# Check for OpenSSL
if ! command -v openssl &> /dev/null; then
    echo "OpenSSL is not installed. Please install it first."
    exit 1
fi

# Configuration
CERT_NAME="certificate"
KEY_FILE="${CERT_NAME}.key"
ENC_KEY_FILE="${CERT_NAME}-encrypted.key"
CERT_FILE="${CERT_NAME}.crt"
P12_FILE="${CERT_NAME}.p12"
DAYS_VALID=397  # 397 days max for browser trust
PASS_FILE="${CERT_NAME}.pass"

# Generate secure 32-character password
gen_password() {
    LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+{}|:<>?=' < /dev/urandom \
    | head -c 32
}

PASSWORD=$(gen_password)
echo "$PASSWORD" > "$PASS_FILE"

# Security confirmation
echo "Generated secure password stored in $PASS_FILE"
echo "All keys will be encrypted with this password"

# Generate encrypted private key
echo "Generating encrypted private key (AES-256)..."
openssl genrsa -aes256 -out "$ENC_KEY_FILE" -passout pass:"$PASSWORD" 2048

# Generate CSR using encrypted key
echo "Generating CSR..."
openssl req -new -key "$ENC_KEY_FILE" -passin pass:"$PASSWORD" \
    -out "${CERT_NAME}.csr" -subj "/CN=${CERT_NAME}/O=MyOrg/C=US"

# Generate self-signed certificate
echo "Generating self-signed certificate..."
openssl x509 -req -days "$DAYS_VALID" -in "${CERT_NAME}.csr" \
    -signkey "$ENC_KEY_FILE" -passin pass:"$PASSWORD" -out "$CERT_FILE"

# Create secure PKCS#12 file
echo "Creating PKCS#12 file with AES-256 encryption..."
openssl pkcs12 -export -out "$P12_FILE" \
    -inkey "$ENC_KEY_FILE" -passin pass:"$PASSWORD" \
    -in "$CERT_FILE" -passout pass:"$PASSWORD" \
    -keypbe AES-256-CBC -certpbe AES-256-CBC -macalg sha256

# Verify the PKCS#12 file
if [ -f "$P12_FILE" ]; then
    echo "Verifying PKCS#12 file..."
    openssl pkcs12 -info -in "$P12_FILE" -passin pass:"$PASSWORD" -noout
else
    echo "Failed to create PKCS#12 file."
    exit 1
fi

# Cleanup
rm "${CERT_NAME}.csr"

# Final output
echo -e "\n\n=== Process completed successfully ==="
echo "Generated files:"
echo "  - Encrypted private key: $ENC_KEY_FILE"
echo "  - Certificate: $CERT_FILE"
echo "  - PKCS#12 bundle: $P12_FILE"
echo "  - Password file: $PASS_FILE"
echo -e "\nPassword for all files: $PASSWORD"
echo -e "\nWARNING: Store the password securely and protect generated files!"
