# AGENTS.md — BiliSum (Bilibili Video → Structured Knowledge)

BiliSum turns Bilibili (and other) videos into searchable notes, mindmaps, and a local knowledge base using ASR + LLM + optional VLM.

## Tech & Structure
- Root: apps/desktop (Electron+React), apps/service (FastAPI), packages/core + infra.
- Pipeline: yt-dlp download/probe → bilibili subtitle or ASR (FunASR recommended for zh) → transcript segments → LLM chunked summary (knowledge cards) → knowledge_note.md (full readable) → mindmap.json + visual notes (optional).
- Exports are self-contained Markdown + assets.
- Local only by design. Supports SiliconFlow, local Whisper/FunASR, OpenAI-compatible LLMs + vision models.

## Rules for Grok Sessions
- Always follow this file + any .grok/ contents when inside the tree.
- Prefer editing existing prompt templates rather than hard-coding.
- When working on ASR/transcription, reference transcribe_funasr_subprocess.py and settings.
- For UI changes, respect the current component structure (HomePage, VideoDetailPage, etc.).
- Keep changes backward compatible for existing tasks/exports.
- Update demo-exports/ and README when user-visible behavior changes.
- Use the running local service (uv run or the built exe) for end-to-end testing when possible.

## Cross-Machine Sync (Grok + Git)
- This project is cloned on every machine (see your ws-sync repo for exact clone command and path recommendations).
- Commit AGENTS.md, .grok/config.toml, design docs, and notes.
- Daily: git pull --rebase on arrival; git push --force-with-lease before leaving.
- Run `grok inspect` after pull to confirm rules are active.
- Long tasks: commit the design doc; recreate worktree or branch on other machine and resume.
- Sessions themselves are local (~/.grok/sessions/<encoded-cwd>/). Use the committed files + "continue from <sha>" for handoff.

## Useful Commands (when using Grok)
- Start the service: uv run --package video-sum-service python -m video_sum_service
- Or the desktop dev: npm run dev (from apps/desktop)
- Test clip is in demo-assets/
- Export artifacts end up in the task dir under data.

Update this file when architecture or conventions change — it will be present on all your machines.
