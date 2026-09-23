# story-video

A skill that turns a short brief into a **fast kinetic-typography story video in DaVinci Resolve**. It makes a card for every spoken phrase, reads them with an expressive AI voice, adds synthesised sound effects and a music bed that drops into a beat at the story's turn, and cuts everything to the voice on a real Resolve timeline you can keep editing.

Everything runs locally: no stock audio, no cloud TTS, no API keys.

## Install

**Claude Code plugin:**

```bash
claude plugin marketplace add Lokendrakushwah12/story-video
claude plugin install story-video@story-video
```

**Any agent** via [vercel-labs/skills](https://github.com/vercel-labs/skills), a third-party CLI (Claude Code, Cursor, Codex and others):

```bash
npx skills add Lokendrakushwah12/story-video      # into ./<agent>/skills/
npx skills add -g Lokendrakushwah12/story-video   # global
```

**By hand:**

```bash
git clone https://github.com/Lokendrakushwah12/story-video.git
cp -R story-video/skills/story-video ~/.claude/skills/
```

Then run the one-time setup once. The skill also tells the agent to run it when something is missing:

```bash
sh ~/.claude/skills/story-video/setup.sh
```

It installs [davinci-resolve-mcp](https://github.com/samuelgursky/davinci-resolve-mcp), which provides Resolve scripting (and the in-app bridge that the free edition needs), plus [Chatterbox](https://github.com/resemble-ai/chatterbox) for the voice. You need `uv` and `ffmpeg` installed first.

## Use it

Once it's installed, describe the video and the skill triggers on its own:

> "make a 30 second founder story video: ex-banker, quit to build a budgeting app, 40k users now. brand Pennywise, pennywise.app, green and black"

> "here's a reference: https://x.com/… — make one like it for our launch"

> "the 'what are you waiting for' line sounds flat, redo it more urgent"

The agent writes the script as cards, sets the emotion for each line, runs one command, and a timeline appears in the Resolve project you have open.

## How it works

```
make_cards.py SCRIPT ──► narrate.py (Chatterbox, per-line emotion) ──► voices/*.wav
        │                                                                   │
        └─► cards/*.png → exact-length mp4 per card ◄── length = its voice ─┘
                              │
make_audio.py: voice + SFX per card style + chord bed with a drop at "why"
                              │
build_timeline.py ──► Resolve: "<Name> Cards" bin, V1 = cards, A1 = mix
```

| File | You edit | What it does |
|---|---|---|
| `make_cards.py` | `SCRIPT`, colours, fonts | card per phrase; the voice decides how long it stays up |
| `narrate.py` | `EMOTION`, `REFERENCE` | expressive narration, per-line intensity, optional voice clone |
| `make_audio.py` | `STYLE_CUE`, `BPM`, `CHORDS` | oscillator/noise SFX palette and a music bed, no audio files |
| `build_timeline.py` | — | imports into Resolve and builds the timeline (Studio directly, free edition via the bridge) |
| `run.sh` | — | all of the above; `--keep-voice` skips re-narrating |

## What it won't do

- **Keyframed motion.** Word-by-word text reveals, push-ins, glitch transitions and glows need manual work in Resolve, because its scripting API can't set keyframes. What you get is a correctly paced, fully scored edit to animate on top of.
- **Editable text in Resolve.** Card text is baked into the images. Change `SCRIPT` and re-run instead.
- **Free Resolve 21.1+.** Blackmagic moved Python scripting to Studio in 21.1. The free edition works up to 21.0.x through the bridge; Studio works on any version.

Chatterbox adds an inaudible AI watermark to everything it generates. The fonts and the `say` fallback voice assume macOS.

## Install counts

A daily workflow snapshots GitHub's traffic data into [`traffic/SUMMARY.md`](traffic/SUMMARY.md). It exists because GitHub keeps only a **14-day rolling window** and discards the rest, so anything not captured is lost for good.

Clones cover every install path (`claude plugin marketplace add`, `npx skills add` and a manual `git clone`), and there's no way to tell them apart. `claude plugin update` fetches again, so `uniques` is a better proxy for people than `count`. None of it measures actual *use*: a skill is static files with no runtime, so acquisition is the only thing observable.
