# qwen3-asr-tts-gb10

Deploy [Qwen3-ASR](https://huggingface.co/Qwen/Qwen3-ASR-1.7B) and [Qwen3-TTS](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-0.6B-Base) on an NVIDIA GB10 as OpenAI-compatible APIs.

## Components

| Component | Description | Docs |
|---|---|---|
| **[qwen3-asr](qwen3-asr/)** | Speech-to-text API — transcribes audio to text with auto language detection | [README](qwen3-asr/README.md) |
| **[qwen3-tts](qwen3-tts/)** | Text-to-speech API — clone, custom, and design voice modes | [README](qwen3-tts/README.md) |
| **[voice-playground](voice-playground/)** | Gradio UI — test voices, create clone/design voices | [README](voice-playground/README.md) |

## Quick Start

### 1. Build & publish containers

```bash
# Login to ghcr.io first
docker login ghcr.io -u cjlapao -p <personal-access-token>

# Build all images locally
make build

# Push to ghcr.io (tags both :latest and :<git-sha>)
make push
```

**Individual targets:**

```bash
make build-asr   # Build ASR only
make build-tts   # Build TTS only
make build-play  # Build Playground only

make push-asr    # Push ASR to ghcr.io
make push-tts    # Push TTS to ghcr.io
make push-play   # Push Playground to ghcr.io
```

**Override version or registry:**

```bash
make VERSION=v1.0.0 build push
make PUSH_REPO=ghcr.io/myuser build
```

See `make help` for the full list of targets.

### 2. Run locally

**Root compose** — all 3 services from one file (ASR + TTS always start, Playground opt-in):

```bash
# Start ASR + TTS (default, no playground)
docker compose up -d

# Start everything including playground
docker compose --profile playground up -d

# Stop everything
docker compose down
```

**Per-component compose** — build from source or consume from ghcr.io:

```bash
# ASR only (dev: build from source)
cd qwen3-asr && docker compose --file docker-compose.dev.yml up -d

# TTS + UI + Playground (dev: build from source)
cd qwen3-tts && docker compose --file docker-compose.dev.yml up -d
```

Or production (consume from ghcr.io):

```bash
cd qwen3-asr && docker compose --file docker-compose.prod.yml up -d
cd qwen3-tts && docker compose --file docker-compose.prod.yml up -d
```

### 3. Access services

| Service | URL | Default Port |
|---|---|---|
| ASR API | `http://localhost:8004` | 8004 |
| TTS API (OpenAI-compatible) | `http://localhost:8005` | 8005 |
| Voice Playground | `http://localhost:8006` | 8006 |

All ports are configurable via environment variables — see each component's README.

## Models

| Model | Hugging Face |
|---|---|
| Qwen3-ASR-1.7B | [Qwen/Qwen3-ASR-1.7B](https://huggingface.co/Qwen/Qwen3-ASR-1.7B) |
| Qwen3-TTS-12Hz-0.6B-Base | [Qwen/Qwen3-TTS-12Hz-0.6B-Base](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-0.6B-Base) |
| Qwen3-TTS-12Hz-1.7B-CustomVoice | [Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice) |
| Qwen3-TTS-12Hz-1.7B-VoiceDesign | [Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign) |

## Architecture

```
                   ┌─────────────────────────────────────────────┐
                   │           qwen3-tts (full stack)            │
                   │                                             │
  ┌──────────┐     │  ┌────────────┐  ┌──────────┐  ┌──────────┐ │
  │  ASR     │     │  │  qwen3-tts │  │qwen3-tts │  │playground│ │
  │  (ASR)   │     │  │   (API)    │  │   (UI)   │  │  (Gradio)│ │
  │          │     │  │            │◀─┤          │◀─│          │ │
  └──────────┘     │  │            │  │          │  │          │ │
                   │  │            │  │          │  │          │ │
                   │  └────────────┘  └──────────┘  └──────────┘ │
                   │                                             │
                   │  HuggingFace Hub (model download)           │
                   │  /app/voices/ (persistent voice storage)    │
                   └─────────────────────────────────────────────┘
```

## Requirements

- NVIDIA GPU (CUDA) — GB10 recommended
- Docker + Docker Compose v2
- `nvidia-container-toolkit`

## Environment Overrides

All services support environment variable overrides for ports, model IDs, and registry configuration. Create a `.env` file or pass variables on the command line:

```bash
# Override ASR model and port
ASR_MODEL_ID=Qwen/Qwen3-ASR-3B ASR_HOST_PORT=9999 \
  docker compose up -d

# Override TTS models and ports
TTS_MODEL_BASE=Qwen/Qwen3-TTS-12Hz-0.6B-Base \
  TTS_HOST_PORT=9995 \
  docker compose up -d

# Custom registry
IMAGE_PREFIX=ghcr.io/myuser IMAGE_TAG=v1.0.0 \
  docker compose --profile playground up -d
```

## Project Structure

```
├── docker-compose.yml            # Global: ASR + TTS + Playground (opt-in)
├── Makefile                      # Build & push containers
├── README.md                     # This file
├── qwen3-asr/
│   ├── Dockerfile                # ASR container (nvcr.io/nvidia/pytorch base)
│   ├── asr_server.py             # FastAPI server
│   ├── docker-compose.dev.yml    # Dev: build from source
│   ├── docker-compose.prod.yml   # Prod: consume from ghcr.io
│   └── README.md
├── qwen3-tts/
│   ├── Dockerfile                # TTS container (nvcr.io/nvidia/pytorch base)
│   ├── tts_server.py             # FastAPI server
│   ├── voice_store.py            # Voice persistence layer
│   ├── voices/                   # Persistent voice storage
│   ├── docker-compose.dev.yml    # Dev: build from source (+ TTS UI)
│   ├── docker-compose.prod.yml   # Prod: consume from ghcr.io
│   └── README.md
└── voice-playground/
    ├── Dockerfile                # Playground container (python:3.12-slim)
    ├── app.py                    # Gradio UI
    ├── docker-compose.dev.yml    # Dev: build from source
    ├── docker-compose.prod.yml   # Prod: consume from ghcr.io
    └── README.md
```
