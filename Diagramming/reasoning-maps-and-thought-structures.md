<!-- Generated from the Obsidian vault (Machine/Research/AI diagramming and reasoning maps). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Reasoning maps and thought structures

> **TL;DR:** Reasoning topologies (chain, tree, graph, DAG) trade cost for quality and GoT reports 62% better sorting at 31% lower cost than ToT; for small models the measured wins come from giving them the plan (blueprints, thought templates, retrieved procedures) rather than more search, and DAG-shaped reasoning records make reasoning checkable.
> **Source:** Web research 2026-11-04: Graph of Thoughts (AAAI 2024), Demystifying chains/trees/graphs (2401.14295), Diagram of Thought (2409.10038), DAG-Math (ICLR 2026), Blueprints (ICML 2025), ReasonFlux, SMART, instruction retrieval (2510.13935), TemplateRL, structured templates scaling (2508.19069), self-structured reasoning (2601.03597), position paper 2605.02452  ·  **Project:** AI workstation  ·  **Updated:** 2026-11-04

Two different things hide under "thought-process mapping": (a) **topologies**, the shape the model's reasoning takes at inference time (chain, tree, graph), and (b) **scaffolds**, structures given to the model in advance (templates, blueprints, procedures, decision rules). The evidence for (b) on small models is stronger and cheaper than for (a).

## 1. Topologies

| Structure | Idea | Reported result | Cost | Label |
|---|---|---|---|---|
| Chain of Thought | Write intermediate steps | The baseline every reasoning model now trains on | 1 pass | MEMORY |
| Self-consistency | Sample many chains, vote | Reliable gains on math; costs N passes | N passes | MEMORY |
| Tree of Thoughts | Branch, evaluate, backtrack | Solves search-like puzzles CoT cannot | Many passes | MEMORY |
| Graph of Thoughts (AAAI 2024) | Thoughts as vertices, dependencies as edges; merge and refine | 62% better sorting quality than ToT at 31% lower cost | Many passes, but fewer than ToT | D3 |
| Hierarchical GoT, Knowledge GoT, Adaptive GoT (2025) | Layered or labelled graphs; pick chain/tree/graph at test time | Secondary summaries only | varies | D3 secondary |
| Diagram of Thought (2024) | One model builds and walks a DAG of propose, critique, refine, summarize using role tokens; no external controller | Theory and small demos; the "colimit" framing is category theory, not a benchmark | 1 pass, longer | D1 |
| DAG-Math (ICLR 2026) | Models CoT as a rule-based stochastic process over DAGs; each step records id, justification, parents, conclusion; "logical closeness" measures whether a derivation follows the DAG | An evaluation framework, not a prompting trick; useful as a format | n/a | D2 |
| Self-structured reasoning (Jan 2026) | Lets a general-domain model choose chain vs graph structure itself | Reference list only seen | n/a | D5 |
| Taxonomy ("Demystifying…", 2024/26) | Reasoning topologies as a design space | Useful vocabulary | n/a | D4 |

What to take from this: graph-shaped reasoning pays when the problem decomposes and recombines (sorting, merging, planning with shared subgoals). On sequential, state-dependent work the vault's agentic-graphs study found topology changes lose, and that holds for reasoning graphs as it did for agent graphs. (D37)

## 2. Scaffolds for small models (the part that applies here)

| Method | Idea | Reported result | Label |
|---|---|---|---|
| Blueprints + prompt template search (ICML 2025) | A large model writes reusable step-by-step guides; a search picks the prompt layout the small model is least sensitive to; no fine-tuning | Consistent gains for small models across math, coding and reasoning | D7 |
| ReasonFlux | A library of about 500 thought templates with hierarchical retrieval | Small models guided by templates beat larger models reasoning directly (math) | D8 |
| SMART | A large model intervenes only at the steps where a small model goes wrong | Framed as policy search; targeted help beats a fixed template | D9 |
| Instruction retrieval at inference (2025) | Small models fetch step-by-step procedures from a store | More maintainable and auditable than baking procedures into weights | D10 |
| TemplateRL | Train with structured templates in the RL loop | Training-time, not inference-only | D11 |
| Structured solution templates by difficulty (2025) | Curriculum of templates | Training-time | D12 |

Pattern: the small model's weakness is planning and staying on plan, not executing a step. Hand it the plan (a blueprint, a template, a retrieved procedure, a checklist) and it executes. This is exactly the capability quantization erodes first, so scaffolds are the cheapest compensation for a 4-bit worker.

## 3. Making reasoning readable: the DAG record

DAG-Math's step format (id, justification, parents, conclusion) is a small, enforceable schema. If the local workers' reasoning for a task is emitted in that shape:
- a deterministic checker can verify that every conclusion cites existing parents (no dangling steps) and that the final answer's ancestors form a connected DAG;
- the record renders as a Mermaid graph for the owner;
- two quantizations of the same model can be compared by how often their DAGs stay "logically close", a structural test KL on text does not give.
The format costs tokens, so it belongs on hard tasks and evaluations, not every call.

## 4. What is not supported

- No study found measures reasoning scaffolds on quantized models specifically. The link to quantization in this folder is reasoned from two separate literatures (scaffolds help small models; quantization hurts reasoning), and the local experiment in [Applying diagrams and maps to this system](applying-diagrams-and-maps-to-this-system.md) is designed to test it.
- Multi-agent debate and heavy search topologies are not recommended by the vault's own evidence review. (D37)
