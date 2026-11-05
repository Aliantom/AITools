<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization-aware training (QAT) methods

> **TL;DR:** QAT recovers most of the accuracy lost at 4 bits and below (torchao: up to 96% of the PTQ loss on HellaSwag), model vendors now ship QAT checkpoints (Gemma 3/4, gpt-oss), the recipe is about 10% of training with fake quantization and teacher distillation, and on this PC the practical form is QLoRA fine-tuning.
> **Source:** Web research 2026-11-04 (PyTorch torchao blogs and paper, NVIDIA Model Optimizer blog, QATFactory, Unsloth docs, TensorFoundry) plus general knowledge, labelled  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

QAT trains (or fine-tunes) the model while simulating quantization, so the weights settle into values that survive rounding. It costs GPU time and needs training data; PTQ does not. The evidence says it only matters at 4 bits and below, and that is exactly where everyone wants to be.

## 1. How it works

1. **Fake quantization.** On every forward pass the weights (and optionally activations) are quantized and de-quantized in place, so the loss sees the rounding error. The stored weights stay in float. (VERIFIED S9, S10)
2. **Straight-through estimator.** Rounding has no useful gradient, so the backward pass treats it as the identity. (MEMORY)
3. **Learnable scales.** LSQ (Esser et al., 2019) makes each layer's step size a parameter; PACT (2018) did the same for the activation clip. (MEMORY)
4. **Distillation.** The student is the fake-quantized model, the teacher is the full-precision model, and the loss is the KL between their output distributions rather than cross-entropy on labels. This is what LLM-QAT, Gemma QAT, ParetoQ and QATFactory do. (VERIFIED S12, S38; LLM-QAT MEMORY)
5. **Convert.** At the end the fake-quant modules are replaced by real quantized weights and kernels. torchao's API is `prepare` then `convert`. (VERIFIED S9)

## 2. When QAT pays off

| Situation | Verdict | Evidence |
|---|---|---|
| 8-bit | Not needed; PTQ is near-lossless | S38 |
| 4-bit on a 7B+ model | Small gain; PTQ with GPTQ/AWQ/imatrix is usually enough | S1, S38 |
| 4-bit on a small model (under 4B) | Worth it; small models lose more per bit | S38 (Gemma 4 E2B example), MEMORY |
| 3-bit | Clear gain | S38 |
| 2-bit and ternary | Required; PTQ breaks down | S38, S1 |
| W4A4 and FP4 (MXFP4/NVFP4) serving | Worth it; vendors do it | S14, S12 |

Numbers from the sources:
- torchao: QAT recovers up to 96% of the HellaSwag degradation that PTQ caused on Llama 3 (S10).
- torchao docs: Qwen3-8B on MMLU-Pro, BF16 0.4929, NVFP4 PTQ 0.4519, NVFP4 QAT 0.4686 (S9).
- Gemma 3 27B QAT: 54 GB to about 14 GB at 4-bit, with roughly half the quality loss of plain PTQ (S38).
- NVIDIA gpt-oss recipe: switching from MXFP4 to NVFP4 gave 2 to 3 percent better validation-loss convergence, after upcasting the MXFP4 checkpoint to BF16 first (S14).

## 3. The 2025 to 2026 recipes

**torchao QAT (PyTorch, 2024 onward).** PyTorch-native fake quantization for Int8, Int4 (per-group) and, on Blackwell, NVFP4 and MXFP4. Works with Hugging Face TRL and Unsloth. The paper (Jul 2025) describes the training-to-serving pipeline; a 2026 RFC adds MXFP8/MXFP4/NVFP4 QAT for MoE experts. NVFP4 QAT needs Blackwell or newer; Int4 and Int8 QAT run on Ampere. (VERIFIED S9, S10, S11, S15)

**Gemma 3 and Gemma 4 QAT checkpoints (Google, 2025 to 2026).** Trained on the teacher's probabilities for a short QAT phase, released as int4 GGUF/MLX/safetensors. The TensorFoundry guide gives Gemma 4 E2B at about 1 GB for mobile. For this PC these are the easiest way to get a near-BF16 4-bit Gemma. (VERIFIED S38; Gemma 3 QAT blog MEMORY)

**NVIDIA Model Optimizer gpt-oss recipe (2025).** Upcast the MXFP4 checkpoint to BF16, fine-tune, apply QAT with NVFP4 or MXFP4 fake quant, export for TensorRT-LLM or vLLM. (VERIFIED S14)

**QATFactory (2026).** A deployment-aligned framework that simulates NVFP4, MXFP4 and GGUF Q4_K in BF16 (no native hardware needed) and includes distillation. Its guideline: train W4A16 for NVFP4 W4A4 deployment, but train W4A4 for MXFP4. (VERIFIED S12)

**ParetoQ (Meta, Feb 2025).** Scaling-law study of extremely low-bit QAT (1-bit, 1.58-bit, 2-bit, 3-bit, 4-bit) with a unified framework. Findings as I recall them: spending about 10% of the training budget on QAT is the sweet spot, below 2 bits the model "reconstructs" rather than "compensates", and 1.58-bit and 2-bit sit on the Pareto frontier for small models. Numbers not re-verified in this session. (MEMORY; cited by S11)

**EfficientQAT (2024).** Two-stage: block-wise training of all parameters, then end-to-end training of only the quantization parameters, so a 70B can be QAT-ed on one GPU. (MEMORY)

**BitNet b1.58 (Microsoft, 2024).** Train from scratch with ternary weights {-1, 0, 1}; no multiplications needed. The largest public model is about 2B. Not a path for this PC's pretrained models. (VERIFIED S38; paper MEMORY)

**Unsloth QAT (2025).** Unsloth exposes torchao QAT inside its fine-tuning loop with the usual 2× speed and memory savings. (S13, title only)

**DeepSeek-V4 (2026).** Reported to apply MXFP4 QAT to MoE expert weights during post-training. (VERIFIED S15, secondhand)

**Bit-by-Bit (Apr 2026).** Progressive bit-width reduction with outlier channel splitting for stable low-bit LLM QAT. (VERIFIED S30)

## 4. Quantized fine-tuning (not QAT, often confused with it)

**QLoRA (2023).** Freeze the base model in 4-bit NF4, add LoRA adapters in 16-bit, train only the adapters. Double quantization quantizes the scales themselves, and paged optimizers survive memory spikes. The base weights never become quantization-aware; the adapters just learn on top of the quantized base. This is how an 8B is fine-tuned on a 10 GB card. (MEMORY; QLoRA/NF4 listed in S38)

**QA-LoRA and similar (2023 to 2024).** Make the adapters mergeable into the quantized base so the final model stays 4-bit without a re-quantization loss. (MEMORY)

**PV-Tuning (2024).** Fine-tunes extreme-compression models (AQLM, QuIP#) end to end, improving 1 to 2 bit results. (MEMORY)

Rule of thumb: QLoRA when you want a fine-tuned model and will quantize it afterwards; QAT when the deliverable itself must be low-bit and accurate.

## 5. Recipe guidance (collected)

- Budget: about 90% of training in full precision, then about 10% as a quantization-aware fine-tune. (S38, ParetoQ MEMORY)
- Teacher: the full-precision model, with KL on logits. (S12, S38)
- What to fake-quantize: match the deployment format exactly (group size, symmetric or not, which tensors stay high-precision). (S9, S12)
- W4A16 vs W4A4 training: depends on the target format (S12: W4A16 for NVFP4, W4A4 for MXFP4).
- Learning rate: lower than the original fine-tune; the model only needs to shift weights to grid-friendly values. (MEMORY)
- Evaluate with KL divergence and task accuracy, not perplexity. (S17)

## 6. On this PC

- Int4 and Int8 QAT through torchao run on the 3080. NVFP4 and MXFP4 QAT do not (no Blackwell), though QATFactory-style BF16 simulation would, slowly.
- The GPU budget rule in `Decisions.md` (200 W cap, night-shift lock) applies; finetune-lab already runs QLoRA under it.
- Practical order for finetune-lab: QLoRA fine-tune, convert to GGUF with an imatrix, measure KL against the BF16 adapter-merged model. Only consider QAT if the target is 3-bit or smaller or a sub-4B model.
