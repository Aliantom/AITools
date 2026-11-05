<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization playbook for the RTX 3080 (10 GB)

> **TL;DR:** On the 3080: imatrix or Unsloth UD GGUF at Q4_K_M to Q6_K, Q8_0 under 4B, flash attention plus q8_0 KV cache, never offload to CPU, AWQ/GPTQ or EXL3 for the vLLM/transformers path, QLoRA via Unsloth for fine-tuning, and KL divergence against Q8_0 as the acceptance test.
> **Source:** Synthesis of the 2026-11-04 quantization research applied to this PC (RTX 3080 10 GB, Ollama, llama.cpp, finetune-lab)  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

Everything here follows from [Quantization formats, GGUF and KV cache](quantization-formats-gguf-and-kv-cache.md) and [Quantization PTQ methods](quantization-ptq-methods.md). The constraint is 10 GB of VRAM on an Ampere card with INT4/INT8 kernels only. Memory, not compute, decides everything.

## 1. Decision tree

```
Which model size?
├─ ≤ 4B   → Q8_0 (fits easily; small models lose the most per bit)
├─ 7–9B   → Q6_K for code/reasoning (6.6 GB), Q5_K_M (5.7 GB) or Q4_K_M (4.9 GB) for chat and bulk
├─ 12B    → Q4_K_M (≈ 7.3–8 GB); Q5 only with a short context
├─ 14B    → Q4_K_M is 9 GB: fits with a tiny context; prefer IQ4_XS (≈ 8 GB) or a UD-Q3_K_XL
├─ 20–32B → IQ3_M / IQ3_XXS only, chat-grade quality; usually not worth it, use a smaller model
└─ 70B+   → does not fit; offloading makes it unusable for interactive work
Always: imatrix or Unsloth UD variant over a plain quant of the same type.
```

## 2. VRAM budget

`weights + KV cache + ~1 GB (CUDA context, compute buffers, desktop)` must stay under 10 GB, and leave 300 to 500 MB free or Ollama starts swapping layers.

| Model (example) | Q4_K_M | Q5_K_M | Q6_K | Q8_0 | KV at 8k, f16 | KV at 8k, q8_0 |
|---|---|---|---|---|---|---|
| 8B (Llama-3 class, 8 KV heads) | 4.9 | 5.7 | 6.6 | 8.5 | 1.0 | 0.5 |
| 12B (Gemma class) | 7.3 | 8.5 | 9.8 | 12.7 | ~1.5 | ~0.8 |
| 14B (Qwen class) | 9.0 | 10.5 | 12.1 | 15.7 | ~1.5 | ~0.8 |

Numbers are approximate GB; measure with `nvidia-smi` and `ollama ps`. (MEMORY; the vault's Local models page records gemma4:12b at 8.0 GB loaded)

## 3. Ollama settings

In the Ollama service environment (systemd drop-in), keep the existing single-model rule and add the cache settings:

```
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
```

`q8_0` halves the KV cache at negligible quality cost. Use `q4_0` only to fit a context that otherwise cannot. Set the context (`num_ctx`) to what the job needs, not the model's maximum: unused context still reserves memory. (Settings MEMORY; verify against the installed Ollama version's docs before changing the unit.)

## 4. Choosing and getting quants

1. Look for the model's Unsloth "UD" repo on Hugging Face first (`UD-Q4_K_XL`, `UD-Q5_K_XL`), then bartowski's imatrix repo, then the official GGUF.
2. Prefer a vendor QAT checkpoint when it exists (Gemma 3/4 QAT int4): it is better than any PTQ 4-bit of the same model.
3. Avoid plain `Q4_0` and `Q4_1` unless nothing else exists; they are the oldest format.
4. I-quants (IQ4_XS, IQ3_M) are fine on the 3080; they are only slow on CPUs and very old GPUs.

## 5. Quantizing your own model (finetune-lab)

The vault already records that llama.cpp build b11530's converter is approved for finetune-lab GGUF import (Decisions, 2026-10-30). Steps:

```bash
# 1. Merge the LoRA into the base and convert to a 16-bit GGUF
python convert_hf_to_gguf.py /path/to/merged-model --outtype f16 --outfile model-f16.gguf

# 2. Build an importance matrix on text that looks like the real job (chat, code, your domain)
llama-imatrix -m model-f16.gguf -f calibration.txt -o imatrix.gguf -ngl 99

# 3. Quantize with it
llama-quantize --imatrix imatrix.gguf model-f16.gguf model-Q4_K_M.gguf Q4_K_M

# 4. Measure: save the reference logits once, then compare each quant
llama-perplexity -m model-f16.gguf      -f eval.txt --kl-divergence-base ref.kld -ngl 99
llama-perplexity -m model-Q4_K_M.gguf   -f eval.txt --kl-divergence-base ref.kld --kl-divergence -ngl 99
```

Use a held-out `eval.txt`, not the calibration text, or the numbers flatter the quant (Unsloth's warning). If the f16 model does not fit the card for step 4, use Q8_0 as the reference; the error it adds is below the noise. Flag names are from memory of llama.cpp's current CLI; check `--help` on the installed build. (Commands MEMORY; imatrix and KL rationale VERIFIED S17, S20)

**Acceptance test.** Median KL below 0.01 and a top-token flip rate below about 2% on the held-out set means the quant is safe for the job. Above that, go up one quant level or fix the calibration data.

## 6. The vLLM and Transformers path

- Use AWQ or GPTQ W4A16 checkpoints; vLLM picks the Marlin kernel on Ampere. SmoothQuant W8A8 INT8 if throughput on big batches matters more than memory.
- No FP8 anything on this card.
- For 3-bit quality that still runs fast, ExLlamaV3 with EXL3 files, through TabbyAPI or its own server.
- GPTQModel (the maintained AutoGPTQ successor) and llm-compressor (vLLM's tool, which absorbed AutoAWQ) produce these files; both run on the 3080 for models up to about 14B in 16-bit if the calibration is done layer by layer, which they do.

## 7. Fine-tuning path

- QLoRA through Unsloth: 4-bit NF4 base, 16-bit LoRA, gradient checkpointing, sequence length chosen to fit. An 8B base at NF4 is about 5.5 GB, leaving 3 to 4 GB for activations and optimizer state at 1k to 2k tokens.
- Run under the finetune-lab guard (200 W cap, night-shift lock) as the 2026-10-30 decision requires.
- After training: merge, convert, quantize with an imatrix built from the fine-tuning domain, and measure KL against the merged 16-bit model. The merge-then-quantize loss is usually under what the fine-tune gained; if it is not, QA-LoRA-style mergeable adapters or a short torchao Int4 QAT phase are the next step.

## 8. Diffusion models

FLUX.1-class models at INT4 through Nunchaku (SVDQuant) fit the card with memory to spare and run about 3× faster than the NF4 route. Use the `svdq-int4` checkpoints; the NVFP4 ones are Blackwell-only. (VERIFIED S47, S48)

## 9. Things not to do

- Do not judge a quant by perplexity alone or by a vendor's table on a different model.
- Do not pick a quant that needs CPU offload for interactive use.
- Do not calibrate and evaluate on the same text.
- Do not run two models at once; the vault's single-model rule exists because weights reload on every switch.
- Do not go below IQ3 for anything that must reason, code or follow long instructions.
