# ==============================================================================
# Makefile for building and publishing qwen3-asr-tts-gb10 containers
# ==============================================================================
#
# Targets:
#   make build        — Build all 3 containers locally
#   make build-asr    — Build qwen3-asr only
#   make build-tts    — Build qwen3-tts only
#   make build-play   — Build voice-playground only
#   make push         — Push all 3 to ghcr.io
#   make push-asr     — Push qwen3-asr to ghcr.io
#   make push-tts     — Push qwen3-tts to ghcr.io
#   make push-play    — Push voice-playground to ghcr.io
#   make push-one=ASR|TTS|PLAY — Push a single image
#   make clean        — Remove built images
#   make help         — Show this help
#
# Variables (override on command line, e.g. make PUSH_REPO=ghcr.io/myorg):
#   PUSH_REPO   — Target registry prefix (default: ghcr.io/cjlapao)
#   VERSION     — Image version tag (default: git short SHA)
#
# Prerequisites:
#   - Docker installed and running
#   - Logged into ghcr.io:  docker login ghcr.io -u <user> -p <token>
#   - NVIDIA GPU + nvidia-container-toolkit (for asr/tts images)
# ==============================================================================

# ── Registry & version ────────────────────────────────────────────────────────

PUSH_REPO   ?= ghcr.io/cjlapao
VERSION     ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "dev")

# ── Image definitions ─────────────────────────────────────────────────────────

ASR_DIR     := qwen3-asr
TTS_DIR     := qwen3-tts
PLAY_DIR    := voice-playground

ASR_NAME    := $(PUSH_REPO)/qwen3-asr-gb10
TTS_NAME    := $(PUSH_REPO)/qwen3-tts-gb10
PLAY_NAME   := $(PUSH_REPO)/voice-playground

# ── TTS build args ────────────────────────────────────────────────────────────

TTS_ARGS    := \
	--build-arg FASTER_QWEN3_TTS_REF=0.2.6 \
	--build-arg TRANSFORMERS_VERSION=4.57.3 \
	--build-arg TORCHAUDIO_VERSION=2.9.1

# ── Helper: tag & push helper ─────────────────────────────────────────────────
# Usage: $(call tag_and_push,NAME,TAG,DEST_NAME)
#   NAME:TAR → DEST_NAME:TAR, then DEST_NAME:TAR → DEST_NAME:latest
# ──────────────────────────────────────────────────────────────────────────────

define tag_and_push
	docker tag $(1):$(2) $(3):$(2)
	docker push $(3):$(2)
	docker tag $(3):$(2) $(3):latest
	docker push $(3):latest
endef

# ── Build targets ─────────────────────────────────────────────────────────────

.PHONY: build build-asr build-tts build-play clean help push-one

build: build-asr build-tts build-play
	@echo ""
	@echo "=== All images built successfully ==="
	@echo "  $(ASR_NAME):$(VERSION)"
	@echo "  $(TTS_NAME):$(VERSION)"
	@echo "  $(PLAY_NAME):$(VERSION)"

build-asr:
	@echo ">>> Building $(ASR_NAME):$(VERSION) ..."
	docker build -t $(ASR_NAME):$(VERSION) $(ASR_DIR)
	@echo ">>> Done: $(ASR_NAME):$(VERSION)"

build-tts:
	@echo ">>> Building $(TTS_NAME):$(VERSION) ..."
	docker build $(TTS_ARGS) -t $(TTS_NAME):$(VERSION) $(TTS_DIR)
	@echo ">>> Done: $(TTS_NAME):$(VERSION)"

build-play:
	@echo ">>> Building $(PLAY_NAME):$(VERSION) ..."
	docker build -t $(PLAY_NAME):$(VERSION) $(PLAY_DIR)
	@echo ">>> Done: $(PLAY_NAME):$(VERSION)"

# ── Push targets ──────────────────────────────────────────────────────────────

push: push-asr push-tts push-play
	@echo ""
	@echo "=== All images pushed to $(PUSH_REPO) ==="

push-asr:
	@echo ">>> Pushing $(ASR_NAME):$(VERSION) ..."
	$(call tag_and_push,$(ASR_NAME),$(VERSION),$(ASR_NAME))
	@echo ">>> Done."

push-tts:
	@echo ">>> Pushing $(TTS_NAME):$(VERSION) ..."
	$(call tag_and_push,$(TTS_NAME),$(VERSION),$(TTS_NAME))
	@echo ">>> Done."

push-play:
	@echo ">>> Pushing $(PLAY_NAME):$(VERSION) ..."
	$(call tag_and_push,$(PLAY_NAME),$(VERSION),$(PLAY_NAME))
	@echo ">>> Done."

# Single-image push: make push-one=ASR|TTS|PLAY
# Maps short names to the full push target
push-one:
	@if [ "$(ONE)" = "ASR" ]; then \
		echo ">>> Pushing $(ASR_NAME):$(VERSION) ..."; \
		$(call tag_and_push,$(ASR_NAME),$(VERSION),$(ASR_NAME)); \
		echo ">>> Done."; \
	elif [ "$(ONE)" = "TTS" ]; then \
		echo ">>> Pushing $(TTS_NAME):$(VERSION) ..."; \
		$(call tag_and_push,$(TTS_NAME),$(VERSION),$(TTS_NAME)); \
		echo ">>> Done."; \
	elif [ "$(ONE)" = "PLAY" ]; then \
		echo ">>> Pushing $(PLAY_NAME):$(VERSION) ..."; \
		$(call tag_and_push,$(PLAY_NAME),$(VERSION),$(PLAY_NAME)); \
		echo ">>> Done."; \
	else \
		echo "ERROR: push-one requires ONE=ASR|TTS|PLAY"; \
		exit 1; \
	fi

# ── Clean ─────────────────────────────────────────────────────────────────────

clean:
	@echo ">>> Removing built images ..."
	docker rmi $(ASR_NAME):$(VERSION) $(ASR_NAME):latest 2>/dev/null || true
	docker rmi $(TTS_NAME):$(VERSION) $(TTS_NAME):latest 2>/dev/null || true
	docker rmi $(PLAY_NAME):$(VERSION) $(PLAY_NAME):latest 2>/dev/null || true
	@echo ">>> Done."

# ── Help ──────────────────────────────────────────────────────────────────────

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build          Build all 3 containers"
	@echo "  build-asr      Build ASR only"
	@echo "  build-tts      Build TTS only"
	@echo "  build-play     Build Playground only"
	@echo "  push           Push all 3 to ghcr.io"
	@echo "  push-asr       Push ASR to ghcr.io"
	@echo "  push-tts       Push TTS to ghcr.io"
	@echo "  push-play      Push Playground to ghcr.io"
	@echo "  push-one=ASR   Push ASR only (also: TTS, PLAY)"
	@echo "  clean          Remove built images"
	@echo "  help           Show this help"
	@echo ""
	@echo "Variables (override on command line):"
	@echo "  PUSH_REPO=<registry>   Target registry prefix (default: ghcr.io/cjlapao)"
	@echo "  VERSION=<tag>          Image version tag (default: git short SHA)"
	@echo ""
	@echo "Examples:"
	@echo "  make build                  # Build all images"
	@echo "  make build push             # Build & push all images"
	@echo "  make push-one=TTS           # Push TTS only"
	@echo "  make VERSION=v1.0.0 build   # Build with version tag"
	@echo "  make PUSH_REPO=ghcr.io/myuser build   # Custom registry"
