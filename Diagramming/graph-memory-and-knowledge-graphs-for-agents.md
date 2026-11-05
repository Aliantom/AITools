<!-- Generated from the Obsidian vault (Machine/Research/AI diagramming and reasoning maps). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Graph memory and knowledge graphs for agents

> **TL;DR:** Graph memory (typed, temporal nodes and edges) is where 'intelligence over time' can accumulate, STRATA and procedural graphs show self-maintained experience graphs beating flat memories on agent benchmarks (self-reported), but a 2026 line of work finds simple retrieval matches elaborate hierarchies and graph memory is a poisoning surface; the vault already chose hybrid search, so the move here is a typed experience graph on top of it, not a new memory product.
> **Source:** Web research 2026-11-04: Zep (2501.13956), Mem0/Zep comparisons, STRATA (2610.19386), MEGA (2608.10504), Procedural Graphs (2609.09153), self-improvement survey (2607.13104), ACE (2510.04618), Memanto, agentic context management (2607.21503), selection integrity (2606.12290); the vault's Agentic graphs report  ·  **Project:** AI workstation  ·  **Updated:** 2026-11-04

## 1. The landscape

| System | Shape | Claim | Label |
|---|---|---|---|
| Zep / Graphiti | Temporal knowledge graph: facts with validity intervals, live ingestion, belief revision | Published architecture paper; Zep CE reportedly deprecated, check before adopting | D23, D24 |
| Mem0 | Vector store plus optional graph; tracks preference changes | Vendor-reported speed and token savings | D25 |
| Cognee, Letta | Graph-and-vector memory; Letta's memory blocks | Practitioner comparisons | D26 |
| GraphRAG (Microsoft) | Batch-built entity graph with community summaries over a static corpus | Good for global questions; costly to build and refresh | D24 |
| STRATA (2026) | Three-layer self-maintained experience graph: atomic skills and code snippets, task workflows, generalized meta-frameworks, typed edges | Best average among memory-augmented methods on four agent benchmarks (self-reported) | D30 |
| MEGA (2026) | "Wisdom graph" as self-evolving agent optimization infrastructure | Preprint | D31 |
| Procedural Graphs (2026) | Execution structures that evolve from experience | Preprint | D32 |
| ACE (2025) | Flat playbook of bullet strategies evolved by generator, reflector, curator | +10.6% average on agents; no labels needed; already in the vault's self-improvement plan | D34 |
| Memanto, temporal semantic memory, PersonalAI 2.0 (2026) | Typed, information-theoretic or temporal retrieval | Preprints | D28 |

## 2. What the critical literature says

- **Cost of graph extraction.** A 2026 paper argues graph-augmented memory adds an LLM extraction step on every insert and that simpler retrieval matches elaborate hierarchies on current benchmarks. (D29)
- **Selection integrity.** Retrieval that is blind to information flow can accumulate wrong facts; a 2026 paper proposes an accumulability criterion for graph memory. (D27)
- **Poisoning.** "Oracle poisoning" shows corrupted knowledge graphs weaponize agent reasoning; anything that writes to memory from untrusted text is an attack surface. (D40, title via summary)
- **The vault's own review** (2026-11-02): keep hybrid search for vault memory, test link expansion and an `as_of` option on a harder eval, no new memory product. (D37)

## 3. Where "intelligence over time" can actually accumulate

The honest answer: not in the weights (no training signal from daily use) and not in a bigger prompt (context is finite and expensive on this card). It accumulates in **structured, typed, retrievable experience**: what worked, under which conditions, with evidence, linked to the code and notes that implement it. That is a graph whether or not a product is bought. The vault already is one (notes as nodes, wikilinks and front matter as typed edges, `verified` dates as temporal validity). STRATA's three layers map onto it cleanly: skills and snippets (Machine/Workflows SKILL files), task workflows (FINDINGS entries), meta-frameworks (Decisions and topic pages).

## 4. Rules for this PC

1. No new memory product. The role "facts live in the vault" has an owner.
2. Add typed edges where they are missing: `depends_on`, `supersedes`, `evidence_for` in front matter, so the graph is queryable by `ai-notes` and renderable as Mermaid.
3. Treat every automated write to the graph as untrusted until a deterministic check or the owner confirms it (the vault's "numbers come from scripts" rule generalizes).
4. Measure before believing: a retrieval eval on the vault exists (`Machine/Research/Vault AI optimization/retrieval_eval.py`); any graph-memory change runs through it.
