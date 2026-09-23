#!/bin/sh
# One-time setup. Safe to re-run: each step skips itself when already done.
set -e
MCP="${DAVINCI_RESOLVE_MCP:-$HOME/davinci-resolve-mcp}"
TTS="${STORY_VIDEO_TTS:-$HOME/.local/share/story-video/tts-venv}"

for tool in uv ffmpeg; do
  command -v "$tool" >/dev/null || { echo "missing: $tool  (brew install $tool)"; exit 1; }
done

# 1. davinci-resolve-mcp: Resolve's scripting API + the in-app bridge the free edition needs
if [ ! -x "$MCP/venv/bin/python" ]; then
  [ -d "$MCP" ] || git clone --depth 1 https://github.com/samuelgursky/davinci-resolve-mcp.git "$MCP"
  # It wants Python 3.10-3.12; uv provides one without touching the system Python
  PY=$(uv python find 3.12 2>/dev/null || (uv python install 3.12 >/dev/null && uv python find 3.12))
  (cd "$MCP" && "$PY" install.py --clients manual)
  (cd "$MCP" && venv/bin/python scripts/install_resolve_bridge.py)
fi

# 2. Chatterbox, local expressive TTS. setuptools<80: its watermarker still imports pkg_resources
if ! "$TTS/bin/python" -c "import chatterbox.tts, perth; assert perth.PerthImplicitWatermarker" 2>/dev/null; then
  mkdir -p "$(dirname "$TTS")"
  uv venv -q -p 3.11 "$TTS"
  VIRTUAL_ENV="$TTS" uv pip install -q chatterbox-tts "setuptools<80"
fi

cat <<EOF

Setup done.
  MCP:        $MCP
  Chatterbox: $TTS   (model downloads on first narration, a few GB)

Free edition only, in Resolve:
  1. Point Resolve at a full Python (it looks only at PYTHON3HOME and /usr/local/bin/python3):
       launchctl setenv PYTHON3HOME "\$(\$(uv python find 3.12) -c 'import sys;print(sys.prefix)')"
     This is lost on reboot; re-run it then.
  2. Restart Resolve, open a project, Workspace > Scripts > resolve_bridge (leave it running).
Studio: Preferences > General > External scripting using > Local. No bridge needed.
EOF
