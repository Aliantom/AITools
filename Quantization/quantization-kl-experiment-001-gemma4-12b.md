<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization KL experiment 001: gemma-4-12b-it on the RTX 3080

> **TL;DR:** Pre-registration of the first measured quantization test on this PC: eleven gemma-4-12b-it quantizations plus two KV-cache settings scored by KL divergence against a Q8_0 reference on held-out wiki, chat and code text; thresholds fixed in advance; status and results recorded below.
> **Source:** Owner request 2026-11-04: run the KL test on gemma4:12b quants. Pre-registered before any result was read.  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Scripts: `experiments/kl_gemma4_12b.sh`, `experiments/prep_eval_data.py`, `experiments/kl_report.py` (this folder). Working directory on disk: `/mnt/ai-storage/quant-eval/gemma-4-12b-it/`. Model files: `/mnt/ai-storage/models/gguf/gemma-4-12b-it/`.

## Question

Which quantization of the default local worker (`gemma4:12b`, Ollama's Q4_K_M) is the best trade between size and fidelity on this card, and does an importance matrix, Unsloth's dynamic mix, the QAT checkpoint, or an 8-bit KV cache change the answer?

## Design (fixed before running)

**Reference.** Q8_0 made here from Unsloth's BF16 GGUF (`unsloth/gemma-4-12b-it-GGUF`, 22.2 GiB). BF16 does not fit 10 GB of VRAM or 16 GB of RAM, so Q8_0 is the teacher; its own error against BF16 is about 0.001 KL on comparable models and is a floor every candidate shares.

**Candidates.**

| Name | Made how | Why it is in |
|---|---|---|
| Q6_K, Q5_K_M, Q4_K_M, Q3_K_M | `llama-quantize` from BF16, no imatrix | The standard ladder |
| Q4_K_M-imat, IQ4_XS-imat, Q3_K_M-imat, IQ3_M-imat | Same, with an imatrix built here from Q8_0 over `calib.txt` | Does calibration help, and by how much, per level |
| UD-Q4_K_XL | Downloaded, Unsloth Dynamic 2.0 | The vendor's per-layer mix |
| QAT-UD-Q4_K_XL | Downloaded, Unsloth's quant of Google's QAT checkpoint | Caveat below |
| ollama-Q4_K_M | The blob Ollama installed for `gemma4:12b` | What runs today |

**KV cache arm.** Q4_K_M-imat with flash attention and K/V at `q8_0`, and at `q4_0`, against its own default run.

**Eval text (`eval.txt`, about 26k tokens).** Three slices, none used for calibration: wikitext-2 test (40k chars), 150 ultrachat test conversations rendered as plain `User:`/`Assistant:` transcripts (40k chars), Python from llama.cpp's `gguf-py` (25k chars). Context 2048 for every run.

**Calibration text (`calib.txt`, about 60k tokens).** wikitext-2 train (offset so it does not overlap the test split), ultrachat test rows 2000 to 2599, C and C++ from llama.cpp `examples/`. Disjoint from the eval slices by construction.

**Metrics** from `llama-perplexity --kl-divergence`: mean KLD (with its standard error), median KLD, 99th percentile KLD, "same top p" (top-1 agreement), perplexity. Mean KLD and top-1 agreement decide; the others explain.

**Thresholds (from the literature before measuring).** Mean KLD at or below 0.02 and top-1 agreement at or above 95% is "safe"; 0.02 to 0.05 is "marginal, chat only"; above 0.05 is "damaged". Basis: Q4_K_M medians of 0.0075 (Mistral-7B, S19), Q4 means of 0.014 to 0.019 on Qwen3.5-27B (S94, S95), and the llama.cpp discussion that deviations above about 0.1 are plainly noticeable (S90). Differences between two candidates smaller than twice the larger standard error are ties.

**Hypotheses.**
1. Q6_K and Q5_K_M land under 0.01; Q4_K_M between 0.01 and 0.03; Q3_K_M above 0.05.
2. The imatrix cuts mean KLD by at least 10% at Q4_K_M and at least 25% at Q3_K_M (S20 claims 10 to 30% in perplexity terms).
3. UD-Q4_K_XL is within 10% of Q4_K_M-imat at a similar size (S94 found uploaders within 6% of each other at the same type).
4. ollama-Q4_K_M matches the no-imatrix Q4_K_M, because Ollama's conversion does not use one (assumption, to be checked against the result).
5. KV at q8_0 adds under 0.002 mean KLD; q4_0 adds more than 0.005.

**Caveat on the QAT candidate.** It is a different set of weights (Google fine-tuned them under fake quantization), so KL against the non-QAT reference measures distance from the original model, not quality. A low number still means "close to the original"; a high number does not mean "worse". Task accuracy is the right test for it, which this experiment does not do.

**Decision rule.** The default `gemma4:12b` should move to the smallest candidate that is "safe" on this mix if that candidate beats the installed blob by more than two standard errors. Changing the Ollama model is the owner's call; this note only recommends.

**Other limits.** Teacher-forced scoring on text is not generation; chat is rendered without Gemma's template; the Ollama blob may differ in metadata from Unsloth's conversion; 26k tokens cannot resolve differences below about 0.001; the thinking mode is not exercised.

## Status

- 2026-11-04 19:55: scripts written; downloads of BF16, UD-Q4_K_XL and QAT-UD-Q4_K_XL started; eval and calibration parquet files started.
- Blocked on building llama.cpp with CUDA: the session's permission mode refused to clone and build external code. Command for the owner (one line, about 10 to 15 minutes):

```
cd /mnt/ai-storage/tools && git clone --depth 1 https://github.com/ggml-org/llama.cpp llama.cpp-main && cd llama.cpp-main && cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=86 -DLLAMA_CURL=OFF -DGGML_NATIVE=ON && cmake --build build --config Release -j 10 --target llama-quantize llama-perplexity llama-imatrix llama-cli
```

- Then: `bash "<this folder>/experiments/kl_gemma4_12b.sh" all` (takes the GPU lock; about 1 to 2 hours, most of it quantizing and the Q8_0 reference pass).

## Results

(filled in by `kl_report.py` when the run completes)
