<!-- Generated from the Obsidian vault (Machine/Research/AI diagramming and reasoning maps). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# AI diagramming and reasoning maps: overview

> **TL;DR:** Start page: diagrams and reasoning maps help an AI when they are text with structure (Mermaid plus a legend table, DAG-shaped reasoning records, repo maps, typed graph memory), the measured gains are largest for small and quantized local models that cannot hold the structure themselves, and the first local experiments are listed.
> **Source:** Owner request 2026-11-04: can AI-ingestible diagramming, system logic flow and thought-process mapping be tuned to improve intelligence now and over time, and how does that go hand in hand with quantization  ·  **Project:** AI workstation  ·  **Updated:** 2026-11-04

**Where this lives.** Vault folder `Machine/Research/AI diagramming and reasoning maps/`, mirrored hourly to `Aliantom/AITools` under `Diagramming/` by the same script as the Quantization folder. Edit here, not in the repo.

## The question, restated

The owner asked three things: (1) which diagram formats an AI can actually ingest, and what "metadata for AI" in a diagram means; (2) whether mapping system logic and thought processes as diagrams can be tuned to make the AI on this PC smarter, now or over time; (3) how this connects with quantization.

## The one idea

An AI reads structure, not pictures. A diagram helps a model only when it reaches the model as text with explicit nodes, edges and attributes (Mermaid, DOT, JSON Canvas, a repo map, a typed knowledge graph), and when the facts that matter sit in a table keyed to node ids rather than in the drawing. Once a diagram is structure, it does three jobs: it is **context** (a compressed, navigable description of a system), it is a **scaffold** (a procedure or decision structure the model follows instead of inventing), and it is **memory** (a graph of what worked that grows over time). Each job has measured evidence, and the evidence says the gains are largest for small models, which is exactly what a 4-bit 12B on this card is.

## The connection to quantization

1. **Quantization damages reasoning first, and scaffolds protect reasoning.** Low-bit models lose multi-step accuracy before they lose fluency (see the Quantization folder's reasoning note). Blueprints, templates and procedure retrieval give small models the plan so they only have to execute steps; those gains are reported precisely on small models. A good scaffold is cheaper than a bigger model and cheaper than a higher quant.
2. **Diagrams are token-efficient context.** A Mermaid map plus legend table says in 400 tokens what a prose description says in 2,000. On a card where context costs VRAM (the KV cache), compressed structure is memory saved.
3. **Quantization produces diagrams.** A sensitivity map (which tensors can take fewer bits) and a model's quantized graph (ONNX QDQ nodes, Netron) are diagrams the pipeline can emit and an AI can read when choosing a mix.
4. **Reasoning records are quantization tests.** Writing the model's reasoning as a DAG (DAG-Math's "logical closeness") gives a structural way to detect quantization damage that KL on text cannot see.

## Map of this folder

| Note | What it answers |
|---|---|
| [Ingestible diagram formats](ingestible-diagram-formats.md) | Which formats an AI reads well, what metadata they carry, how to structure them (the diagram-plus-legend pattern), limits and tooling. |
| [Reasoning maps and thought structures](reasoning-maps-and-thought-structures.md) | Chains, trees, graphs and diagrams of thought; templates and blueprints; what is measured, what works for small models. |
| [Graph memory and knowledge graphs for agents](graph-memory-and-knowledge-graphs-for-agents.md) | Zep/Graphiti, Mem0, Cognee, GraphRAG, STRATA, procedural graphs; evidence, risks, and what the vault already decided. |
| [Applying diagrams and maps to this system](applying-diagrams-and-maps-to-this-system.md) | Concrete, pre-registrable experiments and artefacts for this PC, ordered by value. |
| [AI diagramming sources](ai-diagramming-sources.md) | Source register with evidence labels. |
| [AI diagramming research log](ai-diagramming-research-log.md) | Dated log and open questions. |

## What already exists here

- `AITools/ai-generated-architecture-diagrams (1).md`: the owner's guide to layered Mermaid maps with legend tables and a routing index, written for GitLab's 5,000-character Mermaid cap. Its "diagram plus legend table" pattern is the right one and this folder builds on it.
- `Machine/Research/Agentic graphs/`: the 2026-11-02 study that concluded "no default multi-agent graphs; deterministic gates, a step ledger, GEPA-style prompt evolution, hybrid vault search". This folder does not reopen that; it adds the diagram and memory layer underneath it.
- The vault itself: topic pages, briefs and wikilinks are already a knowledge graph; Obsidian's graph view and `.canvas` files are the visual side.
