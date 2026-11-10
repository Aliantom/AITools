<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Rounding methods deep dive

> **TL;DR:** Round-to-nearest is provably suboptimal; AdaRound to GPTQ to SignRoundV2 learn rounding to cut output error, GPTQ is Babai nearest-plane, and the frontier is better init and extreme-low-bit rounding.
> **Source:** Second research pass 2026-11-04: AdaRound and BRECQ (AIMET docs, arXiv 2102.05426), GPTQ-as-Babai (2507.18553), NeUQI (2505.17595), Provable PTQ/Qronos (2508.04853), SignRoundV2 (2512.04746), D²Quant, ReQuant  ·  **Project:** evolve-lab  ·  **Updated:** 2026-11-04

Given a scale, which integer should each weight become? "Nearest" treats every weight independently. Every method below uses the fact that the weights act together: an error in one can be cancelled by a deliberate opposite error in a neighbour, as judged by the layer's output on calibration data.

## 1. The lineage

| Method | Year | Unit of decision | How it decides | Scope |
|---|---|---|---|---|
| Round to nearest | always | each weight | closest grid point | everything |
| AdaRound | 2020 | each weight, up or down | learns a soft up/down variable by gradient descent on layer output MSE with a rectified-sigmoid regularizer that drives it to 0 or 1 | CNNs, AIMET |
| BRECQ | 2021 | each weight, per residual block | same objective at block granularity, using a Fisher-based second-order argument that blocks balance dependency and generalization | CNN INT2 |
| OBQ / GPTQ | 2022 | one column at a time | quantize a column, propagate its error to the remaining columns through the inverse input Hessian; GPTQ batches it per 128 columns with lazy updates | LLMs, the workhorse |
| SignRound / AutoRound | 2023 | block-wise | signed gradient descent on rounding offsets and clipping values, a few hundred steps per block | LLMs, Intel |
| OmniQuant | 2023 | block-wise | learnable clipping and equivalent transforms | LLMs |
| SignRoundV2 | Dec 2025 | block-wise | extends SignRound toward 2-bit with better initialization and search; targets closing the extreme-low-bit gap | LLMs (S3) |
| D²Quant | Feb 2026 | weight-only | "accurate low-bit post-training weight quantization", not read | LLMs (S4) |
| ReQuant | Aug 2026 | fixed grid | discrete refinement of an existing quantized model on its grid | LLMs (S6) |

(AdaRound, BRECQ, GPTQ, SignRound, OmniQuant mechanisms MEMORY with AIMET docs VERIFIED S27, S28, S29; 2025 to 2026 rows VERIFIED at title/summary level)

## 2. GPTQ, understood properly (2025 theory)

- "The Geometry of LLM Quantization: GPTQ as Babai's Nearest Plane Algorithm" (Jul 2025) shows GPTQ is exactly Babai's nearest-plane algorithm for the closest-vector problem on the lattice defined by the layer's input covariance. That gives error bounds and explains why column order and the Hessian damping matter. (VERIFIED S56, title level)
- "Provable Post-Training Quantization: Theoretical Analysis of OPTQ and Qronos" (Aug 2025) gives finite-sample guarantees and introduces Qronos, a successor with better error control. (VERIFIED S8, title level)
- Practical consequence: GPTQ's remaining weaknesses are initialization of the grid (scale and zero point) and the greedy order. NeUQI (2025) targets the initialization with a near-optimal uniform-grid parameter choice and reports gains at low bits. (VERIFIED S57, title level)

## 3. Which rounding method for which job

- **4-bit weight-only on a 7B to 14B model:** GPTQ, AWQ or imatrix K-quants all round well enough; the differences are within noise once calibration is right. (VERIFIED S1)
- **3-bit:** GPTQ with a rotation, AutoRound, or EXL3's trellis; plain nearest is unusable. (VERIFIED S1, S40)
- **2-bit:** rounding alone cannot save it; codebooks (QuIP#, AQLM), trellises (QTIP) or QAT are required; SignRoundV2 is the strongest pure-rounding attempt. (VERIFIED S3, S39)
- **GGUF:** llama.cpp's quantizer does an error-weighted search for block scales (and uses the imatrix as weights), which is a rounding optimization in all but name; there is no GPTQ-style propagation. (MEMORY)
- **On this PC:** AutoRound is the one method here that is both LLM-grade and runnable on a 10 GB card for a 12B model (it works block by block). It exports GGUF, so it could replace plain `llama-quantize` for a fine-tuned model if KL shows the plain quant is marginal. Not installed; tool-gatekeeper applies.

## 4. Bias correction, revisited

Rounding methods that minimize output error already remove the mean shift that bias correction targets, which is why AIMET says not to stack the two. In LLM practice bias correction survives only inside "zero-point" asymmetric formats (the zero point is a per-group bias) and in SmoothQuant-style equalization. (VERIFIED S28; rest MEMORY)
