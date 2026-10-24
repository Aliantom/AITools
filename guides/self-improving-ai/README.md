# Self-Improving AI: Research Guide

> **TL;DR:** A map of the research on AI systems that improve themselves, centered on the Darwin Gödel Machine (DGM) and its relatives. It covers what each method does, which ones work with API-only models, and where to start if you want to build one.
> **Use when:** you want to understand or build a self-improving agent loop  ·  **Works with:** any LLM (API-only methods) or open-weight models (training methods)  ·  **Updated:** October 2026

**Files in this guide**

| File | What it is |
| --- | --- |
| [reading-list.md](reading-list.md) | Every paper with its arXiv link and code repo, grouped by category |
| [../../prompts/patterns/research-to-project-analysis.md](../../prompts/patterns/research-to-project-analysis.md) | A staged prompt that has an AI deep-read these papers and adapt them to your project |
| [../../cheatsheets/self-improving-ai-discord.md](../../cheatsheets/self-improving-ai-discord.md) | The reading list formatted to paste into a single Discord message |

---

## 1. The one idea to remember

Every self-improving system is a loop with four parts:

1. **Something mutable.** Prompts, agent code, tools, model weights, or the improver itself.
2. **A proposer.** Usually an LLM that suggests a change.
3. **An evaluator.** A benchmark, test suite or scoring script that decides whether the change helped.
4. **A selection rule.** Which variants to keep and which to build on next.

The evaluator is the part that decides whether the whole thing works. A loop can only improve what it can measure, and a weak evaluator gets gamed (DGM's own paper reports cases of objective hacking). The July 2026 RSI survey (arXiv 2607.07663) finds that demonstrated self-improvement strength tracks how reliable the evaluation signal is.

---

## 2. The lineage in one picture

```
Gödel Machine (2003)          theory: accept only provably beneficial self-rewrites
        │  proofs are impossible in practice → replace them with benchmarks
        ▼
STOP (2023) · Gödel Agent (2024) · ADAS (2024)     first LLM-era loops
        │  ADAS: meta-agent + archive of agents
        ▼
SICA (2025) ─────────── Darwin Gödel Machine (2025)
  agent edits its own     agent edits its own code + open-ended ARCHIVE
  codebase                of every variant as "stepping stones"
                                 │
              ┌──────────────────┴──────────────────┐
              ▼                                     ▼
   Huxley-Gödel Machine (2025)              Hyperagents / DGM-H (2026)
   picks parents by how good their          makes the meta-agent itself
   DESCENDANTS turn out (clade score)       editable → works beyond coding
```

A parallel branch evolves single programs rather than whole agents: **FunSearch → AlphaEvolve → OpenEvolve / ShinkaEvolve**.

---

## 3. The methods at a glance

### DGM family (closest relatives)

| Method | What it adds | Notes |
| --- | --- | --- |
| **Gödel Machine** | The theoretical origin: only accept self-modifications that are provably beneficial. | Theory only; proofs are infeasible in practice. |
| **Darwin Gödel Machine** | Swaps proofs for empirical benchmark checks and keeps an archive of every agent variant. Raised SWE-bench from 20% to 50%. | ICLR 2026. The reference implementation. |
| **Huxley-Gödel Machine** | Scores an agent by its descendants' results (clade-level metaproductivity) and picks what to expand with Thompson sampling. More compute-efficient than DGM. | Built on the DGM codebase. ICLR 2026 oral. |
| **Hyperagents (DGM-H)** | Puts the task agent and the meta agent in one editable program, so the system improves how it improves. Works on non-coding tasks (paper review, robotics reward design, math grading). | Meta, March 2026. |
| **Gödel Agent** | Self-referential agent that patches its own running code. No archive. | Smallest codebase to read. |
| **SICA** | A coding agent that edits its own full codebase; no separate meta-agent. SWE-bench subset 17% → 53%. | Models set in `base_agent/src/config.py`. |
| **STOP** | A scaffold that improves the scaffold that improves code. | Early, minimal. |

### Agent design

| Method | What it adds |
| --- | --- |
| **ADAS** | A meta-agent writes new agents as code and keeps an archive. DGM's direct predecessor. |
| **Promptbreeder** | Evolves prompts and also the prompts that mutate them. |
| **Voyager** | A lifelong-learning agent that grows a skill library of code. |

### Evolutionary code search

| Method | What it adds |
| --- | --- |
| **FunSearch** | LLM + evaluator in an evolutionary loop over programs (Nature, 2023). |
| **AlphaEvolve** | Scaled-up successor; its discoveries fed back into Google's own infrastructure. Closed, private preview. |
| **OpenEvolve** | Open-source AlphaEvolve reimplementation. Works with any OpenAI-compatible endpoint. |
| **ShinkaEvolve** | Sample-efficient alternative from Sakana; beat AlphaEvolve's circle-packing result in about 150 evaluations. ICLR 2026. |
| **ELM / OpenELM** | The early paper that used LLMs as mutation operators. |

### Training-time (needs model weights)

| Method | What it adds |
| --- | --- |
| **STaR** | Trains on its own correct reasoning traces. |
| **Self-Rewarding LMs** | The model judges its own outputs for preference training. |
| **SEAL** | The model writes its own fine-tuning data and update directives. Paper runs on 2× A100/H100. |
| **Absolute Zero** | Zero-data self-play: the model proposes and solves its own tasks. |

### Open-endedness and automated research

| Method | What it adds |
| --- | --- |
| **AI-Generating Algorithms** | Jeff Clune's roadmap; the philosophy behind DGM. |
| **POET** | Co-evolves environments and agents; origin of the "stepping stones" idea. |
| **OMNI-EPIC** | LLMs generate an endless curriculum of interesting tasks. |
| **AI Scientist v1/v2** | End-to-end automated research papers. |

Links for all of these are in [reading-list.md](reading-list.md).

---

## 4. Which methods work with which models

The deciding question is whether a method changes things **around** a frozen model or changes **the model's weights**.

| Model type | Examples | Usable methods |
| --- | --- | --- |
| API-only | GPT-5.4, Claude Sonnet | DGM, HGM, Hyperagents, SICA, Gödel Agent, ADAS, OpenEvolve, ShinkaEvolve, Promptbreeder-style prompt evolution |
| Open-weight, large | Poolside Laguna M.1 (225B MoE, 23B active) | All of the above via API; training methods need a multi-GPU server |
| Open-weight, small | 7–14B models | Everything, including STaR / SEAL / Absolute Zero with LoRA on a consumer GPU |

### Suggested role split

Every loop has a **proposer** (called rarely, needs to reason well) and a **task agent** (evaluated many times, where the cost piles up).

- **Proposer / meta-agent:** the strongest reasoning model you have (e.g. GPT-5.4).
- **Task agent:** a cheap or free coding model (e.g. Laguna via OpenRouter; check current rate limits).
- **Cross-check:** run the best agent on a second model (e.g. Claude Sonnet). If the gains survive the swap, they're real and not tuned to one model's quirks. HGM reports its agents transferring across backbone models.

---

## 5. Where to start

| Goal | Start with | Why |
| --- | --- | --- |
| Optimize one function or algorithm | **OpenEvolve** | `pip install openevolve`, point it at an OpenAI-compatible endpoint, write a scoring script. Lowest setup cost. |
| Build a self-improving coding agent | **HGM** | DGM's codebase with smarter, cheaper parent selection. |
| Self-improve on a non-coding task | **Hyperagents** | Designed for domains where coding skill ≠ improvement skill. |
| Understand the mechanics by reading code | **Gödel Agent**, then **SICA** | Small, readable codebases. |

### Suggested reading order

1. Darwin Gödel Machine (the anchor)
2. ADAS (where the archive idea came from)
3. Huxley-Gödel Machine (better selection)
4. Hyperagents (editable meta-agent, beyond coding)
5. ShinkaEvolve (efficiency tricks for evolutionary search)
6. The July 2026 RSI survey (to see the whole field and its failure modes)

---

## 6. Cost and safety notes

- **Start small.** Full DGM-scale SWE-bench runs cost a lot in API calls. Use a 20–50 task subset and a cheap task model until the loop works.
- **Sandbox everything.** These systems execute model-generated code. DGM, Hyperagents and SICA all ship Docker setups; use them.
- **Guard the evaluator.** Keep a held-out test set the loop never sees, and check that improvements on it match improvements on the training benchmark.
- **Human gates for real-world actions.** Anything that touches money, production systems or external services needs an approval step outside the loop.

---

## Sources

- Darwin Gödel Machine: <https://arxiv.org/abs/2505.22954>
- Huxley-Gödel Machine: <https://arxiv.org/abs/2510.21614>
- Hyperagents: <https://arxiv.org/abs/2603.19461>
- SICA: <https://arxiv.org/abs/2504.15228>
- ShinkaEvolve: <https://arxiv.org/abs/2509.19349>
- Recursive Self-Improvement survey: <https://arxiv.org/abs/2607.07663>
- Laguna M.1 model card: <https://huggingface.co/poolside/Laguna-M.1>
