<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Fine-tuning with quantized bases

> **TL;DR:** QLoRA loses quality when merged weights are re-quantized; LoftQ and QA-LoRA avoid this, so finetune-lab should measure its own merge loss by KL divergence.
> **Source:** Second research pass 2026-11-04: LoftQ (2310.08659), QA-LoRA, LQ-LoRA, LQER (2402.02446), Scale-QLoRA (2609.04526), LoRA review (2501.00365), LoRA redux (2604.21905), QLoRA (memory)  ·  **Project:** evolve-lab  ·  **Updated:** 2026-11-04

This is the family finetune-lab lives in. The base model is quantized to fit the card; small trainable adapters learn the task; the question is what you deploy afterwards and how much the quantization costs you at each step.

## 1. The methods

| Method | Year | Base during training | What is learned | Deployment | Key claim |
|---|---|---|---|---|---|
| QLoRA | 2023 | NF4 (4-bit normal-float), double-quantized scales, paged optimizers | LoRA in BF16 | merge into BF16 and re-quantize, or serve base-4-bit plus adapter | 65B fine-tune on one 48 GB GPU (MEMORY) |
| LoftQ | 2023 | any low-bit | LoRA initialized by alternating quantize-and-refit so that Q(W)+AB ≈ W at step 0 | fuse into FP32/BF16 | beats QLoRA at every precision; at 2 bits QLoRA fails to converge while LoftQ reaches perplexity 7.85 (S80) |
| QA-LoRA | 2023 | INT4 with group-wise pooling in the adapter | pooled LoRA | merged model stays INT4 with no loss | integer-friendly merge (S80 summary) |
| LQ-LoRA | 2023 | mixed-precision chosen by ILP with Fisher information | low-rank plus quantized decomposition | as trained | memory-targeted allocation (S80 summary) |
| LQER | 2024 | low-bit plus low-rank error reconstruction (not training) | SVD of quantization error | low-bit plus a thin BF16 branch | PTQ repair, same idea as SVDQuant for diffusion (S82) |
| Scale-QLoRA (Sep 2026) | 2026 | native MXFP4 (microscaled 4-bit) | adapters merged by changing only the block scales, leaving quantized codes unchanged | bit-exact 4-bit | dequant-then-fuse merge scored 14.96 vs 5.77 unmerged on its perplexity metric; scale-only merge avoids it (S81, single preprint, unreplicated) |
| Unsloth QLoRA | 2024 onward | NF4 via bitsandbytes | LoRA | export to GGUF (merged) | 2× speed, less memory; used by finetune-lab (S13) |

## 2. Where the loss actually happens

1. **Base quantization (before training).** NF4 costs about the same fidelity as a Q4 GGUF; the adapter partially compensates because it trains against the quantized base. (MEMORY; LoftQ shows the compensation can be designed in, S80)
2. **Merge.** Merging BF16 adapters into dequantized BF16 weights is exact. Re-quantizing the merged BF16 model to 4-bit is where the damage is: the 2026 preprint measures a large gap for the dequant-then-fuse-then-requant path. (VERIFIED S81; the size of the gap depends on the format and may be overstated by one preprint)
3. **Serving base-4-bit plus adapter unmerged** avoids the re-quantization loss but costs an extra matmul per layer; vLLM supports it (multi-LoRA), Ollama does not for arbitrary adapters in a clean way. (MEMORY)

## 3. What finetune-lab should do

- **Measure the merge loss.** After each run: KL of (merged BF16 → Q8_0) versus (merged BF16 → Q4_K_M-imat) on held-out task text, exactly as experiment 001 does for the base model. If Q4's KL is under the "safe" line, the plain path is fine; if not, the next options are, in order: imatrix built from the fine-tuning data; a Q5_K_M or Q6_K export; LoftQ-style initialization on the next run; a short Int4 QAT phase (see the distillation note).
- **Prefer LoftQ initialization** when the target is 3 bits or the model is small (3B). PEFT supports `loftq_config`. (MEMORY)
- **Do not chase Scale-QLoRA yet**: it targets MXFP4 hardware this PC lacks and is one unreplicated preprint.
- **Keep the prereg discipline**: the `ftlab-p001` protocol's Ollama-versus-in-process disagreement check (Decisions 2026-11-03) is already a merge-loss check in disguise; the KL tooling makes it quantitative.
