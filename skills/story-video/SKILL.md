---
name: story-video
description: Make a fast kinetic-typography story video (founder story, promo, explainer, recap) in DaVinci Resolve from a short brief. Covers phrase-by-phrase title cards, expressive local AI narration (Chatterbox), synthesised SFX and a music bed with a drop, all cut to the voice and laid out on a Resolve timeline. Use whenever the user wants to "make a video like this", turn a story or script into a Resolve edit, make a launch/founder/recap video, or rebuild/tweak one made before (a folder with run.sh + make_cards.py), even if they don't mention Resolve by name.
---

# Story video → DaVinci Resolve

A working pipeline. **Don't rebuild it: copy `template/` and write the data.** The only creative work is the script. Everything else is one command.

The style: fast and emotional. One short phrase per card, cuts land where the words end, black cards with an occasional white contrast beat, a calm music bed that drops into a beat at the story's turn, and a brand end card. Keep cuts tight. Don't swap Chatterbox for the flat `say` voice unless the user asks.

## 0. First run on a machine
Check that `~/.local/share/story-video/tts-venv` and `~/davinci-resolve-mcp/venv` exist. If either is missing, run:
```bash
sh <this skill's dir>/setup.sh
```
Then relay its Resolve instructions to the user. `DAVINCI_RESOLVE_MCP` and `STORY_VIDEO_TTS` override the two locations.

## 1. Is Resolve reachable?
- **Studio** with external scripting set to Local: nothing to check.
- **Free edition:** the in-app bridge must be running. Check with:
  ```bash
  lsof -nP -iTCP:$(python3 -c "import json;print(json.load(open('$HOME/.config/davinci-resolve-mcp/bridge.json'))['port'])") -sTCP:LISTEN
  ```
  - A `fuscript` line means it's up.
  - Nothing printed: ask the user to open a project and run **Workspace ▸ Scripts ▸ resolve_bridge**.
  - If that menu shows no Python scripts, `PYTHON3HOME` was lost on reboot. The last lines of `setup.sh` print the fix.
  - Free Resolve 21.1+ dropped Python scripting entirely, so this path needs 21.0.x or Studio.

## 2. New video
1. Copy the template:
   ```bash
   cp -R <this skill's dir>/template ~/Movies/<slug>
   ```
2. In `make_cards.py`, write `SCRIPT`: rows of `(slug, style, text, seconds)`.
   - Cut sentences into phrases of about 1–2 s of speech. Split across cards where a spoken pause falls ("she had an idea" / "nobody believed in").
   - Styles: `serif`, `sans` (bold), `white` (a black-on-white contrast beat, use sparingly), `photo` (grey placeholder with a caption, where real media goes), `why` (the story's turn), `end` (text is `"NAME|URL"`).
   - `seconds` is only a floor. The voice sets the real length.
   - The music drop lands on the card with slug `why`. Keep exactly one, or change `DROP` in `make_audio.py`.
   - `SAY` holds spoken text that differs from the card text, for example `"end": "Brand dot com."`.
   - Brand: `PURPLE`/`ORANGE` (the end card) and `SERIF`/`SANS`, which are font file paths.
3. In `narrate.py`, set `EMOTION` for the key beats. `exaggeration` 0.5 is neutral, 0.8 is warm, 1.0–1.2 is the peak. A lower `cfg_weight` gives a slower, more deliberate delivery. Every slug not listed uses `DEFAULT` (0.65).
4. Build it:
   ```bash
   cd ~/Movies/<slug> && ./run.sh
   ```
   This narrates (about 1–2 min, plus a model download on first use), renders the cards, mixes the soundtrack, then builds a timeline and a `<Name> Cards` bin in the **currently open** project. The name comes from the folder; `TIMELINE_NAME="..."` overrides it. A re-run replaces only that timeline and bin.

Check the output: any voice line under about 0.7 s is probably a clipped take. Regenerate it (below) before reporting done.

## 3. Tweaks
- **Re-roll takes:**
  ```bash
  ~/.local/share/story-video/tts-venv/bin/python narrate.py <slug> [<slug>...]
  ```
  Then run `./run.sh --keep-voice`.
- **Text, timing or colours:** edit, then `./run.sh --keep-voice`. Re-narrate the lines whose words changed.
- **Clone a voice:** set `REFERENCE` in `narrate.py` to a clean clip of 10 s or more, including the user's own recording.
- **Sound:** in `make_audio.py`, `STYLE_CUE` maps each card style to a sound (whoosh, pop, blip, tick, thud, chime); `BPM`, `CHORDS`, `GAIN` and `VOICE_GAIN` shape the mix.
- **Real photos or footage:** import them and place them on V2 over the `photo` cards, either with the DaVinci MCP tools or with the same proxy `build_timeline.py` uses.

## Limits (tell the user; don't try to script around them)
- Card text is baked into the images, so it can't be edited in Resolve. Edit `SCRIPT` and re-run instead.
- Word-by-word text animation, push-ins, glitch transitions and glows need manual work in Resolve, because the scripting API can't set keyframes.
- Resolve imports a PNG as a single frame and ignores `endFrame`. That's why each card is baked into an exact-length mp4; don't "simplify" it back to stills.
- Chatterbox adds an inaudible AI watermark to its audio.
- The fonts and the `say` fallback assume macOS. On other platforms, change the font paths and always narrate with Chatterbox.
