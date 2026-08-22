# SeniorConnect RSA Key Pair Generator (PowerShell)
param (
    [string]$KeysDir = "./keys"
)

if (!(Test-Path $KeysDir)) {
    New-Item -ItemType Directory -Path $KeysDir -Force | Out-Null
}

$PrivateKey = Join-Path $KeysDir "private.pem"
$PublicKey = Join-Path $KeysDir "public.pem"

Write-Host "Generating 2048-bit RSA private key: $PrivateKey"
openssl genpkey -algorithm RSA -out "$PrivateKey" -pkeyopt rsa_keygen_bits:2048

Write-Host "Extracting RSA public key: $PublicKey"
openssl rsa -pubout -in "$PrivateKey" -out "$PublicKey"

Write-Host "RSA key pair successfully generated in $KeysDir"
