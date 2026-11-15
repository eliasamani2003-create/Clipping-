# Clipping

Home of the **GTA 6 Clipper** Claude Code skill: GTA 6 streams in (YouTube, Twitch, Kick), ready-to-post
9:16 clips out (facecam on top, gameplay below, hook title bar, word-by-word captions, plus a `POST.md`
with a caption and hashtags per clip).

The skill lives in [`.claude/skills/gta6-clipper/`](.claude/skills/gta6-clipper/), so Claude Code loads it
automatically in any session opened in this repo. Full docs: [SKILL.md](.claude/skills/gta6-clipper/SKILL.md)
· [README](.claude/skills/gta6-clipper/README.md).

## Set up on your Mac (recommended)

```bash
git clone https://github.com/eliasamani2003-create/Clipping-.git ~/Clipping
brew install ffmpeg deno
bash ~/Clipping/.claude/skills/gta6-clipper/scripts/setup.sh      # run until it prints "All set"
```

Then open Claude Code in `~/Clipping` and say *"clip this stream: &lt;link&gt;"* or
*"find today's biggest GTA 6 streams and clip them"*. To have the skill in every folder, link it once:
`ln -s ~/Clipping/.claude/skills/gta6-clipper ~/.claude/skills/gta6-clipper`.

Clips go to `~/gta6-clips/<date>/<streamer>__<stream title>/`.

## Linux / cloud sessions

The scripts also run on Linux (`sudo apt-get install -y ffmpeg nodejs fonts-liberation fonts-noto-color-emoji`).
A Claude Code cloud session needs network access to YouTube, Twitch, Kick, their video CDNs and
huggingface.co, which the default limited network policy blocks.
