#!/usr/bin/env bash
# SeniorConnect RSA Key Pair Generator
# Generates a persistent 2048-bit RSA key pair in PKCS#8 format for RS256 JWT signing.

set -e

KEYS_DIR="${1:-./keys}"
mkdir -p "$KEYS_DIR"

PRIVATE_KEY="$KEYS_DIR/private.pem"
PUBLIC_KEY="$KEYS_DIR/public.pem"

echo "Generating 2048-bit RSA private key: $PRIVATE_KEY"
openssl genpkey -algorithm RSA -out "$PRIVATE_KEY" -pkeyopt rsa_keygen_bits:2048

echo "Extracting RSA public key: $PUBLIC_KEY"
openssl rsa -pubout -in "$PRIVATE_KEY" -out "$PUBLIC_KEY"

chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

echo "RSA key pair successfully generated in $KEYS_DIR"
