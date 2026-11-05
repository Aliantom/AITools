<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Serving kernels and speculative decoding

> **TL;DR:** On Ampere the fast paths are llama.cpp CUDA kernels, Marlin INT4×FP16 and EXL3; EXL3 at 4.0 bpw beats GGUF Q4_K_M on KL at smaller size while GGUF wins back above 5 bits; speculative decoding stacks with quantization and gemma4 already ships a multi-token-prediction draft that Ollama uses.
> **Source:** Second research pass 2026-11-04: EXL3 community measurements (ubergarm gist, efraingaray, atomic.chat), 'Speculative Decoding Meets Quantization' (2505.22179), SD2 (2504.08838), Quasar (2603.01399), ML-SpecQD (2503.13565), Ollama/Unsloth MTP draft files, Marlin and QServe (memory)  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

## 1. What runs fast on an RTX 3080

| Path | Kernel | Formats | Notes |
|---|---|---|---|
| llama.cpp / Ollama | ggml CUDA (mul_mat_q, mmvq, flash attention) | every GGUF type | Dequantize-on-the-fly INT kernels; decode is bandwidth-bound so 4-bit is about 2× faster than 8-bit per token (MEMORY) |
| vLLM / SGLang | Marlin (INT4×FP16 and INT8×FP16 GEMM with Ampere tensor cores) | GPTQ, AWQ, compressed-tensors W4A16/W8A16 | Near-ideal 4-bit speed at batch 1 to 32 (MEMORY) |
| vLLM | SmoothQuant W8A8 INT8 tensor cores | INT8 | Real compute speedup on prefill and big batches (MEMORY) |
| ExLlamaV3 (TabbyAPI) | EXL3 trellis kernels | EXL3 at any fractional bpw | Best quality per bit under 4 (S40, S96 to S98) |
| QServe | W4A8KV4 with register-level dequant | INT4 weights, INT8 activations, 4-bit KV | Research kernel, A100/L40S oriented (MEMORY) |
| Not available | FP8, FP4 tensor cores | FP8, MXFP4, NVFP4 | Hopper/Ada/Blackwell only |

## 2. EXL3 measurements (community, not standardized)

- Near-FP16 perplexity at 6 to 8 bpw, competitive down to 3 bpw on Llama-3.1 and Mistral; Llama-3.1-70B "coherent" at 1.6 bpw. (VERIFIED S98 relaying turboderp's numbers)
- A Qwen-family comparison at about 4.0 bpw: EXL3 5.8 GiB with KL near 0.025 versus GGUF Q4_K_M 6.6 GiB at 0.040 and IQ4_XS at 0.054. (VERIFIED S98)
- A 27B on 16 GB: EXL3 at 3 bits mean KL 0.0435 versus imatrix Q3_K_M 0.0554 (EXL3 wins); at a 15 GB budget a custom GGUF reached 0.0159 versus EXL3 3.5 bpw at 0.0234 (GGUF wins). Reading: EXL3 wins under about 4 bits, GGUF mixes win above. (VERIFIED S97)
- GGUF labels understate size: Q4_K averages about 4.5 bits in its own layout and about 4.89 effective. (VERIFIED S98)
- ExLlamaV3 reached a stable release in mid-2026 (version numbers differ between sources). (VERIFIED S97, S98)

For this PC: EXL3 is the way to run a 20B-class dense model at 3 to 3.5 bpw with better fidelity than IQ3 GGUF. It is a new runtime, so the tool-gatekeeper check and a named role ("sub-4-bit serving") come first.

## 3. Speculative decoding and quantization

- **The idea.** A small draft model proposes several tokens; the big model verifies them in one forward pass. Decode is bandwidth-bound, so verifying k tokens costs about the same as generating one; acceptance rate decides the gain. (MEMORY)
- **Compatibility study (May 2025).** Quantization and speculative decoding stack, but a quantized draft raises rejections and a quantized target adds dequantization overhead; a hierarchical design mitigates both. (VERIFIED S102)
- **Quantized drafts.** ML-SpecQD uses MXFP4 drafts for up to 2.72× over BF16 (needs an aligned draft). SPEQ uses part of the target's own weight bits as its draft (needs custom hardware). SD2 finds unstructured-sparse drafters beat 2:4 sparse ones and match dense drafters end to end. Quasar quantizes only the verification stage, training-free. (VERIFIED S105, S103, S104)
- **Multi-token prediction (MTP) heads.** Gemma 4 ships an MTP draft (the Unsloth repos carry `MTP/mtp-gemma-4-12b-it-*.gguf` at 0.4 to 0.8 GiB, and Ollama's `gemma4:12b` manifest includes a 443 MiB "draft" layer). That is built-in speculative decoding at no extra model download: the draft is quantized (Q8_0 or BF16) separately from the main weights, so the main model's quant level does not touch the draft's acceptance rate. (VERIFIED S108 and the local manifest; Ollama's use of it inferred from the manifest, not from docs)

## 4. Rules for this PC

1. Keep using the Ollama path for agents; the MTP draft is already there.
2. If throughput on batch jobs (night-shift extraction over thousands of items) becomes the bottleneck, vLLM with an AWQ W4A16 model and Marlin is the known 2 to 3× step; measure before installing.
3. 2:4 sparsity is a non-starter on this card for quality reasons (SD2) and on Ampere consumer cards for kernel support.
4. Do not quantize a draft model harder than Q8_0; the acceptance rate is the whole gain.
