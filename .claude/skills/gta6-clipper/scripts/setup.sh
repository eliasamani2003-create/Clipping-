#!/bin/bash
# One-time setup for gta6-clipper. Safe to run again. Prints "All set" at the end.
set -e
ENV_DIR="$HOME/.gta6-clipper"
VENV="$ENV_DIR/venv"
HERE="$(cd "$(dirname "$0")" && pwd)"
ok()   { printf "\033[32m✓\033[0m %s\n" "$1"; }
bad()  { printf "\033[31m✗\033[0m %s\n" "$1"; MISSING=1; }
MISSING=0
if [ "$(uname)" = Darwin ]; then
  FFMPEG_HINT="brew install ffmpeg"; JS_HINT="brew install deno"
else
  FFMPEG_HINT="sudo apt-get install -y ffmpeg"; JS_HINT="install node or deno (e.g. sudo apt-get install -y nodejs)"
fi

echo "gta6-clipper setup"
command -v ffmpeg >/dev/null && ok "ffmpeg" || bad "ffmpeg missing: $FFMPEG_HINT"
command -v claude >/dev/null && ok "Claude Code" || bad "claude missing: install Claude Code first"
if command -v deno >/dev/null || command -v node >/dev/null || command -v bun >/dev/null; then
  ok "JavaScript runtime (YouTube needs one)"
else
  bad "no deno/node: $JS_HINT  (YouTube downloads need it)"
fi
FREE_GB=$(df -Pk "$HOME" | awk 'NR==2{print int($4/1048576)}')   # works on macOS and Linux
[ "${FREE_GB:-9}" -ge 2 ] && ok "disk: ${FREE_GB} GB free" || bad "only ${FREE_GB} GB free; setup needs ~1 GB, clipping ~0.1 GB per stream hour"
[ "$MISSING" = 1 ] && { echo; echo "Fix the ✗ lines above, then run this again."; exit 1; }

mkdir -p "$ENV_DIR"
if [ ! -x "$VENV/bin/python" ]; then
  if command -v uv >/dev/null; then
    uv venv -q --python 3.11 "$VENV" || uv venv -q "$VENV"
  else
    python3 -m venv "$VENV"
  fi
fi
PKGS="faster-whisper opencv-python-headless<5 pillow numpy yt-dlp"
if command -v uv >/dev/null; then
  uv pip install -q --python "$VENV/bin/python" -U $PKGS
else
  "$VENV/bin/python" -m pip install -q -U pip
  "$VENV/bin/python" -m pip install -q -U $PKGS
fi
ok "Python packages (private env in ~/.gta6-clipper)"

"$VENV/bin/python" - <<'PY' 2> >(grep -v -e "^objc\[" -e "One of the duplicates" >&2)
from faster_whisper import WhisperModel
for name in ("tiny", "base"):
    WhisperModel(name, device="cpu", compute_type="int8")
print("\033[32m✓\033[0m Whisper models (tiny = listening, base = captions)")
PY

mkdir -p "$ENV_DIR/models"
# A failed download must not leave an error page behind as the "model" (OpenCV would crash on it).
if [ -f "$ENV_DIR/models/yunet.onnx" ] && [ "$(wc -c < "$ENV_DIR/models/yunet.onnx")" -lt 100000 ]; then
  rm -f "$ENV_DIR/models/yunet.onnx"
fi
if [ ! -s "$ENV_DIR/models/yunet.onnx" ]; then
  curl -fsSL -o "$ENV_DIR/models/yunet.onnx.part" \
    "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx" \
    && [ "$(wc -c < "$ENV_DIR/models/yunet.onnx.part")" -gt 100000 ] \
    && mv "$ENV_DIR/models/yunet.onnx.part" "$ENV_DIR/models/yunet.onnx"
  rm -f "$ENV_DIR/models/yunet.onnx.part"
fi
[ -s "$ENV_DIR/models/yunet.onnx" ] && ok "facecam finder (OpenCV YuNet, 0.2 MB)" || echo "! facecam model download failed; clips fall back to a simpler face finder"

mkdir -p "$HOME/gta6-clips"
[ -f "$HOME/gta6-clips/streamers.txt" ] || cp "$HERE/../streamers.txt" "$HOME/gta6-clips/streamers.txt"
ok "watchlist: ~/gta6-clips/streamers.txt"
echo
echo "All set. Try:  bash \"$HERE/gta6clip\" --find --list"
