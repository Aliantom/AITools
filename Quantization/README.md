<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization: overview

> **TL;DR:** Start page for the quantization research folder: the one idea, a map of the notes, the bottom line for the RTX 3080, and how this folder is mirrored to Aliantom/AITools.
> **Source:** Owner request 2026-11-04: document everything about AI quantization (methods, PTQ/QAT, optimization, sources) and keep it mirrored to GitHub  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

This folder holds everything researched about quantizing AI models: what the methods are, which are current, what the evidence says, and what to do on this PC. It is written so a self-taught developer can follow it, with the "why" spelled out.

**Where this lives.** The vault copy (`Machine/Research/Quantization/`) is the source of truth. The folder is converted to GitHub-flavoured Markdown and pushed to `Aliantom/AITools` under `Quantization/` by `Machine/Scripts/mirror_research.py`, which the `research-mirror` user timer runs hourly. Edit here, never in the repo folder: the repo copy is overwritten on every run. See the section "How to add research" below.

## The one idea to remember

A trained model stores every weight as a 16-bit float. Quantization stores each weight as a small integer plus a shared scale, so 4-bit weights take a quarter of the memory and move through the GPU's memory bus four times faster. It works because the loss surface is flat near a trained minimum: small rounding errors barely move the output. It fails because of **outliers**: a few huge values force a large scale, and then every normal value gets rounded coarsely. Almost every method in this folder is a different way to tame outliers, choose rounding better, or teach the model to live with the rounding.

## Map of this folder

| Note | What it answers |
|---|---|
| [Quantization glossary](quantization-glossary.md) | Every term, including the classic list (uniform, non-uniform, per-channel, group, mixed precision, calibration, LSQ, AdaRound, bias correction, cross-layer equalization, outlier channel splitting, distillation, batch-norm folding) and its LLM-era descendant. |
| [Quantization PTQ methods](quantization-ptq-methods.md) | Post-training quantization: CNN-era methods, LLM weight-only methods, weight-and-activation methods, rotation, sub-4-bit codebooks and trellises, the GGUF family, diffusion models, and what benchmarks found. |
| [Quantization QAT methods](quantization-qat-methods.md) | Quantization-aware training: how it works, when it pays off, the 2025 to 2026 recipes (torchao, Gemma QAT, ParetoQ, BitNet, NVIDIA Model Optimizer), and quantized fine-tuning (QLoRA). |
| [Quantization formats, GGUF and KV cache](quantization-formats-gguf-and-kv-cache.md) | Number formats (INT, FP8, FP4, MXFP4, NVFP4, NF4), which hardware runs which, GGUF type table with measured error, memory arithmetic, and KV cache quantization. |
| [Quantization playbook for the RTX 3080](quantization-playbook-for-the-rtx-3080.md) | What to do on this PC: quant choice by model size, VRAM budget, Ollama settings, llama.cpp commands, evaluation protocol, fine-tuning path. |
| [Quantization tools and repos](quantization-tools-and-repos.md) | Every library and repo, what it is for, its status, and whether it runs on Ampere. |
| [Quantization sources](quantization-sources.md) | The source register: every paper, doc and post used, with a URL and an evidence label. |
| [Quantization research log](quantization-research-log.md) | Dated log of what was researched, what was found, and the open questions to pick up next. |

## Bottom line for this PC (RTX 3080, 10 GB, Ampere)

1. Memory is the whole game. The card has no FP8 or FP4 tensor cores, so INT4 and INT8 kernels are what run.
2. Use imatrix or Unsloth "UD" GGUF files between Q4_K_M and Q6_K, Q8_0 for models of 4B or smaller.
3. Turn on flash attention and an 8-bit KV cache in Ollama. It halves the context cost at almost no quality loss.
4. Never spill layers to the CPU. A smaller quant that fits fully beats a bigger one that is offloaded.
5. Judge quants by KL divergence against the full-precision model, not by perplexity.
6. Quantization-aware training only matters at 4 bits and below. For fine-tuning here, QLoRA through Unsloth is the path.

Details and the commands are in [Quantization playbook for the RTX 3080](quantization-playbook-for-the-rtx-3080.md).

## How to add research

1. Add or edit a note in this folder. Start it with front matter: `type: research`, `source`, `project`, `description` (the conclusion in one sentence), `updated: YYYY-MM-DD`.
2. Add every new source to [Quantization sources](quantization-sources.md) with its URL and an evidence label.
3. Add a dated entry to [Quantization research log](quantization-research-log.md): what was asked, what was found, what is still open.
4. Link notes with `wikilinks`. The mirror turns links inside this folder into relative GitHub links and links to other vault notes into plain text.
5. Keep secrets, personal data and large binaries out. The mirror runs the vault's secret guard but the folder is public once pushed.
6. The mirror runs hourly. To push now: `python3 -I "Machine/Scripts/mirror_research.py"`. To preview: add `--dry-run`.
