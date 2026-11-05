<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Formats, GGUF types and the KV cache

> **TL;DR:** Number formats and hardware: Ampere runs INT4/INT8 only (no FP8/FP4); GGUF Q4_K_M is about 4.85 bpw with median KL 0.0075 on Mistral-7B; KV cache for an 8B costs 128 KB per token at FP16 and halves at q8_0; TurboQuant reaches about 3.5 bits per KV value with no loss.
> **Source:** Web research 2026-11-04 (TensorFoundry field guide, llama.cpp docs, Artefact2 KL table, TurboQuant coverage) plus general knowledge, labelled  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

## 1. Number formats

| Format | Bits | Structure | Where native | Notes |
|---|---|---|---|---|
| FP16 / BF16 | 16 | float | every modern GPU | Reference precision; BF16 has FP32's range |
| INT8 | 8 | integer + scale | Turing and later, CPUs | Near-lossless for weights and most activations |
| FP8 E4M3 / E5M2 | 8 | float | Hopper, Ada, Blackwell | Server default for weights and KV; not on Ampere |
| INT4 | 4 | integer + group scale | kernels only (Marlin, ExLlama, llama.cpp) | The local default; runs on Ampere |
| FP4 E2M1 | 4 | float | Blackwell | Only 16 values; always paired with block scales |
| MXFP4 | ~4.25 | FP4 with an 8-bit power-of-two scale per 32 | Blackwell | gpt-oss ships in it; OCP standard |
| NVFP4 | ~4.5 | FP4 with an FP8 E4M3 scale per 16 plus a tensor scale | Blackwell | More accurate than MXFP4 per NVIDIA; per-16 scaling |
| NF4 | 4 | 16 normal-distribution levels, double-quantized scales | bitsandbytes (any CUDA GPU) | QLoRA base weights; slow for inference |
| INT3, INT2 | 3, 2 | integer + group scale | kernels only | Need rotation, codebooks or QAT to be usable |
| Trellis / codebook | 2 to 4 | index into learned structure | ExLlamaV3, QuIP#, AQLM kernels | Best quality per bit, custom kernels |

(VERIFIED S38 for the format list and block sizes; hardware mapping MEMORY plus S38)

**What the RTX 3080 (Ampere, SM 8.6) can do.** INT8 and INT4 tensor-core math, FP16/BF16 (BF16 at reduced rate), no FP8, no FP4. Every "FP8" or "NVFP4" headline is for other cards. The useful kernels here are llama.cpp CUDA (all GGUF types), Marlin and ExLlamaV2/V3 (INT4 and trellis for Transformers and vLLM), bitsandbytes NF4 (fine-tuning), and Nunchaku INT4 (diffusion). (MEMORY; Nunchaku INT4 on Ampere VERIFIED S48)

## 2. GGUF types (llama.cpp, Ollama)

Approximate bits per weight and the Mistral-7B median KL divergence from the Artefact2 table. KL is against FP16; smaller is better; 0.01 is a good rule-of-thumb ceiling for "indistinguishable in use".

| Type | bpw (approx.) | Median KL (Mistral-7B) | Note |
|---|---|---|---|
| Q8_0 | 8.5 | ~0 (+0.003 ppl on 7B) | Reference quant; use for small models |
| Q6_K | 6.56 | 0.0032 | Near-lossless |
| Q5_K_M | 5.69 | ~0.005 | Good for code and reasoning |
| Q4_K_M | 4.85 | 0.0075 | The default |
| IQ4_XS | 4.25 | ~0.01 | Needs imatrix; about 400 MB smaller than Q4_K_M on a 7B at near-same quality |
| Q3_K_M | 3.9 | ~0.02 | Noticeable |
| IQ3_M / IQ3_XXS | 3.7 / 3.1 | ~0.02 / 0.0330 | Needs imatrix; last stop before damage shows in reasoning |
| IQ2_XS | 2.4 | 0.1146 | Chat only, and only for big models |

(VERIFIED S19 for the KL figures marked exactly; other cells approximate MEMORY, and bpw varies by model)

Caveats from the sources: the same quant shows different perplexity deltas in different tables (Q4_K_M at +0.05 in one and +0.18 on Llama-3-8B in another), so compare numbers only within one source and ideally measure on your own model. (VERIFIED S19, S20, S25)

**Size arithmetic.** File size ≈ parameters × bpw / 8. An 8B at Q4_K_M ≈ 4.9 GB, Q5_K_M ≈ 5.7 GB, Q6_K ≈ 6.6 GB, Q8_0 ≈ 8.5 GB. A 12B at Q4_K_M ≈ 7.3 GB (gemma4:12b in Ollama measures 8.0 GB loaded). A 14B at Q4_K_M ≈ 9.0 GB. (MEMORY; gemma4 figure from the vault's Local models page)

## 3. KV cache

Every generated token appends a key and a value vector per layer per KV head. Memory per token at FP16:

```
bytes/token = 2 (K and V) × layers × kv_heads × head_dim × 2 bytes
Llama-3-8B: 2 × 32 × 8 × 128 × 2 = 131072 bytes = 128 KB/token
  8k context  = 1.0 GB      32k context = 4.0 GB      128k context = 16 GB
```
(MEMORY; the TensorFoundry guide gives a 70B at 128k needing about 40 GB, S38)

Models with grouped-query attention (most 2024+ models) have few KV heads, which is why the numbers above are tolerable. Older or MHA models cost 4 to 8× more.

**Options, cheapest first:**
- **q8_0 K and V in llama.cpp and Ollama.** Halves the cache. Needs flash attention on. Quality loss is reported as negligible in community testing; I found no formal measurement in this session (open question in [Quantization research log](quantization-research-log.md)). Ollama: `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q8_0`. (MEMORY for the settings; quality gap noted VERIFIED S41)
- **q4_0 K and V.** Quarter of the cache; measurable degradation on long-context and reasoning tasks. Use only to fit.
- **FP8 KV (vLLM, SGLang).** The server default on Hopper/Blackwell; "roughly doubles the context or batch that fits". Not on Ampere. (VERIFIED S38, S41)
- **KIVI (2024).** 2-bit, keys per-channel and values per-token, asymmetric. Research kernels. (VERIFIED S41 summary; paper MEMORY)
- **TurboQuant (Google, ICLR 2026).** PolarQuant-style rotation plus a 1-bit sketch (QJL) to correct inner products. Reported quality-neutral at about 3.5 bits per value and marginal loss at 2.5, at least 6× reduction. vLLM merged `--kv-cache-dtype turboquant` presets in April 2026; llama.cpp has an open PR proposing `tbq3_0` and `tbq4_0` cache types (issue #20977, PR #21089, status as of mid-2026). An unofficial open-source implementation exists. (VERIFIED S41, S42, S43)
- **Rotation-based 4-bit KV (QuaRot, SpinQuant, Qift)** as part of a full W4A4KV4 pipeline. (VERIFIED S1, S7)

Rule for this PC: q8_0 KV on by default; q4_0 only to fit a context that otherwise will not; wait for the llama.cpp TurboQuant types to land before relying on them.

## 4. Activations and the compute side

Weight-only quantization dequantizes to FP16 in the kernel and multiplies in FP16, so it saves memory and bandwidth but not compute. Activation quantization (W8A8 INT8 on Ampere, FP8 on Hopper, FP4 on Blackwell) is what doubles throughput at large batch. For a single user on one card the decode step is bandwidth-bound, so weight-only 4-bit already gives most of the speed. Prompt processing (prefill) is compute-bound and is where INT8 activations would help on Ampere, but few local stacks do it. (MEMORY, consistent with S38)
