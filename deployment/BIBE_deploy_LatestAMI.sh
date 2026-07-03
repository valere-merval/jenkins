#!/bin/bash
set -euo pipefail

# Gültige Umgebungs-Keys
valid_envs="k l q h i j n m"

# Prüfen, ob genug Argumente übergeben wurden
if [[ $# -lt 2 ]]; then
  echo "Fehler: Erwartet mindestens 2 Parameter (imageMaster und Umgebung)."
  exit 1
fi

IMAGE_MASTER="$1"
UMGEBUNG="$2"
shift 2

echo "Bash-Version: $BASH_VERSION"
echo "IMAGE_MASTER: $IMAGE_MASTER"
echo "UMGEBUNG:     $UMGEBUNG"

# Umgebung prüfen
if [[ ! " $valid_envs " =~ " $UMGEBUNG " ]]; then
  echo "Fehler: Ungültige Umgebung: '$UMGEBUNG'"
  exit 1
fi

# imageMaster-Format case-insensitive prüfen
shopt -s nocasematch
if [[ ! "$IMAGE_MASTER" =~ ^nvs-psx-bibe-imageMasteral23-.*$ ]]; then
  echo "Fehler: Kein gültiger imageMaster angegeben."
  exit 1
fi
shopt -u nocasematch

cd ../update-stack

# Snapshot ID ermitteln
echo "Suche Snapshot für $IMAGE_MASTER..."
SNAPSHOT_ID=$(aws ec2 describe-snapshots \
  --filters Name=tag:ImageMaster,Values="*" Name=tag:Name,Values="$IMAGE_MASTER" \
  --query 'sort_by(Snapshots, &StartTime)[-1].SnapshotId' \
  --output text)

if [[ -z "$SNAPSHOT_ID" || "$SNAPSHOT_ID" == "None" ]]; then
  echo "Fehler: Kein Snapshot gefunden."
  exit 1
fi

echo "Gefundene Snapshot ID: $SNAPSHOT_ID"

# Golden AMI aus Snapshot ableiten
echo "Suche AMI für Snapshot..."
GOLDEN_AMI=$(aws ec2 describe-images \
  --filters Name=block-device-mapping.snapshot-id,Values="$SNAPSHOT_ID" \
  --query 'Images[*].ImageId' \
  --output text)

if [[ -z "$GOLDEN_AMI" ]]; then
  echo "Fehler: Kein Golden AMI gefunden."
  exit 1
fi

echo "Verwende GOLDEN_AMI: $GOLDEN_AMI"

# Alle übergebenen Umgebungsschlüssel verarbeiten
for env in "$UMGEBUNG" "$@"; do
  if [[ " $valid_envs " =~ " $env " ]]; then
    echo "Verarbeite Umgebung: $env"

    sed -i -e "/^Name:/c\\Name: nvs-psx${env}-bibe" \
           -e "/^NvsBibeGoldenImageAmi:/c\\NvsBibeGoldenImageAmi: $GOLDEN_AMI" \
           nvs-psx-bibe.cfg

    echo "Neue Konfiguration für $env:"
    cat nvs-psx-bibe.cfg

    echo "Starte Stack-Update für $env..."
    ./update-stack.py nvs-psx-bibe.cfg
  else
    echo "Ignoriere ungültigen Umgebungsschlüssel: $env"
  fi
done
