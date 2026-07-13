# BiliSum Local Demo Setup Log

Started: 2026-06-24

## 1. Prerequisites Installation

### Installed uv (Python package manager)
```powershell
irm https://astral.sh/uv/install.ps1 | iex
```
Result: uv 0.11.24 installed to `C:\Users\Eiji\.local\bin`

### Installed ffmpeg via winget
```powershell
winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
```
Result: ffmpeg 8.1.1

### Upgraded Node.js via winget
```powershell
winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
```
Result: Node.js v22.14.0

### Installed Ollama via winget
```powershell
winget install --id Ollama.Ollama -e --source winget --accept-source-agreements --accept-package-agreements
```
Result: Ollama 0.30.9

## 2. Clone Repository

```powershell
git clone https://github.com/lycohana/BiliSum.git C:\Users\Eiji\bilisum-demo
```
Result: latest commit `f7ae5e0 chore(release): v1.19.1 [skip ci]`

## 3. Install Dependencies

```powershell
cd C:\Users\Eiji\bilisum-demo
uv sync --python 3.12 --all-packages
npm install --prefix .\apps\desktop
```

## 4. Environment Configuration

Copied `.env.example` to `.env` and configured for fully local operation:
- `VIDEO_SUM_TRANSCRIPTION_PROVIDER=funasr`
- FunASR: paraformer-zh, fsmn-vad, ct-punc, cam++ (speaker diarization)
- LLM: Ollama at http://localhost:11434/v1 with qwen2.5:7b
- `VIDEO_SUM_AUTO_GENERATE_MINDMAP=true`
- Bilibili cookies: not provided (QR login unavailable headless; see troubleshooting)

## 5. Demo Video

Selected: `https://www.bilibili.com/video/BV1GJ411x7hY` (罗翔说刑法 - 张三的奇妙冒险, ~6 min public educational)

## 6. Ollama Model Pull

```powershell
ollama pull qwen2.5:7b
ollama pull llama3.2:3b
```
Result: both models available locally (qwen2.5:7b primary, llama3.2:3b fallback tested).

## 7. FunASR Installation

```powershell
$token = "bilisum-demo-local-token-2026"
curl.exe -s -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" `
  -d "@C:\Users\Eiji\AppData\Local\Temp\grok-goal-e59a5e2b47a7\implementer\funasr_install.json" `
  http://127.0.0.1:3838/api/v1/asr/funasr/install
```
Result: torch 2.12.1+cpu, funasr 1.3.14, modelscope 1.37.1 installed in project `.venv`.

### Managed-runtime subprocess fix (Windows)

FunASR worker subprocess uses managed runtime at:
`C:\Users\Eiji\AppData\Local\bilisum\runtime\base\Scripts\python.exe`

```powershell
& "C:\Users\Eiji\AppData\Local\bilisum\runtime\base\Scripts\python.exe" -m pip install funasr modelscope torch torchaudio
```
Without this, tasks failed with `ModuleNotFoundError: No module named 'funasr'`.

### camp++ cache corruption fix

Interrupted download corrupted ModelScope cache for `speech_campplus_sv_zh-cn_16k-common`.
Deleted cache directory and re-ran task after service restart.

## 8. Service Start

```powershell
cd C:\Users\Eiji\bilisum-demo
# Load .env into process environment before start
Get-Content .env | ForEach-Object {
  if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
    [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process')
  }
}
uv run --package video-sum-service python -m video_sum_service
```
Result: backend listening on `http://127.0.0.1:3838`, health `status=ok`, `runtime_startup.status=ready`.

Note: `.env` alone is not sufficient — BiliSum persists settings in SQLite; env vars must be loaded into the process at start, and settings were also pushed via `PUT /api/v1/settings`.

## 9. Settings Update (SQLite)

```powershell
curl.exe -s -X PUT -H "Authorization: Bearer bilisum-demo-local-token-2026" `
  -H "Content-Type: application/json" `
  -d "@C:\Users\Eiji\AppData\Local\Temp\grok-goal-e59a5e2b47a7\implementer\settings_update.json" `
  http://127.0.0.1:3838/api/v1/settings
```

## 10. Bilibili Fallback

Original target: `https://www.bilibili.com/video/BV1GJ411x7hY` (罗翔说刑法, ~6 min).

Failures:
- HTTP 412 when downloading without cookies
- Browser cookie export failed DPAPI decryption in headless context
- QR login unavailable headless

**Fallback:** local demo video built from bundled ASR test audio:
`C:\Users\Eiji\bilisum-demo\demo-assets\demo_local_zh.mp4`

To retry Bilibili: export `cookies.txt` from browser (Netscape format) and set:
`VIDEO_SUM_YTDLP_COOKIES_FILE=<absolute path to cookies.txt>`

## 11. End-to-End Processing (successful)

```powershell
curl.exe -s -X POST -H "Authorization: Bearer bilisum-demo-local-token-2026" `
  -H "Content-Type: application/json" `
  -d "@C:\Users\Eiji\AppData\Local\Temp\grok-goal-e59a5e2b47a7\implementer\create_task.json" `
  http://127.0.0.1:3838/api/v1/tasks
```

| Field | Value |
|-------|-------|
| Task ID | `4dfbb49a43144459aa5cb98fd718f1b5` |
| Status | `completed` |
| Duration | ~158 s |
| LLM tokens | 4150 (qwen2.5:7b) |
| Mind map | `ready` |
| VLM notes | `idle` (VLM not enabled) |

Transcript:
```
[00:00] 你好，
[00:01] 这是 billism 语音识别连接测试。
```

## 12. Exported Artifacts

Project exports: `C:\Users\Eiji\bilisum-demo\demo-exports\`
- `BiliSum Local Demo (Chinese ASR test clip) 2026-06-26.md` (main report)
- `knowledge_note.md`, `summary.json`, `mindmap.json`, `transcript.txt`
- `funasr_worker_result.json`, `funasr_worker_progress.jsonl`
- `BiliSum Local Demo (Chinese ASR test clip).mp3`

Task data dir:
`C:\Users\Eiji\AppData\Local\bilisum\data\tasks\4dfbb49a43144459aa5cb98fd718f1b5\`

## 13. Failed / Superseded Tasks

| Task ID | Cause | Resolution |
|---------|-------|------------|
| `b9556bdb...` | FunASR not in managed runtime | pip install into managed runtime |
| `d0f67638...` | camp++ cache JSONDecodeError | delete cache, restart, new task |

## 14. Verification (2026-06-26)

- Prerequisites: `prereqs.log` in scratch dir
- Config: `config.log`
- Launch (2x health): `launch.log` — both `status=ok`
- Main report: `main_report.md`
- Backend still healthy at `http://127.0.0.1:3838/health`