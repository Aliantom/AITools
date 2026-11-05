<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization research log

> **TL;DR:** Dated log of each quantization research pass: what was asked, what was found, what changed in the notes, and the open questions to pick up next (Unsloth claims unverified, EXL3 numbers missing, q8_0 KV quality unmeasured, nothing measured on this PC yet).
> **Source:** Running log of quantization research sessions; started 2026-11-04  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Newest entry first. Each entry: what was asked, what was done, what was found, what changed, what is open. When a later entry answers an open question, say so and link the note that holds the answer.

## 2026-11-04 (late evening): passes 2 to 4 before implementation

**Asked.** Start the three pre-implementation passes while the owner builds llama.cpp: evaluation methods for this PC's jobs, Ollama mechanics for applying a custom quant, and full reads of the five load-bearing papers.

**Done.** Three notes: [Quantization evaluation methods for this PC](quantization-evaluation-methods-for-this-pc.md), [Ollama mechanics for custom quants](ollama-mechanics-for-custom-quants.md), [Quantization primary paper reads](quantization-primary-paper-reads.md). Patched the reasoning, distillation, and two diagramming notes where the full reads changed a number. Sources S112 to S122; S51, S52, S67, D2, D7 upgraded to FETCHED.

**Found.**
- The task-level eval already exists: evolve-lab's `loop.evaluate` over Ollama tags, driven by finetune-lab's `evalrun.py`; only a deterministic tool-call set is missing. Public harnesses work over Ollama's OpenAI endpoint for generative tasks only.
- Ollama 0.40.10 here: flash attention auto-on for gemma4, KV cache still f16, no GGUF quantization on import, no imatrix in its quantizer; the Modelfile needs FROM, DRAFT and a second FROM (projector). Registry blob is 250 MiB larger than Unsloth's Q4_K_M, so the mixes differ.
- Paper corrections: ParetoQ's 90/10 is one 125M experiment; GPTQ beats AWQ at 4-bit on every Qwen3 size; 4-bit KV is under 1% on 14B+ reasoners but 3-bit KV and W4A4 are not; blueprints help small models most on code but APO and template search sometimes hurt; DAG-Math's format is Edge, Parents, Node and correct answers are at most 80% closed.

**Open.** 16. ~~Confirm the projector FROM syntax on a scratch model~~ (done 21:15: works; smoke tests pending). 17. Build the 30 to 50 item tool-call set (owner reviews). 18. Decide whether to install lm-eval or bfcl-eval (gatekeeper). 19. Read the rest of 2504.04823 (appendix past 100k chars) and DAG-Math's appendix for the checker rules.

## 2026-11-04 (evening): second pass, deep dives and the first experiment

**Asked.** Run the KL test on gemma4:12b quants; go deeper on every requested topic; find repos; connect quantization with AI-ingestible diagramming and reasoning maps.

**Done.** Sixteen more searches (S51 to S111 in [Quantization sources](quantization-sources.md)); nine new notes (calibration, mixed precision, outliers and rotation, rounding, distillation and low-bit QAT, quantized fine-tuning, reasoning models, MoE and multimodal, serving and speculative decoding); experiment 001 pre-registered with scripts in `experiments/`; a sibling research folder "AI diagramming and reasoning maps" started and mirrored to AITools.

**Experiment 001 status.** Downloads started (Unsloth BF16, UD-Q4_K_XL, QAT UD-Q4_K_XL; wikitext and ultrachat parquet). Building llama.cpp with CUDA was refused by the session's permission mode; the owner runs the one-line build in the experiment note, then the runner. No result yet.

**New findings worth keeping.**
- Calibration saturates at about 128 × 2048 tokens; domain match beats volume; evaluate elsewhere. (S55, S59)
- Scalar Hessian proxies rank layer sensitivity poorly; output-error and Shapley-style measures do better; early layers are usually the sensitive ones. (S61, S62, S64)
- Rotation does nearly all the work in rotation-plus-codebook methods; ParoQuant brings it to AWQ speed. (S31, S99)
- ParetoQ: learning transition between 2 and 3 bits; QAT share should grow with compute; sub-4-bit can beat 4-bit at equal size. Over-trained models quantize worse. (S67, S68)
- Reasoning models: W4A16 and KV8 safe, 3-bit risky, aggressive quantization lengthens outputs of small models; Qwen3-14B loses 1% MMLU at GPTQ-4 while 0.6B loses 10%. (S52, S51)
- Uploaders are within about 6% at the same quant type; Unsloth's XL mixes are the real edge. (S94, S95)
- EXL3 beats GGUF under 4 bpw, loses above 5. (S97, S98)
- Gemma 4 ships an MTP draft that Ollama already uses; speculative decoding is free here. (S108, local manifest)
- MoE: expert-level allocation by activation importance is the way qwen3:30b-a3b could fit this card. (S85, S86)

**Open questions carried forward.** Items 1 to 10 from the first entry remain except 7 (ParetoQ read at abstract level) and 8 (survey located, S79). Added: 11. Measure per-tensor-type sensitivity of gemma-4-12b (mixed-precision note, section 5). 12. KL-test an Unsloth 2-bit-expert quant of qwen3:30b-a3b. 13. Merge-loss KL for the next finetune-lab run. 14. Verify Ollama's flash-attention default on the installed version. 15. Read the 2606.00206 "think longer" paper and QuantLRM.

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
