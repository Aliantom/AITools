<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Post-training quantization (PTQ) methods

> **TL;DR:** PTQ in 2026: GPTQ and AWQ are the 4-bit workhorses, rotation (QuaRot, SpinQuant) handles activations and sub-4-bit, codebooks and trellises (QuIP#, AQLM, EXL3) win at 2-3 bits.
> **Source:** Web research 2026-11-04 (arXiv, PyTorch, Unsloth, llama.cpp, Qualcomm AIMET, TensorFoundry) plus general knowledge, labelled  ·  **Project:** evolve-lab  ·  **Updated:** 2026-11-04

PTQ quantizes a trained model without further training, using at most a small calibration set and minutes to hours of compute. It is what produces almost every model file people download. Grouped by era and by what the method attacks. Evidence labels as in [Quantization glossary](quantization-glossary.md); source ids point to [Quantization sources](quantization-sources.md).

## 1. Baseline: round to nearest (RTN)

Pick a scale per tensor, channel or group, round each weight to the nearest integer. With group size 32 to 128 this alone gives a usable 8-bit model and a rough 4-bit one. Every method below is measured against it. HQQ is the modern "smart RTN": it solves for the scale and zero point that minimize the weight error under a robust loss, with no calibration data, in minutes. (MEMORY; HQQ listed as fast and newer in S38)

## 2. CNN-era PTQ (2019 to 2021)

These were built for per-tensor INT8 on phone chips and are the origin of the classic term list.

| Method | Year | Idea | Where it lives now |
|---|---|---|---|
| Data-Free Quantization (DFQ): cross-layer equalization + bias correction | 2019 | Equalize channel ranges across layers, correct the output mean shift, no data needed | AIMET; concept reborn as SmoothQuant |
| Outlier channel splitting | 2019 | Duplicate and halve outlier channels | Rare; revived inside a 2026 QAT paper (S30) |
| AdaRound | 2020 | Learn per-weight round up/down from layer output error | AIMET; concept reborn as GPTQ and AutoRound |
| BRECQ | 2021 | AdaRound at residual-block level, INT2 on ResNet | Block-wise reconstruction is now standard in LLM methods (OmniQuant, AutoRound) |

AIMET's recommended order is batch-norm folding, then CLE, then AdaRound, with bias correction used only when AdaRound is not. (VERIFIED S27, S28, S29)

## 3. LLM weight-only PTQ (W4A16 and below)

The decoding phase of an LLM is memory-bandwidth-bound, so shrinking weights speeds it up even while activations stay 16-bit. This is the most used class.

**GPTQ (2022).** Quantize one column at a time and push the rounding error onto the not-yet-quantized columns using the inverse Hessian of the layer's inputs (from Optimal Brain Quantization). Minutes for a 7B, hours for 70B on one GPU. Needs calibration data. The early-2025 benchmark found GPTQ (and QuIP) "consistently achieve satisfactory results across any model and bitwidth" and that combining QuaRot rotation with GPTQ sharply improves 2-bit. A 2025 paper gives provable bounds for GPTQ (called OPTQ there) and a successor Qronos. (VERIFIED S1, S8; mechanism MEMORY)

**AWQ (2023).** Observe that about 1% of channels are salient (they multiply large activations). Scale those channels up before quantization so their rounding error shrinks, and fold the inverse scale into the previous layer. Fast, robust at 4-bit, the usual choice for vLLM serving. Collapses at 2-bit on several Llama models in the 2025 benchmark. (VERIFIED S1, S38)

**HQQ (2023).** Half-quadratic solver for scale and zero point, no calibration data, very fast. Good 4-bit, respectable 3-bit. (S38 lists it as a newer, faster method; details MEMORY)

**SignRound / AutoRound (Intel, 2023 to 2025).** Learn rounding offsets and clipping per block with signed gradient descent over a few hundred steps. SignRoundV2 (Dec 2025) targets extreme low bits and claims to close much of the gap. Exports to GPTQ, AWQ and GGUF formats. (VERIFIED S3; mechanism MEMORY)

**OmniQuant (2023).** Learnable clipping and equivalent transformation, block-wise, still PTQ-sized compute. (MEMORY)

**SqueezeLLM (2023).** Sensitivity-weighted non-uniform codebook plus dense-and-sparse split that stores outliers separately in a sparse matrix. (MEMORY)

**D²Quant, ReQuant (2026).** Newer low-bit weight-only methods; titles only, not read. (S4, S6)

## 4. Weight-and-activation PTQ (W8A8, W4A4)

Needed for compute speedups on big batches and for the new FP8 and FP4 hardware. The obstacle is activation outliers.

**LLM.int8() (2022).** Keep the outlier dimensions in 16-bit, quantize the rest to INT8 vector-wise. Accurate, slow, the bitsandbytes 8-bit path. (MEMORY)

**SmoothQuant (2022).** Per-channel factor migrates the activation range into the weights before quantization (alpha controls how much). Enables static W8A8 with no quality loss on most models and is the standard INT8 and FP8 recipe. (MEMORY; S38 lists it)

**Rotation: QuaRot (2024), SpinQuant (2024), FlatQuant (2024).** Multiply the residual stream by a Hadamard matrix (QuaRot), or learn the rotation (SpinQuant), or learn affine transforms per layer (FlatQuant), so outliers are spread across channels and W4A4 becomes feasible, including 4-bit KV cache. The RMSNorm scale is folded into the next linear so the rotation is exact. A tensor-core Hadamard kernel (HadaCore) keeps the overhead small. (VERIFIED S1, S35, S36; mechanisms MEMORY)

**2026 rotation work.** PolarQuant (Mar 2026) normalizes blocks, applies a Walsh-Hadamard rotation, then quantizes with Gaussian-matched centroids, and reports that the rotation alone accounts for 98% of the improvement. HARP (EMNLP 2026) replaces fixed Hadamard mixing with a learnable orthogonal processor. A Jan 2026 paper ("Any Orthogonal Transform Will Do") argues the whole family works by range reduction. A survey-style paper (Aug 2026) lists learned-rotation methods DFRot, DartQuant, OSTQuant, ReSpinQuant and ParoQuant (learned Givens rotations plus per-channel scaling). Qift (Jun 2026) targets W2A4 with 4-bit KV on rotated models. (VERIFIED S31, S32, S34, S36, S7)

## 5. Sub-4-bit: codebooks, lattices, trellises

At 2 to 3 bits uniform grids waste too much; the winners encode groups of weights jointly.

| Method | Year | Idea | Result (self-reported) |
|---|---|---|---|
| QuIP | 2023 | Incoherence processing (random rotation) + adaptive rounding | First usable 2-bit |
| QuIP# | 2024 | Hadamard incoherence + E8 lattice codebook + fine-tuning | 2-bit Llama-2-70B near 3-bit quality |
| AQLM | 2024 | Additive multi-codebook vector quantization, learned | Strong 2-bit, slow kernels (large codebooks) |
| PV-Tuning | 2024 | Fine-tuning framework for any extreme-compression method | Improves AQLM and QuIP# further |
| QTIP | 2024 | Trellis-coded quantization replaces the codebook | 2-bit Llama-2-70B C4 ppl 5.48 vs QuIP# 5.71 vs AQLM 5.62; >2× faster than AQLM |
| EXL3 (ExLlamaV3) | 2025 | A QTIP variant with different regularization and packing, built to be fast to produce on consumer GPUs | The practical home option at 3 to 4 bpw; numbers via the repo's compare script |
| LLVQ | 2026 | Leech lattice vector quantization; "Spherical GPTQ" reduces the need for rotation | Paper only |
| QAM-W | 2026 | Joint 2D codebook with block-Hadamard and activation-aware scaling | Paper only |

(VERIFIED S39, S40, S33, S37; QuIP, QuIP#, AQLM, PV-Tuning details MEMORY)

## 6. The GGUF family (llama.cpp)

What Ollama runs. Not a paper lineage but the most used quantization on earth.

- **Legacy types** Q4_0, Q4_1, Q5_0, Q8_0: 32-weight blocks, one scale (and offset for _1). Q8_0 is near-lossless (+0.003 perplexity on a 7B in the llama.cpp docs) and is the reference quant. (VERIFIED S20)
- **K-quants** (Q2_K to Q6_K, with _S/_M/_L mixes): 256-weight super-blocks of 32-weight sub-blocks with quantized scales, plus a per-tensor type mix (the _M in Q4_K_M upgrades the most sensitive tensors). Do not need an imatrix but benefit from one. (VERIFIED S21, S22)
- **I-quants** (IQ1 to IQ4, _XXS/_XS/_S/_M/_NL): non-linear lookup grids for 2 to 4 bits. Need an imatrix. IQ4_XS saves about 400 MB on a 7B versus Q4_K_M at near-identical perplexity. Slower on CPU and Pascal-era GPUs. (VERIFIED S22)
- **imatrix**: importance weighting from calibration text; 10 to 30 percent lower perplexity loss claimed. (VERIFIED S20)
- **Unsloth Dynamic 2.0 (Apr 2025)**: picks a quantization type for every layer per model, calibrates on a 1.5M-token hand-curated chat set, and reports lower KL divergence and better MMLU and Aider scores than standard quants at similar size. Vendor numbers, not independently verified here. (VERIFIED S17, S18)
- **Measured error (Mistral-7B, Artefact2 gist, median KL vs FP16)**: Q6_K 0.0032, Q4_K_M 0.0075, IQ3_XXS 0.0330, IQ2_XS 0.1146. Compare numbers only within one source; the same quant gets different deltas across models and datasets. (VERIFIED S19)

## 7. Diffusion models

**SVDQuant (ICLR 2025 spotlight) + Nunchaku engine.** 4-bit weights and activations for FLUX.1 and other diffusion transformers. Outliers are absorbed by a 16-bit low-rank side branch (SVD of the residual) instead of being smoothed, and Nunchaku fuses the branch into the 4-bit kernel. Reported 3.5× less memory and 3.0× speedup over W4A16 on a 16 GB laptop 4090, better quality than NF4. INT4 works on Ampere; NVFP4 variant for Blackwell. (VERIFIED S47, S48)

## 8. What the benchmarks say

- **Benchmarking PTQ in LLMs (Feb 2025, S1):** across models and bit-widths GPTQ and QuIP are consistently fine; AWQ fails at 2-bit on several Llamas; rotation plus GPTQ rescues 2-bit; QuaRot and SpinQuant extend rotation to weight-activation quantization.
- **TensorFoundry field guide (Jun 2026, S38):** 8-bit near-lossless; 4-bit is the local default and "step up to 5 or 6 bits for reasoning or coding"; 3-bit works with rotation and codebooks but reasoning and coding suffer first; 2-bit needs QAT.
- **Unsloth (S17):** KL divergence, not perplexity, as the error metric; calibration data must match the use.
- **General pattern (MEMORY, consistent with the above):** small models (under 8B) lose more per bit than large ones; reasoning, math and code degrade before chat; long-context and multilingual degrade before English short-context.

## 9. Which PTQ method for what (summary)

| Goal | Use |
|---|---|
| Run a model locally with llama.cpp or Ollama | imatrix K-quant or Unsloth UD (Q4_K_M to Q6_K) |
| Serve with vLLM on Ampere or Ada | AWQ or GPTQ W4A16 with Marlin kernels; SmoothQuant W8A8 for throughput |
| Serve on Hopper or Blackwell | FP8 weights and KV; NVFP4 on Blackwell |
| Best quality at 3 bits or less on a home GPU | EXL3, or QuIP#/AQLM if the kernels exist for the model |
| Diffusion models | SVDQuant via Nunchaku |
| No calibration data at all | HQQ, or RTN with small groups at 8-bit |
| Below 3 bits for real use | Stop: use a QAT checkpoint instead ([Quantization QAT methods](quantization-qat-methods.md)) |
