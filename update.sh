#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $0 -e EMAIL"
  exit 1
}

while getopts "e:h" opt; do
  case $opt in
    e) EMAIL="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

[[ ! -v EMAIL ]] && usage

# Generate Packages index for each arch
POOL_ALL_DIR="pool/main/all"
for arch in amd64 arm64; do
  POOL_ARCH_DIR="pool/main/$arch"
  PKG_DIR="dists/stable/main/binary-$arch"

  {
    dpkg-scanpackages "$POOL_ARCH_DIR"
    dpkg-scanpackages "$POOL_ALL_DIR"
  } > "$PKG_DIR/Packages"
  gzip -c "$PKG_DIR/Packages" > "$PKG_DIR/Packages.gz"
done

dpkg-scanpackages "$POOL_ALL_DIR" > "dists/stable/main/binary-all/Packages"
gzip -c "dists/stable/main/binary-all/Packages" > "dists/stable/main/binary-all/Packages.gz"

# Generate Release
apt-ftparchive -c "aptftp.conf" release "dists/stable" > "dists/stable/Release"

# Sign — passphrase will be prompted interactively
gpg --default-key "$EMAIL" \
    --pinentry-mode loopback \
    -abs -o "dists/stable/Release.gpg" \
    "dists/stable/Release"

gpg --default-key "$EMAIL" \
    --pinentry-mode loopback \
    --clearsign -o "dists/stable/InRelease" \
    "dists/stable/Release"

echo "Repository updated successfully."

exit 0
