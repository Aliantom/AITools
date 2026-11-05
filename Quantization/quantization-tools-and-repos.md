<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization tools and repos

> **TL;DR:** The quantization toolchain for this PC: llama.cpp for GGUF, GPTQModel and llm-compressor for vLLM formats, exllamav3 for EXL3, torchao for QAT, bitsandbytes and Unsloth for QLoRA, Nunchaku for diffusion; AIMET, Model Optimizer and TensorRT-LLM matter mainly for other hardware.
> **Source:** Web research 2026-11-04 plus general knowledge of the quantization tooling landscape, labelled  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Status column is as of 2026-11-04 and mixes what the sources said (VERIFIED) with general knowledge (MEMORY). "Ampere" says whether it is useful on the RTX 3080.

## Inference-side quantizers and runtimes

| Tool | What it does | Formats | Ampere | Status / notes | Label |
|---|---|---|---|---|---|
| **llama.cpp** (ggml-org) | Quantize (`llama-quantize`), calibrate (`llama-imatrix`), evaluate (`llama-perplexity --kl-divergence`), run GGUF | all GGUF types | yes | Very active; Ollama is built on it; TurboQuant KV PR open | VERIFIED S20, S41 |
| **Ollama** | Local model server over llama.cpp | GGUF | yes | Installed here; `OLLAMA_KV_CACHE_TYPE`, `OLLAMA_FLASH_ATTENTION` | MEMORY |
| **Unsloth** (GGUF side) | Publishes Dynamic 2.0 "UD" quants; exports fine-tunes to GGUF | GGUF | yes | Vendor-reported gains | VERIFIED S17 |
| **GPTQModel** (ModelCloud) | Maintained successor to AutoGPTQ; GPTQ and related methods, many kernels | GPTQ (W4A16, W8A16), exports | yes (Marlin) | Active; AutoGPTQ itself is unmaintained | MEMORY |
| **llm-compressor** (vLLM project, Red Hat) | One-stop PTQ for vLLM: GPTQ, AWQ, SmoothQuant, FP8, NVFP4, sparsity | compressed-tensors | yes for INT formats | Active; absorbed AutoAWQ's role after AutoAWQ was archived in 2025 | MEMORY |
| **AutoAWQ** | Original AWQ tooling | AWQ | yes | Archived 2025; use llm-compressor | MEMORY |
| **AutoRound** (Intel) | SignRound rounding optimization; exports GPTQ/AWQ/GGUF | many | yes | Active; SignRoundV2 paper Dec 2025 | VERIFIED S3 |
| **HQQ** (mobius labs) | Calibration-free quantizer, fast | HQQ, exports | yes | Active | S38 mention |
| **exllamav3** (turboderp) | EXL3 trellis quantizer and fast consumer-GPU runtime | EXL3 | yes | Active; `eval/compare_q.py` for bitrate-matched perplexity | VERIFIED S40 |
| **vLLM** | Serving engine; Marlin INT4 kernels, FP8, TurboQuant KV presets | AWQ, GPTQ, compressed-tensors, FP8 | yes (no FP8) | Active | VERIFIED S41 |
| **SGLang** | Serving engine with FP8 KV | similar | yes (no FP8) | Active | S38 |
| **bitsandbytes** | LLM.int8() and NF4; the QLoRA base | int8, NF4 | yes | Active; slow for inference, built for training | MEMORY |
| **Optimum-quanto** (Hugging Face) | Simple weight/activation quantization in Transformers | int8, int4, fp8 | partial | Active, less used for LLM serving | MEMORY |
| **TensorRT-LLM** | NVIDIA serving with INT4 AWQ, FP8, NVFP4 | engine files | INT formats only | Active; heavyweight build | MEMORY |
| **Nunchaku** + **deepcompressor** (MIT HAN Lab) | SVDQuant 4-bit diffusion runtime and quantizer | INT4, NVFP4 | INT4 yes | Active; ComfyUI nodes exist | VERIFIED S48, S49 |
| **turboquant** (OnlyTerp, unofficial) | Open implementation of Google's TurboQuant KV compression | KV cache | research | Unofficial | VERIFIED S42 |

## Training-side (QAT and quantized fine-tuning)

| Tool | What it does | Ampere | Notes | Label |
|---|---|---|---|---|
| **torchao** (PyTorch) | QAT (Int4, Int8; NVFP4/MXFP4 on Blackwell), PTQ, float8 training | Int4/Int8 yes | The PyTorch-native path; works with TRL and Unsloth | VERIFIED S9, S11 |
| **Unsloth** (training side) | QLoRA/LoRA fine-tuning 2× faster, QAT via torchao | yes | Used by finetune-lab | VERIFIED S13 |
| **NVIDIA Model Optimizer (modelopt)** | PTQ and QAT to FP8/NVFP4/MXFP4/INT4, export to TRT-LLM and vLLM | INT4 only | gpt-oss QAT recipe | VERIFIED S14 |
| **QATFactory** | Deployment-aligned QAT and distillation, simulates NVFP4/MXFP4/Q4_K in BF16 | yes (simulated) | 2026 paper; check for code | VERIFIED S12 |
| **AIMET** (Qualcomm) | CLE, bias correction, AdaRound, QAT for ONNX/PyTorch, aimed at Qualcomm NPUs | CPU/GPU simulation | The classic-term library; not for LLM serving here | VERIFIED S27, S28 |
| **Intel Neural Compressor** | PTQ/QAT for CPUs and Intel accelerators; hosts AutoRound | CPU | Mainly for Intel targets | MEMORY |
| **QuaRot**, **SpinQuant** repos | Reference rotation pipelines | yes | Research code | S1, MEMORY |
| **PV-Tuning**, **AQLM**, **QuIP#** repos | Extreme-compression research code | partial kernels | Research code | MEMORY |

## Evaluation

| Tool | Use |
|---|---|
| `llama-perplexity --kl-divergence` | KL, top-token agreement and perplexity for GGUF quants against a saved reference |
| **lm-evaluation-harness** (EleutherAI) | Task accuracy (MMLU, HellaSwag, GSM8K) for any backend, including vLLM and GGUF |
| Unsloth's KL methodology | Calibration vs evaluation separation (S17) |
| exllamav3 `eval/compare_q.py` | Bitrate-matched perplexity across EXL3 sizes (S40) |

## Role on this PC (one owner per role)

- GGUF production and measurement: llama.cpp (finetune-lab already uses its converter).
- Fine-tuning: Unsloth with bitsandbytes NF4, under the finetune-lab guard.
- Serving beyond Ollama: not yet installed; vLLM with AWQ would be the choice if needed.
- Nothing above should be installed without the tool-gatekeeper check and a named role.
