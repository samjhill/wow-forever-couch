#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
TAG="v1.9.2"
ASSET="whisper-bin-ubuntu-x64.tar.gz"
URL="https://github.com/ggml-org/whisper.cpp/releases/download/${TAG}/${ASSET}"
APPDIR="${HOME}/.local/opt/whisper-cpp"
SHARE="${HOME}/.local/share/whisper"
BINDIR="${HOME}/.local/bin"
mkdir -p "$BINDIR" "$SHARE" "$APPDIR"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
if [[ ! -x "${APPDIR}/whisper-cli" ]]; then
  echo "Downloading $URL"
  curl -L --fail --retry 3 -o "$TMP/$ASSET" "$URL"
  tar -xzf "$TMP/$ASSET" -C "$TMP"
  FOUND=$(find "$TMP" -type f -name 'whisper-cli' | head -1)
  cp -a "$(dirname "$FOUND")/." "$APPDIR/"
fi
cat > "${BINDIR}/whisper-cli" << 'WRAP'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="$HOME/.local/opt/whisper-cpp:${LD_LIBRARY_PATH:-}"
exec "$HOME/.local/opt/whisper-cpp/whisper-cli" "$@"
WRAP
chmod +x "${BINDIR}/whisper-cli" "${APPDIR}/whisper-cli"
MODEL="${SHARE}/ggml-base.en.bin"
if [[ ! -f "$MODEL" ]]; then
  curl -L --fail --retry 3 -o "$MODEL.partial" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
  mv "$MODEL.partial" "$MODEL"
fi
echo "OK: ${BINDIR}/whisper-cli → ${APPDIR}/whisper-cli"
echo "OK: $MODEL"
