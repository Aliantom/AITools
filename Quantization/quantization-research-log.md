<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization research log

> **TL;DR:** Dated log of each quantization research pass: what was asked, what was found, what changed in the notes, and the open questions to pick up next (Unsloth claims unverified, EXL3 numbers missing, q8_0 KV quality unmeasured, nothing measured on this PC yet).
> **Source:** Running log of quantization research sessions; started 2026-11-04  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Newest entry first. Each entry: what was asked, what was done, what was found, what changed, what is open. When a later entry answers an open question, say so and link the note that holds the answer.

## 2026-11-04: first pass (Claude Code, Fable 5.1)

**Asked.** How quantization applies to AI; current and bleeding-edge methods; how an end user optimizes it; research, repos and guidelines; PTQ and QAT; and the meaning of a list of terms (non-uniform, mixed precision, per-channel vs per-tensor, group, calibration, uniform, LSQ, AdaRound, bias correction, cross-layer equalization, outlier channel splitting, distillation-assisted, batch-norm folding).

**Done.** Eleven web searches (five extended) and one page fetch; see [Quantization sources](quantization-sources.md) S1 to S50. Wrote the seven notes in this folder, the vault output note "2026-11-04 AI quantization survey" (now superseded by this folder), and set up the GitHub mirror (`mirror_research.py`, `research-mirror.timer`).

**Found.**
- The classic term list is the Qualcomm AIMET / DFQ / AdaRound lineage. Each has an LLM-era descendant: CLE → SmoothQuant, AdaRound → GPTQ and AutoRound, OCS → rotation, BN folding → RMSNorm folding inside rotation pipelines.
- 4-bit weight-only PTQ (GPTQ, AWQ, imatrix K-quants) is still the workhorse; the 2025 benchmark (S1) says GPTQ and QuIP are consistently fine and AWQ collapses at 2-bit.
- Rotation is the dominant idea of 2024 to 2026 for activations and sub-4-bit (QuaRot, SpinQuant, PolarQuant: "rotation alone gives 98% of the gain").
- Sub-4-bit winners are codebooks and trellises (QuIP#, AQLM, QTIP, EXL3).
- QAT matters at 4 bits and below; vendors now ship QAT checkpoints (Gemma 3/4, gpt-oss recipe); torchao is the PyTorch-native path; NVFP4/MXFP4 QAT need Blackwell.
- KV cache: q8_0 locally, FP8 on servers, TurboQuant (Google, ICLR 2026) at about 3.5 bits is in vLLM and pending in llama.cpp.
- Evaluation: KL divergence and flip rate, not perplexity.

**Changed.** New folder; Decisions row for the GitHub mirror; Local models topic page points here.

**Open questions (next passes).**
1. Unsloth Dynamic 2.0's gains are vendor-reported; find or run an independent KL comparison on a model we use (gemma4:12b, qwen3.5:9b).
2. EXL3 has no published bits-per-weight table in what I found; run `eval/compare_q.py` or find community numbers.
3. QTIP vs EXL3 head-to-head: none found.
4. GPTQModel vs llm-compressor on Ampere: no benchmark found; matters only if vLLM is installed.
5. q8_0 KV cache quality: no formal measurement found; measure KL with and without it on this PC.
6. TurboQuant in llama.cpp: PR #21089 status; re-check.
7. ParetoQ's actual numbers (10% budget, 1.58-bit frontier) are from memory; read arXiv 2502.02631.
8. The 2025 *Neural Networks* survey "A survey of low-bit large language models: Basics, systems, and algorithms" was cited but not read.
9. Nothing has been measured on this PC yet. First experiment: KL of Q4_K_M, UD-Q4_K_XL, Q5_K_M and Q6_K for one model against Q8_0 on a held-out chat and code set, with and without q8_0 KV.
10. Check the exact Ollama variable names for the installed version before changing the service unit.
