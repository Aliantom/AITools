<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization: overview

> **TL;DR:** Start page for the quantization research folder: the one idea, a map of the notes, the bottom line for the RTX 3080, and how this folder is mirrored to Aliantom/AITools.
> **Source:** Owner request 2026-11-04: document everything about AI quantization (methods, PTQ/QAT, optimization, sources) and keep it mirrored to GitHub  ·  **Project:** evolve-lab  ·  **Updated:** 2026-11-04

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
| [Quantization KL experiment 001 (gemma4 12b)](quantization-kl-experiment-001-gemma4-12b.md) | The first measured test on this PC: pre-registration, scripts (`experiments/`), status and results. |
| [Quantization calibration deep dive](quantization-calibration-deep-dive.md) | How much calibration data, how long, which domain, imatrix practice, activation calibration methods. |
| [Quantization mixed precision and sensitivity](quantization-mixed-precision-and-sensitivity.md) | Measuring layer sensitivity, allocating bits, llama.cpp `--tensor-type`, KV and MoE variants. |
| [Quantization outliers and rotation deep dive](quantization-outliers-and-rotation-deep-dive.md) | Where outliers come from and the fix lineage from channel splitting to learned rotations. |
| [Quantization rounding methods deep dive](quantization-rounding-methods-deep-dive.md) | AdaRound to GPTQ to AutoRound; GPTQ as a lattice algorithm; which rounding for which bit-width. |
| [Quantization distillation and low-bit QAT deep dive](quantization-distillation-and-low-bit-qat-deep-dive.md) | ParetoQ's findings, distillation losses, recipes, what is feasible on this card. |
| [Quantization fine-tuning with quantized bases](quantization-fine-tuning-with-quantized-bases.md) | QLoRA, LoftQ, QA-LoRA, merge loss, and what finetune-lab should measure. |
| [Quantization and reasoning models](quantization-and-reasoning-models.md) | What quantization does to thinking models and agent workers. |
| [Quantization of MoE and multimodal models](quantization-of-moe-and-multimodal-models.md) | Expert-level mixed precision; how qwen3:30b-a3b could fit; vision towers. |
| [Quantization serving kernels and speculative decoding](quantization-serving-kernels-and-speculative-decoding.md) | Fast paths on Ampere, EXL3 numbers, speculative decoding and Gemma 4's built-in draft. |
| [Quantization evaluation methods for this PC](quantization-evaluation-methods-for-this-pc.md) | The three-layer eval stack (KL, evolve-lab task evals, deterministic tool-call set), what public harnesses can do over Ollama, what to build first. |
| [Ollama mechanics for custom quants](ollama-mechanics-for-custom-quants.md) | What Ollama 0.40.10 does and does not do (flash attention, KV type, no GGUF quantization, no imatrix) and the Modelfile recipe for importing a custom quant with draft and projector. |
| [Quantization primary paper reads](quantization-primary-paper-reads.md) | Full reads of ParetoQ, Quantization Hurts Reasoning, the Qwen3 study, Blueprints and DAG-Math: confirmations, corrections, tables. |
| [Quantization research log](quantization-research-log.md) | Dated log of what was researched, what was found, and the open questions to pick up next. |

## Bottom line for this PC (RTX 3080, 10 GB, Ampere)

1. Memory is the whole game. The card has no FP8 or FP4 tensor cores, so INT4 and INT8 kernels are what run.
2. Use imatrix or Unsloth "UD" GGUF files between Q4_K_M and Q6_K, Q8_0 for models of 4B or smaller.
3. Turn on flash attention and an 8-bit KV cache in Ollama. It halves the context cost at almost no quality loss.
4. Never spill layers to the CPU. A smaller quant that fits fully beats a bigger one that is offloaded.
5. Judge quants by KL divergence against the full-precision model, not by perplexity.
6. Quantization-aware training only matters at 4 bits and below. For fine-tuning here, QLoRA through Unsloth is the path.

Details and the commands are in [Quantization playbook for the RTX 3080](quantization-playbook-for-the-rtx-3080.md).

## Deep dives (second pass, 2026-11-04)

The rows above from the KL experiment downward were added in the second pass. Each ends with a "what to do here" section so findings can be pulled straight into finetune-lab or the Ollama setup.

## How to add research

1. Add or edit a note in this folder. Start it with front matter: `type: research`, `source`, `project`, `description` (the conclusion in one sentence), `updated: YYYY-MM-DD`.
2. Add every new source to [Quantization sources](quantization-sources.md) with its URL and an evidence label.
3. Add a dated entry to [Quantization research log](quantization-research-log.md): what was asked, what was found, what is still open.
4. Link notes with `wikilinks`. The mirror turns links inside this folder into relative GitHub links and links to other vault notes into plain text.
5. Keep secrets, personal data and large binaries out. The mirror runs the vault's secret guard but the folder is public once pushed.
6. The mirror runs hourly. To push now: `python3 -I "Machine/Scripts/mirror_research.py"`. To preview: add `--dry-run`.
