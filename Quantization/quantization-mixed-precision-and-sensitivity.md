<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Mixed precision and sensitivity

> **TL;DR:** Mixed precision works because layers differ in sensitivity by an order of magnitude; scalar Hessian proxies rank them poorly, output-error and Shapley-style measures do better, early layers and attention V/FFN-down tensors are usually the ones to keep high, and llama.cpp exposes all of this through --tensor-type.
> **Source:** Second research pass 2026-11-04: CoopQ, CASA, MXSens, NSDS, WINDQuant, MixLLM, KVTuner, GEMQ, llama.cpp --tensor-type discussion  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Not every tensor deserves the same bits. Mixed precision spends the bit budget where the model is sensitive. The questions are how to measure sensitivity, how to allocate under a size budget, and what granularity the kernels can run.

## 1. Why sensitivity varies

- Early layers amplify error through every layer after them; MXSens measures systematically higher sensitivity in early layers of LLaMA-3-8B and Mistral-7B, but in middle layers of Qwen1.5-7B, so the pattern is model-specific. (VERIFIED S64)
- Attention output and value projections and the feed-forward down projection carry disproportionate damage when squeezed, which is why llama.cpp's _M and _L mixes keep them one level higher. (MEMORY, consistent with the Q4_K_M design)
- Embeddings and the output head are cheap to keep at Q6_K or Q8_0 and expensive to get wrong; community recipes do this routinely. (VERIFIED S90)
- Outlier channels and "massive activations" concentrate in a few layers; those layers are the sensitive ones for activation quantization. (MEMORY)

## 2. How sensitivity is measured

| Measure | Idea | Verdict in the 2025 to 2026 literature |
|---|---|---|
| Weight norm / range | Cheap proxy | Weak (S61) |
| Hessian trace or top eigenvalue (HAWQ) | Curvature of the loss w.r.t. the layer | Collapsing a matrix's Hessian to one scalar ranks modules unreliably (S62) |
| Fisher information | Gradient-squared proxy for curvature | Used in LQ-LoRA's ILP allocation (S80 family); cheap, moderate |
| One-layer-quantized output error (MXSens) | Quantize one layer, measure output deviation | Captures position-dependent amplification (S64) |
| Shapley-style cooperative value (CoopQ / SPQE) | Progressive quantization to estimate inter-layer interactions | Best under 4 bits average, where independent scores fail (S61) |
| Data-free dual sensitivity (NSDS) | Numerical plus structural signals, no calibration | Competitive with calibrated metrics (S65) |
| End-to-end loss with cross-layer local search (CASA) | Score bit-width changes by actual loss, refine after knapsack | Fixes scalar-proxy errors (S62) |
| Learned policy (WINDQuant) | Reinforcement learning over column-level units under a global budget | Research stage (S5) |

Takeaway: measure sensitivity by output or loss impact with the other layers in place, not by a per-layer scalar. For a 12B model on this PC, "quantize one tensor type at a time and measure KL" is the honest version of the same idea, and llama.cpp can do it.

## 3. Allocation

- The budget problem is a multiple-choice knapsack: each layer picks a bit-width, total size must fit, maximize fidelity. Solvers: greedy by sensitivity per bit, ILP (LQ-LoRA), RL (WINDQuant), or global per-output-feature selection (MixLLM, MLSys 2026). (VERIFIED S62, S66, S5)
- Granularity options: per layer, per tensor type, per output channel (MixLLM), per column (MXSens assigns 4, 6 or 8 bits per column), per block. Finer is more accurate and needs kernels that can mix types inside one matmul; GGUF mixes per tensor, which every llama.cpp kernel supports. (VERIFIED S64, S66)
- KV cache has its own version: KVTuner (ICML 2025) picks per-layer KV precision and reports near-lossless 3.25-bit average on Llama-3.1-8B-Instruct. (VERIFIED S63)
- MoE: GEMQ and BitsMoE allocate per expert; activation-dependent importance (how often and how strongly an expert fires) beats uniform allocation by a wide margin at 2-bit on Qwen3-30B-A3B (47% vs 25% in BitsMoE's ablation). See [Quantization of MoE and multimodal models](quantization-of-moe-and-multimodal-models.md). (VERIFIED S85, S86)

## 4. Mixed precision in the tools you have

**llama.cpp `--tensor-type`.** `llama-quantize --tensor-type <name>=<type>` (repeatable) or `--tensor-type-file` sets the type for tensors by name pattern, so you can build your own mix: for example embeddings and output at Q8_0, attention V and FFN down at Q6_K, everything else Q4_K_S. A community recipe thread evaluated mixes by mean-squared deviation from BF16 and found deviations above about 0.1 noticeable. Known bug: an override that equals the global type was ignored in some builds (issue #22544); a recent build is needed. (VERIFIED S89, S90, S91)

**Unsloth Dynamic 2.0** is this applied per layer per model with their own sensitivity pass; UD-Q4_K_XL is roughly "Q4_K_M with the sensitive tensors raised". (VERIFIED S17)

**Prebuilt mixes.** Q4_K_M versus Q4_K_S versus Q4_K_L differ only in which tensors are raised. IQ4_XS is uniform I-quant at 4.25 bpw. (MEMORY)

**vLLM / compressed-tensors** supports per-layer schemes (keep `lm_head` and some layers in BF16, the rest INT4/INT8); GPTQModel and llm-compressor expose "ignore" lists for that. (MEMORY)

## 5. What to try here

1. Build Q4_K_S with overrides (`token_embd`, `output` at Q8_0; `attn_v`, `ffn_down` at Q6_K) and compare it to Q4_K_M-imat and UD-Q4_K_XL by KL. This is the "roll your own UD" test.
2. Measure per-tensor-type sensitivity for gemma-4-12b: quantize one tensor family to Q3_K at a time, everything else Q8_0, record mean KL. Eight runs give the model's sensitivity map, which is also a useful diagram (see the diagramming notes).
3. Use that map to choose the smallest mix that stays "safe" under experiment 001's thresholds.
