<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization of MoE and multimodal models

> **TL;DR:** MoE models quantize per expert: rarely-used experts can go to 2 bits while hot experts stay at 4 to 8, which is how qwen3:30b-a3b could fit this card (it currently spills 4 GB to swap); multimodal models need the vision tower kept at higher precision and modality-aware expert allocation.
> **Source:** Second research pass 2026-11-04: GEMQ (2605.23078), BitsMoE (2606.00079), TileQ (2605.09281), MODE (2606.17118), Unsloth Dynamic 2.0 docs, torchao MoE QAT RFC  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Two of the installed models are special cases: `qwen3:30b-a3b` is a mixture of experts (30.5B parameters, 3.3B active, 128 experts per layer across 48 layers, 8 active per token) and `gemma4` has a vision projector and audio. (Qwen3 architecture figures VERIFIED S85; gemma4 capabilities from `ollama show`)

## 1. MoE

**Why MoE is different.** Only a few experts run per token, so memory is dominated by experts that are idle most of the time. That makes expert-level mixed precision attractive: quantize cold experts hard, keep hot and sensitive experts at higher precision. Routing weights and the shared attention layers are small and should stay at 8-bit. (MEMORY, consistent with the sources)

| Method | Year | Idea | Result (self-reported) |
|---|---|---|---|
| Unsloth Dynamic (v1) | 2025 | Per-layer type selection; originally MoE-only (DeepSeek-R1 1.58-bit) | Made 671B runnable at home (S17) |
| GEMQ | May 2026 | Global expert-level mixed precision across all layers under one budget, evaluated on Qwen3-30B-A3B among others | Better than per-layer uniform at matched size (S85) |
| BitsMoE | Jun 2026 | Spectral-energy-guided bit allocation; ablation shows activation-dependent importance (how experts actually fire) matters: 47.2% accuracy at 2-bit versus about 25% for uniform allocation on Qwen3-30B-A3B | (S86) |
| TileQ | May 2026 | Low-rank correction for expert weights stored with 2D tiling; overhead about 0.04 bits/weight versus 0.43 for per-expert low-rank | (S87) |
| torchao MoE QAT RFC | 2026 | MXFP8/MXFP4/NVFP4 fake-quant for expert weights; DeepSeek-V4 reportedly does MXFP4 QAT on experts | (S15) |
| MODE | Jun 2026 | Modality-decomposed expert-level mixed precision for multimodal MoEs (Qwen3-VL-30B-A3B, Kimi-VL-A3B): within 3% of BF16 at 3-bit average | (S88) |

**Practical options in llama.cpp.** `--tensor-type` patterns can target expert tensors (`ffn_*_exps`) separately from attention and shared layers, so a hand-built mix (experts IQ3 or IQ2, attention Q6_K, embeddings Q8_0) is possible today; Unsloth's UD quants of MoEs do this automatically. llama.cpp can also keep experts in system RAM while attention runs on the GPU (`--override-tensor`), which suits a 10 GB card with 16 GB of RAM poorly but a RAM upgrade well. (VERIFIED S89, S90 for the override flags; MoE offload practice MEMORY)

**For `qwen3:30b-a3b` here.** The installed 18 GB Q4 spills about 4 GB to swap (Local models page). Options, cheapest first: (1) Unsloth UD-IQ2_M or UD-Q2_K_XL style quant, about 10 to 11 GB, chat-grade; (2) a custom mix with experts at IQ3_XXS and attention at Q5_K_M, about 12 to 13 GB, still needs CPU offload of some experts; (3) the RAM upgrade the hardware note allows (32 GB) with experts in RAM. Option 1 is the only one that fits VRAM today and should be KL-tested like experiment 001 before replacing the current tag.

## 2. Multimodal

- **Vision towers are small and sensitive.** The gemma4 projector is 52M parameters (167 MiB in Ollama); quantizing it buys nothing and risks image understanding, so Ollama and llama.cpp keep `mmproj` at F16 or BF16 (the Unsloth repo ships mmproj at BF16/F16/F32 only). (VERIFIED S108 listing; practice MEMORY)
- **Language side quantizes as usual**, but image tokens have different activation statistics than text tokens, so calibration for activation quantization should include image-conditioned sequences. (MEMORY)
- **Modality-aware allocation (MODE)** finds that experts specialize by modality in multimodal MoEs and allocates bits accordingly. (VERIFIED S88)
- **Diffusion** is covered in the PTQ note (SVDQuant).

## 3. Open questions

- No measured KL or task numbers exist here for the MoE options above; they belong in a follow-up experiment once experiment 001's tooling works.
- Whether gemma4's audio path survives 4-bit language weights is unmeasured anywhere I found.
