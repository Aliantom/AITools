<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Distillation and low-bit QAT deep dive

> **TL;DR:** Below 3 bits the model must re-learn, not just adapt (ParetoQ's 2-to-3-bit transition), self-distillation from the full-precision teacher is what makes sub-4-bit QAT work (BitDistiller, UPQ), the QAT share of compute should grow with total compute, and over-trained models quantize worse, so a 12B trained on many trillions of tokens loses more per bit than older models did.
> **Source:** Second research pass 2026-11-04: ParetoQ (arXiv 2502.02631 and repo), BitDistiller (ACL 2024), LLM-QAT, UPQ (2506.09104), Bit-by-Bit (2604.07888), EdgeRazor (2605.04062), QATFactory, torchao, 'Low-bit favors undertrained LLMs' (2411.17691)  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

## 1. The key empirical facts

**A learning transition between 2 and 3 bits (ParetoQ, Meta, 2025).** At 3 bits and above, QAT keeps the model near its pretrained representations ("compensation"); at 2 bits and below the representations shift substantially ("reconstruction"), which needs more training and a different quantization function. ParetoQ uses one function per bit-width: a 1-bit sign function, LSQ for 3 and 4 bits, and a new Stretched Elastic Quantization for 1.58 and 2 bits. Sub-4-bit models (binary, ternary, 2-bit, 3-bit) often beat 4-bit at equal effective size, with 2-bit and ternary on the Pareto frontier for small models; the 1.58-bit Llama-3-8B closes 37.8% more of the gap to full precision than BitNet's 1.58-bit Llama-3-8B using 30% of the tokens. The repo's advice: for hardware friendliness and speed, explore 2-bit for on-device use. (VERIFIED S67, S70)

**QAT budget scales with compute (ParetoQ).** The loss-optimal fraction of training spent in QAT increases with total compute and is predictable from a tokens-per-parameter-byte statistic; the "about 10%" rule from earlier notes is a point on that curve, not a constant. (VERIFIED S67, abstract level)

**Over-trained models quantize worse ("Low-Bit Quantization Favors Undertrained LLMs", 2024).** Scaling laws fit on up to 100T training tokens predict that the quantization-induced degradation grows with tokens per parameter: a small model trained on a huge corpus (every modern 8B to 12B) is harder to quantize than an older, under-trained one of the same size. This is the systematic reason Qwen3 and Gemma lose more at 3 bits than Llama-2 did. (VERIFIED S68, title plus general knowledge of the paper; the Qwen3 study's finding that Qwen3 degrades more than LLaMA-3 at low bits is consistent, S51)

## 2. Distillation as the loss

| Method | Teacher | Student | Loss | Data | Result (self-reported) |
|---|---|---|---|---|---|
| LLM-QAT (2023) | FP model | fake-quant model | KL on logits | teacher-generated (data-free) | Usable 4-bit W4A8KV4 LLaMA-7B to 30B (MEMORY) |
| BitDistiller (ACL 2024) | FP model | sub-4-bit QAT model | confidence-aware KL ("CAKLD"), asymmetric clipping | small, task-mixed | 2-bit LLaMA-2-7B MMLU 29.25 vs 23.62 for LLM-QAT per a secondary summary (S76) |
| UPQ (Jun 2025) | INT4 block-PTQ model as stage 1, FP as teacher | INT2 | generalized Jensen-Shannon divergence | instruction data | INT2 up to 8B instruct; weights only (S77) |
| ParetoQ (2025) | FP model | 1 to 4 bit | cross-entropy plus distillation | pretraining mix | see above (S67) |
| Gemma 3/4 QAT (Google) | FP model | int4 | teacher probabilities | about 5k steps | half the PTQ loss (S38) |
| QATFactory (2026) | FP model | NVFP4/MXFP4/Q4_K in BF16 simulation | distillation | configurable | W4A16 training for NVFP4 deployment, W4A4 for MXFP4 (S12) |
| EdgeRazor (May 2026) | FP model | mixed-precision | quantization-aware distillation | n/a | title only (S78) |
| Bit-by-Bit (Apr 2026) | FP model | progressively lower bits | QAT with outlier channel splitting | n/a | stability at low bits (S30) |

Why distillation and not labels: the quantized model's job is to imitate the original, and the teacher's full distribution gives per-token gradient signal on every vocabulary entry, not just the correct one. Confidence-aware variants (BitDistiller) weight the loss toward tokens where the teacher is sure, so the student does not waste capacity matching noise. (MEMORY plus S76)

## 3. Practical recipes (collected)

1. **Start from PTQ.** UPQ's two-stage recipe (block-wise PTQ to INT4, then distillation-based QAT to INT2) beats QAT from scratch at the same budget; EfficientQAT's block-then-end-to-end recipe makes 70B QAT fit one GPU. (VERIFIED S77; EfficientQAT MEMORY)
2. **Match the deployment grid exactly** during fake quantization: group size, symmetric or asymmetric, which tensors stay high. torchao and QATFactory both insist on this. (VERIFIED S9, S12)
3. **Keep the learning rate low** and the QAT phase short at 4-bit (compensation regime); budget more at 2-bit (reconstruction regime). (ParetoQ, VERIFIED S67)
4. **Pick the quantizer by bit-width**: LSQ-style learnable scales at 3 to 4 bits, stretched/elastic functions at 2 bits and below. (VERIFIED S67)
5. **Progressive lowering** (Bit-by-Bit): 8 to 6 to 4 to 3 bits, with outlier handling, is more stable than jumping. (VERIFIED S30, summary)
6. **Evaluate on tasks, not KL**, for QAT models: they are different weights, and distance from the original is not the goal. (This note's own reasoning; see experiment 001's caveat.)

## 4. What it means for this PC

- A 12B QAT run is out of reach here (needs the BF16 model and optimizer state, about 100 GB); a 1B to 4B model is feasible with torchao Int4 QAT in the finetune-lab venv under the 200 W guard.
- The place QAT could matter for finetune-lab is the small-model track (the `ftlab-p001` Qwen2.5-3B runs): a short Int4 QAT phase after QLoRA could let the 3B ship at Q4 with Q8-level fidelity. That is a pre-registrable experiment.
- For the 12B worker, use Google's QAT checkpoint (Unsloth's QAT UD-Q4_K_XL) rather than doing QAT; experiment 001 measures it.
- Repos: facebookresearch/ParetoQ (training code), DD-DuDa/BitDistiller, pytorch/ao (QAT), the UPQ paper (code not confirmed). (VERIFIED S67, S76, S9)
