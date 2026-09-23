#!/bin/sh
# Whole pipeline, one command: voice -> cards -> soundtrack -> Resolve timeline.
#   ./run.sh              everything (re-narrates every line)
#   ./run.sh --keep-voice reuse voices/ takes, only rebuild cards/audio/timeline
# Free edition: Workspace > Scripts > resolve_bridge must be running in Resolve.
set -e
cd "$(dirname "$0")"
TTS="${STORY_VIDEO_TTS:-$HOME/.local/share/story-video/tts-venv}/bin/python"
MCP="${DAVINCI_RESOLVE_MCP:-$HOME/davinci-resolve-mcp}"
[ "$1" = "--keep-voice" ] || PYTORCH_ENABLE_MPS_FALLBACK=1 "$TTS" narrate.py 2>&1 | grep -E " ok$|Error" || true
uv run -q --with pillow make_cards.py
uv run -q --with numpy --with pillow make_audio.py
DAVINCI_RESOLVE_MCP="$MCP" "$MCP/venv/bin/python" build_timeline.py ${TIMELINE_NAME:+"$TIMELINE_NAME"}
