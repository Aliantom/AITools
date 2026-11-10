<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Primary paper reads

> **TL;DR:** Full reads confirmed the headline claims but fixed details: ParetoQ split is from one 125M model, GPTQ beats AWQ at 4-bit on Qwen3, 4-bit KV loses under 1%, blueprints lift small models 20 points.
> **Source:** Pass 4, 2026-11-04 evening: full fetches of ParetoQ (2502.02631), Quantization Hurts Reasoning v2 (2504.04823), An Empirical Study of Qwen3 Quantization (2505.02214), Blueprints for SLMs (2506.08669), DAG-Math (2510.19842); the fetch tool summarized the HTML, so numbers were copied from its extraction and the two long papers were read to the 100k-character mark  ·  **Project:** evolve-lab  ·  **Updated:** 2026-11-04

Each entry: what the full text confirmed, what it corrected in the earlier summary-level notes, and the numbers to keep. The earlier notes were patched where a number changed.

## 1. ParetoQ (Meta, 2025) — S67, now FETCHED

**Confirmed.** A learning transition between 2 and 3 bits: 3- and 4-bit models change 10 to 20% from initialization and recover near full-precision accuracy after about 10B fine-tuning tokens; binary, ternary and 2-bit change about 40%, saturate around 30B tokens and do not fully recover. Quantizer per bit-width: sign function at 1 bit; Stretched Elastic Quant (balanced levels, no forced zero) at 1.58 and 2 bits; LSQ at 3 and 4 bits. Learnable scales beat statistics-based ranges at every bit-width.

**Corrected.** The "about 10% QAT" rule comes from one experiment: MobileLLM-125M with a fixed 100B-token budget, peak at about 90% full-precision and 10% QAT, sharp drop above 90%. The text contains no tokens-per-parameter-byte statistic and no compute-scaling study; the abstract's claim is broader than the evidence in the body. Models are MobileLLM 125M to 1.5B and LLaMA-3 1B, 3B, 8B.

**Numbers.** LLaMA-3 8B, five-task average (FP 74.6): 2-bit 71.2, 1.58-bit 69.0, 1-bit 67.8; eight-task average (FP 70.2): 4-bit 69.0, 3-bit 68.4, 2-bit 67.0. MobileLLM-1B 2-bit 61.0 vs FP 62.1. Practitioner advice: start from a pretrained model; 90/10 split; learnable scales; SEQ at 2 bits, LSQ at 3 to 4; prefer 2-bit over ternary for hardware; quantize embeddings at 4 bits or the weight bit-width. Speedups need INT2 tensor cores, which Ampere lacks; the 2-bit GPU kernel only pays off on very large matrices.

## 2. Quantization Hurts Reasoning? (Liu et al., v2 Aug 2025) — S52, now FETCHED

**Confirmed.** W8A8 and W4A16 are effectively lossless; 3-bit and W4A4 are not; harder tasks and RL-trained reasoners lose more; aggressive settings lengthen outputs, most on the 1.5B model (figures only, no token counts). Models: DeepSeek-R1-Distill-Qwen 1.5B to 32B, Distill-LLaMA 8B and 70B, QwQ-32B, Qwen3-8B. Benchmarks: AIME-120, MATH-500, GSM8K, GPQA-Diamond, LiveCodeBench.

**Numbers to keep (average accuracy change vs BF16).**

| Setting | 1.5B | 7B | 14B | 32B |
|---|---|---|---|---|
| W4 AWQ | -2.1 | -2.1 | -1.1 | -0.4 |
| W3 AWQ | -18.6 | -6.3 | -6.2 | -3.9 |
| KV4 (KVQuant*) | -1.4 | -1.0 | -0.6 | -1.1 |
| KV3 (KVQuant*) | -12.3 | -5.9 | -5.4 | -4.0 |
| W8A8 (FlatQuant) | +0.2 | -0.2 | +0.2 | 0.0 |
| W4A4 (FlatQuant) | -10.9 | -11.8 | -3.0 | -2.9 |

Qwen3-8B: W4 AWQ -1.3, W3 AWQ -13.0, KV4 QuaRot 0.0, KV3 QuaRot -7.4. QwQ-32B: W4 AWQ -0.8. Task difficulty at 32B W4A4KV4: AIME -3.9, MATH-500 -1.2, GSM8K 0.0.

**Corrected and added.** KV-cache method choice is model-specific: QuaRot collapses on the small Qwen distills (-44 and -59 at KV3) where KVQuant* holds; the recommendation is QuaRot except for the 1.5B and 7B Qwens. Calibration domain matters for GPTQ: the 1.5B at 3-bit gains 9.8 points when calibrated on math data instead of WikiText2; other methods move under 1 point. "AWQ over GPTQ" is a simplicity call at comparable accuracy, not an accuracy win.

## 3. An Empirical Study of Qwen3 Quantization (2025; journal 2026) — S51, now FETCHED

**Confirmed.** 8-bit lossless; 4-bit good; 3-bit and below lose most of the model's advantage; Qwen3 degrades more than LLaMA-3 (C4 perplexity at AWQ w3g128: LLaMA3-8B 9.2 to 11.6; Qwen3-8B-Base 10.4 to 23.8), attributed to less parameter redundancy from stronger pretraining. Calibration: 128 C4 samples of 2048 tokens, group size 128. Methods: RTN, GPTQ, AWQ, SmoothQuant, BiLLM.

**Corrected.** The earlier note said "GPTQ 4-bit 14B loses 1% MMLU"; the table says 78.5 to 77.4, and GPTQ beats AWQ at 4-bit at every size. The third-party dispute over "69.3" is settled: 69.3 is AWQ 4-bit on the 8B, 73.4 is GPTQ.

**Numbers (MMLU 5-shot, post-trained models).**

| Size | FP16 | GPTQ 4 | AWQ 4 | AWQ 3 | GPTQ 2 |
|---|---|---|---|---|---|
| 0.6B | 47.1 | 44.0 | 42.1 | 25.0 | 23.5 |
| 1.7B | 60.0 | 55.7 | 52.5 | 26.7 | 25.6 |
| 4B | 69.7 | 67.6 | 64.1 | 31.5 | 24.4 |
| 8B | 74.7 | 73.4 | 69.3 | 33.2 | 25.0 |
| 14B | 78.5 | 77.4 | 75.9 | 47.7 | 28.5 |
| 32B | 81.2 | 80.6 | 78.0 | 54.9 | 28.1 |

For this PC: a 12B-class model at a good 4-bit should sit about 1 to 2 MMLU points under BF16; anything at 3 bits is a different, much worse model.

## 4. Blueprints and prompt template search for SLMs (ICML 2025) — D7, now FETCHED

**Confirmed.** A blueprint is a reusable step-by-step guide for a task category, generated once by GPT-4o from sampled solved examples in one of 12 styles, the best style picked on 10 training examples, optionally refined by one round of automatic prompt optimization, then inserted into every prompt (1-shot, no chain-of-thought). Template search varies shots (0 to 3), description position, blueprint on/off and CoT on/off (32 templates) by successive halving on 5 examples.

**Numbers.** Accuracy, CoT 3-shot vs blueprint with APO, for Mistral-7B / Phi-3-mini: BBH 0.530 / 0.686 to 0.559 / 0.738; GSM8K 0.347 / 0.780 to 0.480 / 0.840; MBPP 0.233 / 0.658 to 0.401 / 0.681 (blueprint without APO reached 0.440 on Mistral MBPP). The paper's "+20%" on MBPP is from 0.233 to about 0.44.

**Corrected.** It is not uniformly positive: APO lowered Mistral's MBPP from 0.440 to 0.401; template search lowered Phi-3's BBH (0.738 to 0.722) and GSM8K (0.840 to 0.820); on GPT-4o-mini MBPP the plain APO baseline won. The authors blame scoring on too few examples. Small models are 11 to 12% sensitive to blueprint style versus 3% for GPT-4o-mini, so style must be chosen per model. Costs: about 120 small-model calls for style selection, about 125 for APO, 310 for template search, per task category.

**For the local experiment:** keep the blueprint, skip template search, choose style on at least 50 dev items with the existing scorer, and expect gains mainly on code and multi-step tasks.

## 5. DAG-Math (ICLR 2026) — D2, now FETCHED

**Confirmed.** Reasoning is modelled as a DAG; the metric is logical closeness; code and benchmark at github.com/YuanheZ/DAG-MATH.

**Corrected.** The step format is Edge, then Parents, then Node ("Step 4 Edge: since ... Parents: Step 1. Node: log(x−1) requires x>1"), not id/justification/parents/conclusion. A DAG is logically closed when every non-final node has at least one outgoing edge; the score PRR is the expectation of (closed) × (correct final answer). Node correctness is assumed and checked with SymPy or a judge; acyclicity is assumed.

**Numbers.** Gemini-2.5-Flash on AIME 2025: PASS@1 52.4 without thinking, 64.0 with; PRR 17.0 and 35.9. About a 36-point gap between PASS@1 and PRR; correct outputs reach at most 80% logically closed nodes; incorrect graphs branch more. Models: Gemini 2.5 Flash and Flash-Lite, GPT-4.1 and mini, Qwen3-30B-A3B-Instruct.

**For this PC:** the format is cheap to require and to check (parents must exist, non-final nodes must be used); the finding that even right answers leave 20% of steps dangling means the checker should flag, not reject, dangling steps.
