<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Outliers and rotation deep dive

> **TL;DR:** Outliers are the root cause of quantization damage; the fixes evolved from splitting and equalizing channels to migrating ranges (SmoothQuant, AWQ) to rotating the whole residual stream (QuaRot, SpinQuant, ParoQuant), and 2026 work shows the rotation itself does nearly all the work.
> **Source:** Second research pass 2026-11-04: ParoQuant (ICLR 2026), SINQ, PolarQuant, HARP, 'Any Orthogonal Transform Will Do', transforms survey 2608.25188, LLM.int8, SmoothQuant, QuaRot, SpinQuant (memory, labelled)  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

## 1. Where outliers come from

- **Emergent outlier features.** Past roughly 6.7B parameters a handful of hidden dimensions take values up to 100× the typical magnitude in nearly every token. They are consistent across tokens and layers, which is why per-tensor activation quantization collapses at scale. (MEMORY: LLM.int8() paper)
- **Massive activations and attention sinks.** A few tokens (often the first) carry enormous activations that act as attention sinks; they sit in specific layers and dimensions. (MEMORY)
- **Weight outliers.** Less dramatic than activation outliers, but a few large weights per row still force large group scales at low bits. (MEMORY)
- **Why it matters.** A uniform grid's step size is range divided by levels. One value at 100 with everything else under 1 makes the step 100/15 at 4-bit, so every normal value rounds to zero. (MEMORY, arithmetic)

## 2. The fix lineage

| Generation | Method | Mechanism | Cost | Status |
|---|---|---|---|---|
| 2019 | Outlier channel splitting (OCS) | Duplicate the outlier channel, halve both copies | Wider layer | Historical; reused in a 2026 progressive QAT paper (S30) |
| 2019 | Cross-layer equalization | Rescale channels between consecutive layers (ReLU equivariance) | Free at inference | CNNs; AIMET |
| 2022 | LLM.int8() | Keep outlier dimensions in FP16, rest INT8 | Slow mixed kernel | bitsandbytes 8-bit |
| 2022 | SmoothQuant | Per-channel factor migrates activation range into weights (alpha 0.5 typical) | Free at inference (folded) | The standard W8A8/FP8 recipe |
| 2023 | AWQ scaling | Scale salient channels up before weight quantization | Free | Standard W4A16 |
| 2024 | QuaRot | Hadamard rotation of the residual stream; outliers spread across channels; exact by computational invariance | One fused Hadamard per block | W4A4KV4 research baseline |
| 2024 | SpinQuant | Learn the rotation (Cayley optimization) on a small set | Same at inference | Better than fixed Hadamard at W4A4 |
| 2024 | FlatQuant | Learn per-layer affine transforms that flatten distributions | Small | Strong W4A4 |
| 2025 | SINQ | Calibration-free; a second-axis scale (rows and columns) found by Sinkhorn normalization halves the perplexity gap of plain RTN | Free | Preprint (S101) |
| 2025 to 2026 | ParoQuant (ICLR 2026) | Learned pairwise Givens rotations plus per-channel scaling, cheap enough to run at AWQ speed; +2.4% average over AWQ on reasoning tasks | Small | Code for NVIDIA and Apple (S99) |
| 2026 | PolarQuant | Normalize blocks, Walsh-Hadamard rotate, Gaussian-matched centroids; rotation alone accounts for 98% of the gain | Small | Preprint (S31) |
| 2026 | HARP | Learnable orthogonal processor replacing fixed Hadamard, exact equivalence kept | Small | EMNLP 2026 (S32) |
| 2026 | "Any Orthogonal Transform Will Do" | Shows the mechanism is range reduction; the specific transform matters less than people assumed | n/a | Preprint (S34) |

(Pre-2025 rows MEMORY; 2025 to 2026 rows VERIFIED as cited; the transforms survey S36 lists DFRot, DartQuant, OSTQuant, ReSpinQuant as further learned-rotation variants)

## 3. Why rotation works (plain words)

A rotation mixes every channel into every other channel without changing what the next layer computes, as long as you apply the matching inverse rotation to that layer's weights (which you can fold in ahead of time). After mixing, one huge value becomes a small contribution to hundreds of values, so the per-tensor or per-group range shrinks and the values look Gaussian. Gaussian values quantize well on a uniform grid or, better, on a grid matched to a Gaussian (PolarQuant's centroids, NF4's levels). The only places you cannot fold the rotation are around nonlinearities (the attention softmax, the activation function), so the methods insert one online Hadamard there and pay for it with a tensor-core kernel (HadaCore). (MEMORY plus S31, S35)

## 4. What this changes in practice

- **For weight-only 4-bit (the local default):** rotation is a modest gain; AWQ, GPTQ or imatrix already handle weight outliers. ParoQuant is the first rotation method pitched as a drop-in AWQ replacement at AWQ speed. (VERIFIED S99)
- **For 2 to 3 bits:** rotation is required. The 2025 benchmark's 2-bit rescue of GPTQ by QuaRot is the clearest number. (VERIFIED S1)
- **For activations (W4A4, FP4 serving, 4-bit KV):** rotation is the enabling technology; every current W4A4 and TurboQuant-style KV method uses it. (VERIFIED S1, S41)
- **For this PC:** nothing here changes the Ollama path today. If ExLlamaV3 or vLLM with a rotation-quantized model is tried, expect better 3-bit behaviour than GGUF IQ3. The QuaRot/SpinQuant repos are research code; ParoQuant has usable kernels.

## 5. Open questions logged

- No independent replication of ParoQuant's +2.4% over AWQ was found.
- Whether rotation helps the Gemma 4 family specifically (its architecture has its own normalization layout) is unmeasured.
- SINQ's calibration-free result is attractive for quick local quantization but has no llama.cpp integration.
