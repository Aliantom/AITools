<!-- Generated from the Obsidian vault (Machine/Research/Quantization). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Evaluation methods for this PC's jobs

> **TL;DR:** This PC already has the task-level instrument that matters (evolve-lab's loop.evaluate scores any Ollama tag on JSON-schema tasks at temperature 0), KL divergence is the fidelity layer under it, the one missing layer is a deterministic tool-call set, and public harnesses (lm-eval, BFCL) work over Ollama's OpenAI endpoint only for generative tasks, not log-probability ones.
> **Source:** Pass 2, 2026-11-04 evening: lm-evaluation-harness and BFCL docs and issues, agent-eval guides, the quantized tool-call failure write-up, and a read of evolve-lab's task evals and finetune-lab's evalrun harness on this PC  ·  **Project:** finetune-lab  ·  **Updated:** 2026-11-04

KL divergence says how far a quant drifts from the original model. It does not say whether the night-shift extraction still parses, whether code repairs still land, or whether tool calls still validate. One community measurement found a vendor's NVFP4 build worse than an uncalibrated INT8 and found 4-bit KV cache the only setting that produced reproducible, unrecovered tool-call failures on a 100k-token workload; the author's conclusion, "test the specific artifact", is the right one. (S116, unverified methodology)

## 1. Three layers, cheapest first

| Layer | Instrument | What it catches | Cost | Status here |
|---|---|---|---|---|
| Fidelity | `llama-perplexity --kl-divergence` (experiment 001) | Drift from the reference; ranks quants | Minutes per quant | Ready, blocked on the build |
| Task accuracy | evolve-lab `loop.evaluate(task, model, prompt, examples)` over Ollama, JSON-schema constrained, temperature 0, thinking off | Whether the job still works: ticker-extract-v2, code-repair-choice-v1, python-repair-v1, schema-correction-v1, filing-events-v1, pulse-stance-v1, cli-workflow-v1 | Minutes per task per model | Exists; finetune-lab's `evalrun.py` already drives it for one model and one file |
| Tool use | A deterministic tool-call set: expected tool name, required parameters, argument types and values, plus "no tool" negatives | Silent tool-call failures that KL and schema tasks miss | One-time build of 30 to 50 items; seconds to score | Missing |

## 2. The existing instrument, named exactly

`~/code/evolve-lab/src/evolve/loop.py` has `evaluate(task, model, prompt, examples, workers=2)`, which calls `models.local_json(model, prompt, rendered_input, task.schema)` per example and scores with the task's `scorer.py`. Tasks live in `~/code/evolve-lab/tasks/<name>/` with `task.yaml` (description, input template, JSON schema), `data/`, `seed_prompt.md` and a scorer. finetune-lab's `evalrun.py` wraps it: `~/code/evolve-lab/.venv/bin/python evalrun.py --model M --data F.jsonl --out predictions.jsonl --metrics m.json`, refusing the frozen holdout. (LOCAL, read 2026-11-04)

So "score quant X on the extraction job" is: create an Ollama tag from the GGUF (see [Ollama mechanics for custom quants](ollama-mechanics-for-custom-quants.md)), then run evalrun with `--model <tag>` on the dev split of ticker-extract-v2 and code-repair-choice-v1. No new harness is needed for the quantization decision or for the blueprint experiment; the holdout rules in `tasks/COMMON_RULES.md` apply.

## 3. Public harnesses over Ollama: what works

- **lm-evaluation-harness** talks to Ollama through `local-chat-completions` with `base_url=http://127.0.0.1:11434/v1/chat/completions` and `--apply_chat_template`. Generative tasks (GSM8K, HumanEval-style) work; log-probability tasks (MMLU, HellaSwag) do not over the chat endpoint, because it returns no logprobs. For those, point the harness at a `llama-server` (which exposes logprobs) or use its `gguf` backend. The `/v1` root alone 404s; use the full path. (S113, S114; Ollama's `/v1/models` answered on this PC, LOCAL)
- **BFCL v4** (`bfcl-eval` on PyPI) is `bfcl generate` then `bfcl evaluate`; its local backends are vLLM and SGLang, and any running OpenAI-compatible server can be used with `--skip-server-setup` and `REMOTE_OPENAI_BASE_URL`. Not confirmed against Ollama. Its AST track scores tool-call syntax and arguments deterministically; the irrelevance bucket scores "should not call". (S115)
- **τ-bench, ToolBench, AgentBench**: nothing found that runs locally without a large setup; skip until a need appears.
- Neither package is installed in any venv here; installing either is a tool-gatekeeper question with the role "public benchmark runner".

## 4. Deterministic tool-call scoring (the missing layer)

Vendor eval guides converge on the same checks, none of which needs an LLM judge: tool name exact match, required parameters present, parameter types and values match, call order where it matters, and correct abstention on items that need no tool. (S117, S118, vendor docs) The set for this PC should be built from real traffic: the night-shift runner's tool calls (vault search, hub MCP, Paperclip reads), the agent presets' tool schemas, and 10 negatives. Score = exact match on name plus argument validation; report per-tool.

## 5. What to build before implementing anything

1. A `quant-eval` bundle: a script that takes an Ollama tag and runs evalrun on ticker-extract-v2 and code-repair-choice-v1 dev splits plus the tool-call set, writing one JSON of scores. This is the acceptance test for any quant, any blueprint, and any fine-tune export.
2. The tool-call set itself (30 to 50 items), reviewed by the owner since it encodes what "correct" means for the agents.
3. A results note per run in the vault, with the Ollama tag, the GGUF hash, and the three layers' numbers side by side. Experiment 001's note is the template.

## 6. Cautions

- Multiple-choice benchmarks are not robust to option order and formatting (S119); the owner's JSON tasks avoid this.
- KL and task scores can disagree (a thread in S95 cites a model with better KL doing worse on LiveCodeBench); when they do, the task score decides.
- Keep thinking mode off in evals unless the job uses it; it changes both cost and scores.
