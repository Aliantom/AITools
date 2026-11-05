<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Ollama mechanics for custom quants

> **TL;DR:** On this PC Ollama 0.40.10 turns flash attention on by itself for gemma4 but the KV cache is still f16 (OLLAMA_KV_CACHE_TYPE unset), it never quantizes GGUF on import (and its safetensors quantizer has no imatrix), and a custom quant goes in through a Modelfile with FROM for the weights, DRAFT for the multi-token-prediction draft, a second FROM for the vision projector, and RENDERER/PARSER gemma4.
> **Source:** Pass 3, 2026-11-04 evening: the installed Ollama 0.40.10 (ollama create --help, ollama show --modelfile gemma4:12b, the service log and drop-ins), Ollama's import docs, and 2026 write-ups on the DRAFT directive and speculative decoding  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Everything below was read on this PC on 2026-11-04 unless labelled otherwise.

## 1. What is running

- Ollama 0.40.10, system service, models on `/mnt/ai-storage/models/ollama`, drop-ins set `OLLAMA_MAX_LOADED_MODELS=1` and `OLLAMA_KEEP_ALIVE=2m`. (LOCAL)
- The server config line in the journal shows `OLLAMA_FLASH_ATTENTION:false` and `OLLAMA_KV_CACHE_TYPE:` empty, yet the runner log for gemma4 says `resolve_fused_ops: Flash Attention enabled` and `warmup: flash attention is enabled`. So flash attention is auto-enabled for this architecture on this GPU (consistent with the 2026 guides saying Ollama 0.30+ does this on Ampere and newer), and the KV cache runs at f16 because the type was never set. (LOCAL; S106)
- Speculative decoding is already on: the `gemma4:12b` Modelfile has a `DRAFT` line pointing at a 443 MiB draft blob and `PARAMETER draft_num_predict 3`. Guides say Ollama turned this on by default around 0.34 for Qwen and Gemma registry builds. (LOCAL; S120)

## 2. How Ollama quantizes, and does not

- `ollama create --quantize <level>` and `--draft-quantize` apply to **safetensors** inputs only. The official import docs say Ollama does not quantize GGUF models during import; quantize first with `llama-quantize`. (S112; `ollama create --help` LOCAL)
- Ollama's own quantizer has no importance-matrix option in its help or docs. Whether the registry's `gemma4:12b` Q4_K_M was made with one is unknown; its blob is 7,039 MiB against Unsloth's 6,789 MiB for the same type, so the tensor mix differs. Experiment 001 measures the installed blob directly, which settles the only question that matters. (LOCAL; hypothesis 4 in the experiment note)

## 3. Importing a custom quant with everything the registry model has

The installed Modelfile (secrets-free, read with `ollama show --modelfile gemma4:12b`) is the template:

```
FROM <weights .gguf>          # the quantized text model
DRAFT <mtp draft .gguf>       # multi-token-prediction draft (0.4 GiB at Q8_0 in Unsloth's MTP/ folder)
FROM <mmproj .gguf>           # vision projector; Ollama reads a second FROM as the projector
TEMPLATE {{ .Prompt }}
RENDERER gemma4
PARSER gemma4
PARAMETER draft_num_predict 3
PARAMETER temperature 1
PARAMETER top_k 64
PARAMETER top_p 0.95
```

Recipe for the experiment's winner:
1. Download `MTP/mtp-gemma-4-12b-it-Q8_0.gguf` (0.43 GiB) and `mmproj-F16.gguf` (0.16 GiB) from the Unsloth repo into the same models folder.
2. Write the Modelfile above with the chosen quant's path, `ollama create gemma4:12b-<quant> -f Modelfile`.
3. Verify with `ollama show --modelfile` that the draft and projector layers appear, then `ollama run` one image prompt and one tool-call prompt as smoke tests.
4. Score it with the quant-eval bundle ([Quantization evaluation methods for this PC](quantization-evaluation-methods-for-this-pc.md)) before any preset tag points at it.

Caveat: the "second FROM is the projector" reading comes from the installed Modelfile, not from documentation; if `create` rejects it, the import docs' wildcard form (`FROM /path/model-*.gguf`) and the GitHub docs are the next thing to check. (S112)

## 4. Settings worth changing (owner's call, service config)

A third drop-in, `92-kv-cache.conf`, with `Environment="OLLAMA_KV_CACHE_TYPE=q8_0"`, halves the KV cache for every model Ollama loads. Flash attention is a prerequisite and is already on for gemma4; for an architecture that does not support it, Ollama falls back to f16 silently, so check `ollama ps` memory after the change. Do it after experiment 001's KV arm reports, and back the drop-in up in workstation-config like the others. (S106; LOCAL for the drop-in layout)

`OLLAMA_CONTEXT_LENGTH` is 0 (default) in the server config; the `-cool16k` and `-agent16k` tags carry their own `num_ctx`. Unused context still reserves KV memory, so per-tag context is the right pattern and should stay.

## 5. Open items

- Confirm the projector `FROM` syntax on a scratch model before relying on it.
- Confirm the Ollama registry's quantization recipe (imatrix or not) from the Ollama GitHub repo; the experiment answers the practical question either way.
- The OpenAI-compatible endpoint returns no log-probabilities (needed by MMLU-style evals); `llama-server` from the same build does.
