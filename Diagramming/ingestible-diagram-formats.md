<!-- Generated from the Obsidian vault (Machine/Research/AI diagramming and reasoning maps). Edit the vault note, not this file: mirror_research.py overwrites it. -->

# Ingestible diagram formats

> **TL;DR:** Mermaid plus a legend table is the default AI-readable diagram format; Structurizr for C4, JSON Canvas for Obsidian, repo maps for code; validate-and-repair lifts Mermaid from ~70% to ~100% valid.
> **Source:** Web research 2026-11-04 (diagram-as-code comparisons, MermaidSeqBench, Mermaid repair studies, JSON Canvas spec, Aider repo map, llms.txt adoption) plus the owner's AITools diagram guide  ·  **Project:** AI workstation  ·  **Updated:** 2026-11-04

"Ingestible" means a model receives the diagram as text with explicit structure. A PNG is opaque to a text model and lossy even to a vision model. Everything below is text.

## 1. Format comparison

| Format | What it is | AI reads it | AI writes it | Metadata it can carry | Renders where | Best for | Label |
|---|---|---|---|---|---|---|---|
| **Mermaid** | Text DSL for flowcharts, sequence, class, state, ER, Gantt, mindmap, C4-ish | Yes, fluently | Yes, with repairable syntax errors | Node ids, labels, `classDef` styles, `click` links, subgraphs, YAML front matter (title, config), accessibility `accTitle`/`accDescr` | GitHub, GitLab (5,000-char cap), Obsidian, most docs tools | Default for everything | D18, D19, D36 |
| **Graphviz DOT** | Graph description language | Yes | Yes | Arbitrary key=value attributes on nodes and edges (the richest metadata) | Needs Graphviz | Large node-edge graphs, generated from data | D19 |
| **PlantUML** | UML text DSL | Yes | Yes, more syntax than Mermaid | Notes, stereotypes, skinparams | Needs a server or plugin | Detailed UML | D19 |
| **D2** | Modern diagram language with a constraint layout engine | Yes | Yes | Classes, labels, links, nested containers | D2 CLI | Cleaner auto-layout than Mermaid | D19 (vendor-adjacent) |
| **Structurizr DSL** | C4 model as code: model once, derive context/container/component views | Medium | Medium (less training data) | Full element metadata (technology, tags, properties, docs, ADR links) | Structurizr tools | Architecture models that must stay consistent | D18, D19 |
| **JSON Canvas** (`.canvas`) | Obsidian's open whiteboard format: nodes (text, file, link, group) and edges, MIT, v1.0 | Yes (plain JSON) | Yes | Node ids, types, positions, colors, edge labels and ends; file nodes link to notes | Obsidian, Kinopio, others | Thinking boards inside the vault | D20 |
| **Excalidraw JSON** | Whiteboard scene JSON | Yes, verbose | Poorly | Element ids, text, bound elements, custom data | Excalidraw | Sketches; convert to Mermaid for AI use | D18 |
| **draw.io XML** | Diagram XML (mxGraph) | Yes, verbose | Poorly | Cell attributes, arbitrary key=value on cells | draw.io | Legacy diagrams | MEMORY |
| **BPMN 2.0 XML**, **SysML v2** | Process and systems modelling standards | Yes, verbose | Poorly | Rich typed semantics | Specialist tools | Formal processes | MEMORY |
| **ONNX graph** (Netron) | The model itself as a graph; QDQ nodes mark quantization | Yes (protobuf to JSON) | n/a | Op types, shapes, quant params | Netron | Reading what a quantizer did | D38 |
| **Repo map** (Aider style) | Ranked tree of files, symbols and references built with tree-sitter and personalized PageRank | Yes, designed for it | n/a (generated) | Definitions, references, rank, token budget | Text | Giving a coding agent the shape of a codebase | D21 |
| **llms.txt** | A curated markdown index of a site for AI readers | Yes | n/a | Links with descriptions | Text | Documentation sites; adoption 6 to 10%, benefit contested | D22 |

## 2. The pattern that works: diagram plus legend table

From the owner's own guide (D36) and consistent with every comparison read: Mermaid encodes topology well and everything else badly. Keep the diagram to nodes and edges with short ids, and put the substance in a Markdown table keyed to those ids (purpose, owner, technology, state, links). The table is what the AI retrieves and reasons over; the diagram is what the human and the AI use for shape. Rules from the guide that still hold:

- One diagram per level (context, containers, components), one file each, plus an `index.md` that routes.
- Stay under about 40 to 50 nodes per diagram; Mermaid's layout degrades past that and GitLab stops rendering at 5,000 characters.
- Short node ids, no prose in nodes, quote labels that contain punctuation (`A["Vault (git)"]`), which removes the most common syntax failure (D17).
- Generate from a source of truth (code, config, the vault's topic pages), never by hand twice.

## 3. Metadata "for AI" in a diagram

What people mean by it, and what is real:
- **Ids and typed attributes** (DOT attributes, Structurizr properties, JSON Canvas node types) are the metadata a model can use. Mermaid's are thinner: `classDef` classes, `click` URLs, subgraph membership, and YAML front matter with `title` and config. The accessibility fields `accTitle` and `accDescr` are a legitimate place for a one-line machine-readable summary. (MEMORY for Mermaid syntax; formats' metadata from D18 to D20)
- **The legend table** is the richest metadata channel and the one every model reads perfectly, because it is a table.
- **Links back to sources** (`click` in Mermaid, file nodes in JSON Canvas, wikilinks in the legend) turn a diagram into a navigation structure, which is what retrieval needs.

## 4. Generating diagrams with models

- MermaidSeqBench (NeurIPS 2025 workshop, 132 NL-to-sequence-diagram pairs) scores syntax, activation handling, error handling and usability with an LLM judge; judge choice shifts scores. (D13)
- Recurrent failures: inconsistent activation markers, malformed error handling, incomplete output; unquoted labels with brackets. (D14, D17)
- Fix: validate with the Mermaid parser and feed the error back; models repair their own syntax most of the time; a validation agent with the full syntax reference in the system prompt raised validity from about 70% to near 100%. (D15, D16)
- No published results by model size were found; small local models will need the repair loop more. (gap)

## 5. Code as a diagram: the repo map

Aider's repo map parses every file with tree-sitter, builds a graph where files are nodes and shared identifiers are edges, ranks with personalized PageRank biased toward files in the conversation, and renders the top symbols within a token budget. Independent reimplementations exist (pyrepomap, RepoMapper). It is the most-used "ingestible diagram" in coding agents and the one with the clearest effect: the agent sees the shape of the codebase without reading it. (D21)

## 6. Rules for this PC

1. Mermaid plus legend table, generated from sources, for every system map in the vault.
2. Front matter on the note (not inside the Mermaid block) carries `type`, `description`, `sources`, so the vault index and `ai-notes` find it.
3. JSON Canvas for thinking boards the owner makes in Obsidian; agents can read `.canvas` files as JSON.
4. Add a Mermaid validation step to any agent that writes diagrams (the `mmdc` CLI or a parser call), with one repair retry.
5. A repo-map style summary for the local coding agent (opencode on qwen3.5) is the highest-value "diagram" to try first; see [Applying diagrams and maps to this system](applying-diagrams-and-maps-to-this-system.md).
