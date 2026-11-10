<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Calibration deep dive

> **TL;DR:** PTQ calibration saturates near 128 samples of 2048 tokens; domain match beats volume, Wikipedia-only flatters perplexity, and an imatrix should use use-case text and be evaluated elsewhere.
> **Source:** Second research pass 2026-11-04: calibration data studies (arXiv 2409.11055, 2510.10618, LLMC 2405.06001), llama.cpp imatrix docs and discussions, Unsloth docs  ·  **Project:** evolve-lab  ·  **Updated:** 2026-11-04

Calibration is the step where PTQ looks at data. It decides activation ranges (for activation quantization), importance weights (imatrix, AWQ scales, GPTQ Hessians) and, in rounding-optimization methods, the error the method minimizes. Getting it wrong is the most common way a "4-bit" model turns out worse than it had to be.

## 1. What calibration is used for, by method

| Method | What it collects | Data sensitivity |
|---|---|---|
| Static activation quantization (W8A8, TensorRT) | Per-tensor or per-channel activation min/max, percentiles or entropy-optimal clip | High: ranges must cover the deployment distribution |
| GPTQ | Inverse Hessian of layer inputs (XXᵀ) | Medium: a few hundred sequences; wrong domain costs a little |
| AWQ | Mean activation magnitude per input channel, to find salient channels | Medium |
| llama.cpp imatrix | Sum of squared activations per weight column, per tensor | Medium to high at low bits (I-quants need it) |
| AdaRound, BRECQ, AutoRound, OmniQuant | Layer or block output error to minimize | Medium; overfits with tiny sets |
| HQQ, SINQ, RTN | None | None, by design |

(MEMORY for the mechanisms; SINQ calibration-free VERIFIED S101)

## 2. How much data, how long, which domain

- **Sample count.** A Qwen3-8B GPTQ study found stable results at 128, 256 or 512 C4 samples and noticeable degradation under 64. A calibration-data study reports diminishing returns past 128 samples for most capabilities and occasional drops as samples are added, especially for AWQ and GPTQ. (VERIFIED S59, S55)
- **Sequence length.** Gains plateau or reverse past 2048 tokens for some tasks and methods. One reasoning-model study raised the length to 4096 to catch key-cache outliers in small reasoning models. (VERIFIED S55, S52)
- **Defaults in practice.** 128 sequences of 512 tokens from the Pile for AWQ; 128 samples of 2048 tokens from C4 for GPTQ. (VERIFIED S55)
- **Domain.** The LLMC benchmark saw about 0.2 perplexity gained on WikiText2 by calibrating on WikiText2 rather than the Pile, which is mostly a warning about evaluating on the calibration domain. Unsloth's position is stronger: Wikipedia-only calibration "overfits" perplexity tests, so they calibrate on 1.5M tokens of curated chat and evaluate on separate data. (VERIFIED S58, S17)
- **Capability preservation.** The "Preserving LLM Capabilities through Calibration Data Curation" line of work (Oct 2025) treats calibration as curation: pick samples that exercise the capabilities you want kept (instruction following, code, math), not generic web text. (VERIFIED S55, summary level)
- **Reasoning models.** For models with long chains of thought, calibration on reasoning traces rather than plain text is the emerging practice (QuantLRM uses fine-tuning signals; the reasoning study used longer sequences). (VERIFIED S54 title, S52)

## 3. imatrix practice (llama.cpp)

- Built by `llama-imatrix -m <model> -f <text> -o imatrix.gguf`; it runs the model over the text and accumulates per-column activation energy for every linear tensor. Newer builds write a GGUF-format imatrix. (VERIFIED S89 family; exact format MEMORY)
- Source model: the BF16 or F16 GGUF ideally; Q8_0 is accepted practice when the full model does not fit (its activations differ negligibly). (MEMORY; used in experiment 001)
- Calibration text in the wild: bartowski's `calibration_datav3.txt` (a mixed English, code and chat file, about 100 chunks of 512 tokens) is the de facto community default; its contents were not readable in this pass. (VERIFIED S107 mentions it; contents MEMORY)
- The imatrix matters most for I-quants and anything under Q4; at Q5 and above its effect is small but not zero. (VERIFIED S22, S20)
- Pitfall: calibration text that is too narrow (one language, one style) hurts other uses; the fix is mixing domains in proportion to real use, which is what `prep_eval_data.py` does for this PC (wiki, chat, code).

## 4. Activation calibration methods (for W8A8 and FP8 paths)

- **Min/max:** exact range, wrecked by one outlier.
- **Percentile:** clip at the 99.99th percentile; loses the outlier, keeps resolution.
- **MSE:** search the clip value that minimizes reconstruction error.
- **Entropy / KL (TensorRT INT8):** pick the clip that minimizes KL between the FP32 and quantized activation histograms.
- **Dynamic per-token:** no calibration; compute scales at run time per token (vLLM's default for INT8/FP8 activations); costs a reduction per token but is robust.
(MEMORY; consistent with S38's static vs dynamic note)

## 5. Rules for this PC

1. Calibrate on text shaped like the job: chat transcripts plus code for agents, the owner's domain for fine-tunes. Keep it disjoint from whatever you evaluate on.
2. 100 to 200 chunks of 2048 tokens is enough; more is wasted time.
3. Build the imatrix from the BF16 model if it fits, else Q8_0.
4. Never report a quant's quality from perplexity on its own calibration domain. Use KL on held-out text and, for the final call, a task eval.
5. For activation quantization (if vLLM with INT8 ever lands here), prefer dynamic per-token activations over static calibration unless throughput demands static.
