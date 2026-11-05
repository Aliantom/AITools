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

## Amendment 1 (2026-11-04 21:40, before any KL result was read)

**Observation during the run.** Sanity perplexities on the eval slices with two known-good 4-bit files (Unsloth UD-Q4_K_XL and the Ollama blob): wiki slice 751 and 626, plain chat transcripts 48, code 15. A control model (qwen2.5-coder 7B) scores 9.1 on the same wiki slice. GGUF metadata is sane (BOS added, final logit softcapping 30, sliding-window pattern present), a 512-token context changes nothing (600), and greedy generation is coherent. Formatting the chat slice in Gemma's own turn template lowers it from 48 to 30. Reading: the model runs correctly; a heavily post-trained thinking model is simply far from raw Wikipedia text, so the wiki slice would contribute huge, noisy per-token KL values and dominate the mixed-text mean.

**Change.** Run A (the pre-registered mixed text) completes and is reported as planned. Run B (`experiments/kl_slices.sh`) adds per-slice KL on three files: the chat slice in Gemma's template, the code slice, and the wiki slice, each with its own Q8_0 reference. The decision rule now reads: the "safe" thresholds apply to the chat-template and code slices; the wiki slice is reported as a stress domain and does not decide. Hypotheses and thresholds are otherwise unchanged.

**Why this is allowed.** No KL number had been produced or read when the amendment was written; only perplexity sanity checks were.

## Amendment 2 (2026-11-04 21:55, after run A, before any run B result)

**Run A result (mixed text, as pre-registered).** Not decision-grade. Mean KLD: Q6_K 0.50, Q5_K_M 0.74, UD-Q4_K_XL 0.77, installed Ollama Q4_K_M 0.83, Q4_K_M-imat 0.88, Q4_K_M plain 1.40, Q3_K_M-imat 1.58, IQ3_M-imat 1.62, Q3_K_M plain 2.39, QAT-UD-Q4_K_XL 2.95 (a different model, as the caveat said). Top-1 agreement 81% down to 49%. Full table in `results/REPORT.md` on the NVMe. These values are two orders of magnitude above what Q6_K costs on normal text, which prompted the checks below.

**Diagnostics.**
1. Q8_0 scored against its own reference at the same GPU split: KL 0.000, top-1 99.99% (the pipeline is sound).
2. Q8_0 scored against its own reference with a different split (20 instead of 30 layers on the GPU): mean KL 0.034, median 0.0027, top-1 95.1%. The CPU and CUDA paths disagree enough on this model to flip one top token in twenty on this text. Any run must therefore use the same split as the reference.
3. Q4_K_M-imat at the reference split: 0.865, unchanged. So run A's spread is real for this text, and the text is the problem: a model with perplexity 700 on a slice has nearly flat distributions there, and flat distributions make KL and top-1 agreement measure noise.

**Changes.** (a) Run B scores every candidate and the KV arm at the reference split (30 layers). (b) Run C adds a fourth slice, `slice-self.txt`: 40 ultrachat questions (rows 5000 onward, disjoint from everything else) answered by the installed `gemma4:12b` with thinking off at temperature 0, written in Gemma's turn template. Scoring quants on the model's own answers measures drift where the model is confident, which is the regime the agents run in. (c) The decision rule applies to the self-generated and chat-template slices first, code second; wiki is a stress domain only. Thresholds unchanged, with the 0.034 split-noise result noted as the floor to beat.

## Amendment 3 (2026-11-04 22:15): the CUDA flash-attention path is numerically wrong for gemma4

**Run B result (per slice, reference split everywhere).** Still oversized: chat-template slice Q6_K mean 0.31 (median 0.025, top-1 84.5%), UD-Q4_K_XL 0.56, Q5_K_M 0.73, installed Ollama blob 0.85, Q4_K_M-imat 0.85, plain Q4_K_M 1.00, Q3 class 1.1 to 1.5. Code slice: medians are normal (Q6_K 0.002, Q4_K_M-imat 0.007, Q4_K_M plain 0.037) but means are 0.48 to 1.8 because 1 to 2% of tokens have KL above 10. Tables in `results-chat-template/`, `results-code/`, `results-wiki/` on the NVMe.

**Control (Qwen2.5-3B-Instruct, BF16 reference, full GPU offload, code slice).** Q8_0 0.0011, Q6_K 0.0037, Q4_K_M 0.030; maximum KL 1.2; a different offload split changes Q8_0 by 0.0000. Textbook. The pipeline is sound.

**Gemma 4, same Q8_0 weights, code slice, against a CPU-only reference (`-ngl 0 -fa off`).**

| Run | Mean KLD | Max KLD | 99% KLD | Top-1 agreement |
|---|---|---|---|---|
| CPU again | 0.000 | 0.00005 | 0.00003 | 100.0% |
| GPU 30 layers, flash attention off | 0.023 | 4.9 | 0.38 | 96.3% |
| GPU 30 layers, flash attention on | 0.222 | 21.0 | 5.3 | 92.3% |

Flash attention on versus off on the GPU, same weights: 0.224, max 33.7. The CPU path is deterministic and the control model shows GPU and CPU agreeing to 0.001, so the CUDA flash-attention kernels (and to a lesser degree the non-FA CUDA path) are producing wrong logits for Gemma 4 at a small fraction of positions, badly enough to flip the top token one time in thirteen. llama.cpp's tracker has Gemma 4 crash reports under flash attention (#21336, #24400) with a theory about batching sliding-window and global layers; no numerical report was found. Build: commit 3de52ac of 2026-11-04.

**Consequences.** (1) Every KL number in runs A and B measures kernel error plus quantization, not quantization. (2) Ollama runs `gemma4:12b` with flash attention enabled (its runner log says so), on the same ggml CUDA kernels, so the production worker is likely affected; whether it costs task accuracy is unmeasured and is the first thing to test. (3) Run D scores the eight main candidates on the CPU path only (`experiments/kl_cpu.sh`), on the model's own answers (`slice-self.txt`, 40 ultrachat questions answered by the installed model, thinking off, temperature 0, about 23k tokens) and the code slice. Thresholds unchanged for run D.

## Amendment 4 (2026-11-04 22:55): task-level check, template error, and determinism

**Flash attention does not reach task accuracy here.** The installed `gemma4:12b` scored through evolve-lab's `loop.evaluate` (seed prompt, JSON schema, temperature 0, train split; holdout untouched), once on a throwaway Ollama instance on port 11435 started with `OLLAMA_FLASH_ATTENTION=0`, once on the production server (flash attention on):

| Task | FA off | FA on | Items that changed | Seconds per item (off / on) |
|---|---|---|---|---|
| ticker-extract-v2 (150 items) | 0.758 | 0.753 | 5 of 150 | 4.8 / 2.8 |
| code-repair-choice-v1 (6 train items) | 1.000 | 1.000 | 0 of 6 | 2.4 / 1.1 |

One extraction item is 0.0067 of the score, so the difference is noise. Reading: the per-token KL spikes are real but, on a short JSON extraction task at temperature 0, they rarely change the chosen answer. Flash attention stays on; it is 1.7× faster. No service change recommended on this evidence.

**The chat-formatted slices were malformed.** Gemma 4's template (read from the GGUF, 18,922 characters) uses `<|turn>user`, `<turn|>`, `<|turn>model` and a `<|channel>thought ... <channel|>` thinking block; `<start_of_turn>` is Gemma 2/3 syntax and does not exist here. Separately, `llama-perplexity` tokenizes its input with `parse_special=false`, so any marker in the text is scored as literal characters anyway. That is why the Q8_0 reference scored perplexity 22 on the model's own answers. The chat-template and self slices are therefore not in-distribution tests and are set aside; the code and wiki slices (plain text) are unaffected.

**The CPU path is exactly deterministic**, for Gemma 4 and for the Qwen control: changing the thread count (summation order) gives KL 0.000 and maximum 0.00005 on both. So Gemma 4's large Q6_K-vs-Q8_0 tail on the CPU path (code slice: mean 0.48, median 0.002, 99th percentile 10.8) is a genuine sensitivity of the computation to weight perturbation, not noise. Whether it is the model or llama.cpp's implementation of it is the remaining question; an independent transformers (bitsandbytes NF4) reference on the same code slice is being run to answer it.

**Run D (CPU path, code slice)** is finishing; its table replaces run B's as the quantization ranking.

## Independent reference (2026-11-04 23:10): transformers agrees with llama.cpp

To test whether llama.cpp's Gemma 4 implementation is wrong, the same code slice was scored in transformers 5.20 with bitsandbytes NF4 (the only precision of a 12B that fits 10 GB), 256-token windows, second half of each window scored, the same windowing llama.cpp uses.

| Model | llama.cpp (CPU, Q8_0 or BF16) | transformers NF4 |
|---|---|---|
| Qwen2.5-3B-Instruct | 3.14 | 3.20 |
| gemma-4-12b-it | 15.53 | 16.39 |

The two implementations agree within 6% on both models. So llama.cpp's forward pass for Gemma 4 is not broken: Gemma 4 12B-it genuinely assigns perplexity about 16 to ordinary Python (and about 700 to Wikipedia text), five times a 3B Qwen on the same text. A heavily post-trained thinking model is simply far from raw text, and in that regime its output distribution is flat and twitchy, which is what the large KL tails under any perturbation (quantization, flash attention, CPU-versus-GPU) are measuring. The remaining implementation-level fact is that llama.cpp's own CUDA flash-attention path differs from its CPU path by 0.22 mean KL on this model, which no task score has yet shown to matter.

**What this does to the experiment's logic.** KL on raw text cannot rank Gemma 4 quants against the pre-registered thresholds; those thresholds came from models that are not this far out of distribution. The usable readings are (1) the median KL, which reflects the typical token and is in the normal range (code slice: Q6_K 0.002, Q4_K_M-imat 0.007, plain Q4_K_M 0.037), (2) the relative order of candidates, which is consistent across slices and paths, and (3) task accuracy, which is the arbiter. A clean in-distribution KL test needs run E: the model's own answers through its real `<|turn>` template, scored by a `llama-perplexity` built with special-token parsing on, on the CPU path.

## Status

- 2026-11-04 19:55: scripts written; downloads of BF16, UD-Q4_K_XL and QAT-UD-Q4_K_XL started; eval and calibration parquet files started.
- 2026-11-04 20:45: the owner gave blanket permission; the clone passed as a separate command and the CUDA build finished at 21:08 (llama.cpp commit 3de52ac, 2026-11-04). Draft (MTP Q8_0, 444 MiB) and projector (mmproj-F16, 167 MiB) downloaded for the later Ollama import.
- 2026-11-04 21:10: full run started (`kl_gemma4_12b.sh all`, log in the session scratchpad; results land in `/mnt/ai-storage/quant-eval/gemma-4-12b-it/results/`).
- The build command, kept for reproducibility:

```
cd /mnt/ai-storage/tools && git clone --depth 1 https://github.com/ggml-org/llama.cpp llama.cpp-main && cd llama.cpp-main && cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=86 -DLLAMA_CURL=OFF -DGGML_NATIVE=ON && cmake --build build --config Release -j 10 --target llama-quantize llama-perplexity llama-imatrix llama-cli
```

- The runner: `bash "<this folder>/experiments/kl_gemma4_12b.sh" all` (takes the GPU lock; about 1 to 2 hours, most of it quantizing and the Q8_0 reference pass).
- 21:41 run A done; 21:47 to 22:05 run B (per slice, `kl_slices.sh`); 22:12 to 22:46 run D self slice on the CPU path (`kl_cpu.sh`); 22:13 to 22:47 flash-attention A/B on the real tasks; 22:50 to 23:10 Qwen control and transformers cross-check; 23:13 run E started: the model's own answers rendered through the real template (`slice-self2.txt`, 20k tokens) on the deterministic path under the GPU lock, then the code slice fully on the CPU (chained, slow, overlaps the night shift without touching the GPU).
- Run folders on the NVMe: `results/` (A), `results-chat-template/`, `results-code/`, `results-wiki/` (B), `results-cpu-self/` (D, malformed slice, kept for the record), `results-cpu-self2/` (E), `results-cpu-code/` (E, second stage). Each has a `REPORT.md`.

## Results

(filled in by `kl_report.py` when the run completes)
