<!-- Generated from the Obsidian vault (Machine/Research/AI diagramming and reasoning maps). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# AI diagramming research log

> **TL;DR:** Dated log: first pass on 2026-11-04 established that text diagrams with legend tables and small-model scaffolds are the evidence-backed moves, found no study that tests scaffolds on quantized models, and queued five local experiments.
> **Source:** Running log for the AI diagramming and reasoning maps research; started 2026-11-04  ·  **Project:** AI workstation  ·  **Updated:** 2026-11-04

## 2026-11-04: first pass (Claude Code, Fable 5.1)

**Asked.** Whether AI-ingestible diagrams, system-logic maps and thought-process maps can be tuned to improve the AI on this PC, now and over time; what "ingestible metadata" means; how it connects to quantization.

**Done.** Eight searches (D1 to D40 in [AI diagramming sources](ai-diagramming-sources.md)); read the owner's diagram guide and the vault's agentic-graphs report; wrote the five notes in this folder; registered the folder with the GitHub mirror.

**Found.**
- Text formats only. Mermaid is the default; DOT and Structurizr carry richer metadata; JSON Canvas is the open Obsidian whiteboard format; the repo map is the proven code diagram.
- The substance goes in a legend table keyed to node ids (the owner's guide already says this; every comparison agrees).
- Small models gain from being handed the plan (Blueprints, ReasonFlux, instruction retrieval); graph-shaped reasoning pays only on decomposable problems; DAG-Math's step schema makes reasoning checkable.
- Graph memory products exist but the vault's own review keeps hybrid search; typed edges in front matter give most of the benefit with none of the extraction cost or poisoning surface.
- Mermaid generation errors are fixable with a parser-in-the-loop repair step (70% to near 100%).
- No paper tests scaffolds on quantized models; the link is reasoned and queued as a local experiment.

**Open questions.**
1. Does a blueprint raise gemma4:12b's extraction score more at a lower quant than at Q4_K_M? (Experiment 3 in the applied note; depends on quantization experiment 001.)
2. Small-model Mermaid validity rates (7B to 12B) are unpublished; measure with the local workers.
3. STRATA's three-layer graph: is any code released?
4. Zep CE deprecation: confirm status before anyone proposes it.
5. Read D1 (DoT) and D2 (DAG-Math) in full; the step schema is from a third-party summary.
6. Is there an Obsidian plugin or CLI that renders Mermaid from a `.canvas` file, for the map in experiment 1?
