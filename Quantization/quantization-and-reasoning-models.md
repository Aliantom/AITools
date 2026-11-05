<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Quantization and reasoning models

> **TL;DR:** For reasoning and thinking models, W8A8 or W4A16 is near-lossless, 3-bit is risky, harder tasks and RL-trained reasoners degrade most, aggressive quantization makes small models produce longer outputs, 4-bit KV cache is fine, and AWQ is recommended over GPTQ for weight-only; Qwen3-14B loses 1% MMLU at GPTQ 4-bit while the 0.6B loses 10%.
> **Source:** Second research pass 2026-11-04: 'Quantization Hurts Reasoning?' (2504.04823 v2), 'An Empirical Study of Qwen3 Quantization' (2505.02214, Springer 2026), 'Quantized Reasoning Models Think They Need to Think Longer' (2606.00206, title), QuantLRM (2602.02581, title), ParoQuant  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

The local workers here (gemma4 with thinking on by default, qwen3.5, the deepseek 8B) are reasoning-style models used for agent work, which is the use quantization hurts first. This note collects what is measured.

## 1. "Quantization Hurts Reasoning?" (Liu et al., 2025, v2 Aug 2025)

Studied DeepSeek-R1-distilled and QwQ-style reasoning models under weight, KV and activation quantization on math, science and code.
- W8A8 and W4A16 are lossless in practice; lower bit-widths carry significant accuracy risk.
- 4-bit KV cache quantization is also near-lossless (≤1% drop); they suggest QuaRot for the KV cache.
- AWQ is preferred over GPTQ for weight-only at comparable accuracy because of its simpler, faster implementation.
- Harder tasks and RL-trained reasoners degrade more than SFT-distilled ones.
- Output length: quantized models with minor accuracy loss do not reason longer; aggressively quantized small models do produce longer outputs.
- Mechanisms "remain incompletely understood". Code and models are open.
(VERIFIED S52)

## 2. "An Empirical Study of Qwen3 Quantization" (2025, journal 2026)

Five PTQ methods, 1 to 8 bits, the whole Qwen3 family.
- 8-bit near-lossless across sizes.
- 4-bit: Qwen3-14B loses about 1% MMLU under GPTQ; Qwen3-0.6B loses about 10%.
- 3-bit: AWQ retains some capability, most of the model's advantage is gone.
- Qwen3 degrades more than LLaMA-3 at 3 bits or fewer (consistent with the over-training scaling law in the distillation note).
- The toolkit repo (AI-Efficiency/Qwen3-Quantization-Toolkit) publishes the tables; third-party retellings disagree on which method got 69.3 vs 73.4 MMLU at 4-bit, so read the paper's table before quoting.
(VERIFIED S51, S110)

## 3. 2026 follow-ups (titles only)

- "Quantized Reasoning Models Think They Need to Think Longer, but They Do Not" (Jun 2026): the title says low-bit reasoners emit longer chains without needing them; not read. (S53)
- QuantLRM (Feb 2026): quantizes large reasoning models using fine-tuning signals, that is, calibration and rounding guided by what the reasoning fine-tune changed. (S54)
- ParoQuant (ICLR 2026) is explicitly pitched for "efficient reasoning LLM inference" and reports +2.4% average over AWQ on reasoning tasks. (S99)

## 4. What this means for the agents on this PC

- Keep `gemma4:12b` and `qwen3.5:9b` at 4-bit or better; never run an agent worker at 3-bit, and treat IQ3 as a chat-only fallback.
- Thinking mode multiplies the cost of any per-token error (longer chains), so the KL threshold for thinking models should be stricter than for chat: experiment 001's "safe" line (0.02) is the loose bound; 0.01 is the comfortable one.
- Watch output length as a symptom: a quant that makes the model ramble is damaged even if its benchmark score is close.
- 8-bit KV cache is safe for reasoning; 4-bit KV is "near-lossless" in the study but should be measured here before use in agents (experiment 001's KV arm).
- Evaluate with task sets that resemble the agent jobs (extraction, code repair, tool calls) in addition to KL; the vault already has the 150-item extraction bake-off and the 7 code repairs, which are the right instruments.
