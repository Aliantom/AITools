# AITools

**A working library of guidance, prompts, agent personas and tooling for getting real work out of AI models.**

This repo collects what actually works when using AI assistants (mostly Claude and Claude Code, but much of it is model-agnostic): reference guides, copy-paste system prompts, agent packs, prompt patterns, and small scripts that make agents more reliable. Everything here is written to be *used*, not just read: each entry should be something you can paste, install, or follow today.

> **Status:** early and growing. Content is added as it gets battle-tested. Things move fast in this space, so every guide carries the date it was written; check version-specific details against current docs.

---

## Contents

- [Quick start](#quick-start)
- [Catalog](#catalog)
- [How to use each kind of resource](#how-to-use-each-kind-of-resource)
- [Core principles](#core-principles)
- [Planned layout](#planned-layout)
- [Roadmap](#roadmap)
- [Contributing and conventions](#contributing-and-conventions)
- [Disclaimer](#disclaimer)

---

## Quick start

| I want to… | Start here |
| --- | --- |
| Get better results from Claude Code today | [Prompting Claude Code](prompting-claude-code.md), §1 "Start Here" (the five rules) |
| Give Claude a specialist role (reviewer, debugger, architect…) | [Computer Science Agent Pack](cs-agent-pack) |
| Get a rigorous UX/UI teardown of a website | [UX/UI Architect Prime](UX-UI%20Architect%20Prime) system prompt |
| Make an agent's output precise instead of vague | [Mathematical constraints](Mathematical-constraints) |
| Generate architecture diagrams that render in GitLab | [AI-generated architecture diagrams](ai-generated-architecture-diagrams%20%281%29.md) |
| Run an agent unattended in a loop with guardrails | [run-agent-loop](run-agent-loop%20%281%29.md) |

---

## Catalog

### 📘 Guides and references

Long-form, opinionated write-ups on a single topic.

| Resource | What it covers | Best for |
| --- | --- | --- |
| [**Prompting Claude Code**](prompting-claude-code.md) | Context engineering, CLAUDE.md, subagents, hooks, skills, MCP vs CLI tradeoffs, Explore→Plan→Code→Commit, TDD loops, headless mode, permissions and safety, ten task-specific prompt templates (bug fix, feature, refactor, review, migration, incident…), anti-patterns, model selection and cost control. | Anyone using Claude Code daily. The most complete document in the repo. |
| [**AI-Generated Architecture Diagrams for GitLab**](ai-generated-architecture-diagrams%20%281%29.md) | Why Mermaid wins for GitLab, why one mega-diagram fails (including GitLab's 5,000-character Mermaid limit), layered per-level diagram files with a routing index, and legend tables keyed to node IDs. | Turning a large codebase or context dump into diagrams both humans and AI can read. |
| [**Mathematical Constraints for Agents**](Mathematical-constraints) | Using complexity bounds, pre/postconditions (Hoare logic), queueing theory and Little's Law, workload distributions, and information theory to constrain what an agent generates, with storage-systems examples and a plain-language B+tree explainer. | Engineers who want precise, checkable specs instead of "make it fast." |

### 🎭 System prompts and personas

Drop-in roles that change how a model approaches a task.

| Resource | What it does | How to use |
| --- | --- | --- |
| [**UX/UI Architect Prime**](UX-UI%20Architect%20Prime) | A website redesign auditor grounded in Apple's HIG, Gestalt, Fitts's, Hick's and Miller's laws, and grid systems. Works in three phases (friction audit → user journey → fine-detail spec) and forces every recommendation into *Observation / Principle / Solution / Expected Impact*. Pushes back when a request contradicts proven design principles. | Paste as a system prompt or Claude Project instructions, then give it a URL, screenshot or page description. |

### 🤖 Agent packs

Collections of specialized agents for coding tools.

| Resource | What it is | Targets |
| --- | --- | --- |
| [**Computer Science Agent Pack**](cs-agent-pack) | 38 rigorous agent personas across builders, investigators, rigor & math, adversaries, operations, research & academia, and coordination. All share one rigor protocol: evidence over assertion, VERIFIED / REASONED / ASSUMED labels, no invented results, and stopping rather than breaking a hard rule. Includes suggested builder → adversary pairings. | Claude Code subagents and Kilo Code custom modes. |

> **Note:** the pack's README currently refers to `claude-code/agents/*.md` and `kilo-code/kilocodemodes.yaml`, which are not yet committed to this repo.

### 🛠️ Scripts and harnesses

| Resource | What it does | Notes |
| --- | --- | --- |
| [**run-agent-loop**](run-agent-loop%20%281%29.md) | A shell harness for running a coding agent repeatedly toward a goal, packaged as Markdown with three extraction methods (agent, `awk`, copy-paste) and a SHA-256 hash to verify the script arrived intact. | Wrapped in Markdown so it survives networks that block `.sh` downloads. |

---

## How to use each kind of resource

**Guides.** Read the TL;DR or "Start Here" section first; every guide is written so the top section stands alone. The rest is reference: jump to the section that matches your task.

**System prompts / personas.** Copy the full text into one of:
- a **Claude Project's** custom instructions (persistent across chats),
- the **system prompt** field of an API call, or
- the top of a chat, followed by `---` and your actual request.

**Claude Code subagents.** Agent files go in `.claude/agents/` (project-level, shared through git) or `~/.claude/agents/` (all your projects). Run `/agents` inside Claude Code to confirm they loaded, then either name one explicitly ("use the debugger agent to…") or let Claude delegate based on each agent's description.

**Scripts packaged as Markdown.** Some environments block script downloads, so scripts here may be wrapped in Markdown code fences. Each one documents how to extract it and how to verify it (hash plus `bash -n`). Always verify before running.

---

## Core principles

The ideas that keep showing up across everything in this repo:

1. **Context is a budget.** Output quality degrades as the context window fills. Feed the smallest set of high-signal information and start fresh sessions for new tasks.
2. **Give a runnable definition of done.** A test, build, lint, or screenshot the model can check itself beats any amount of instruction.
3. **Constrain precisely.** Invariants, bounds, schemas and output formats beat adjectives like "clean," "fast," or "robust."
4. **Separate building from checking.** Pair a builder with an adversary (developer → tester → reviewer) rather than asking one agent to grade its own work.
5. **Label certainty.** Ask models to distinguish what they verified from what they reasoned or assumed, and to stop rather than invent.
6. **Small, linked pieces beat one giant artifact.** Applies to diagrams, CLAUDE.md files, prompts and documentation alike.

---

## Planned layout

As the collection grows, files will move into topic folders. Target structure:

```
AITools/
├── guides/            # Long-form references (prompting, context engineering, diagrams…)
├── prompts/
│   ├── system/        # Personas and role prompts (e.g. UX/UI Architect Prime)
│   └── patterns/      # Reusable task templates (bug fix, code review, refactor…)
├── agents/            # Agent packs for Claude Code, Kilo Code and others
├── skills/            # Claude skills (SKILL.md folders)
├── scripts/           # Harnesses and helpers (agent loops, extraction tools)
├── mcp/               # MCP server notes, configs and examples
├── cheatsheets/       # One-page quick references
└── README.md
```

---

## Roadmap

Ideas queued for the collection:

- [ ] Reorganize existing files into the folder layout above and give every file a `.md` extension
- [ ] Commit the CS Agent Pack's agent files and Kilo Code modes
- [ ] Prompt pattern library: one file per reusable task template
- [ ] CLAUDE.md starter templates for common project types
- [ ] Skills: examples and authoring guide
- [ ] MCP: setup notes, server recommendations, and building a read-only server
- [ ] Hooks cookbook: deterministic guardrails for Claude Code
- [ ] Local models: running and prompting open-weight models on consumer GPUs
- [ ] Model selection cheatsheet: which model for which job, and what it costs
- [ ] Evaluating prompts: simple ways to A/B test a prompt change
- [ ] Glossary of AI and agent terms

---

## Contributing and conventions

This is a personal collection, but issues and pull requests with tested improvements are welcome.

**Every new entry should:**

1. **Be usable as-is.** Something to paste, install or follow, not a link dump.
2. **Open with a TL;DR** of three to five lines: what it is, when to use it, and the one thing to remember.
3. **Carry a date** (e.g. *Compiled October 2026*) and note anything version-specific.
4. **Show at least one concrete example** of the prompt or tool in use.
5. **Use a `.md` extension** and a lowercase, hyphenated file name (`code-review-prompt.md`, not `Code Review Prompt (1)`).
6. **Get a line in the [Catalog](#catalog)** above.

**Template for a new prompt:**

```markdown
# <Prompt name>

> **TL;DR:** <what it does, in one line>
> **Use when:** <situations>  ·  **Works with:** <models/tools>  ·  **Updated:** <month year>

## The prompt
<the full prompt in a code block>

## How to use it
<where to paste it, what inputs it expects>

## Example
<a short input and what good output looks like>

## Notes and limitations
<known failure modes, tuning tips>
```

---

## Disclaimer

These are practical notes from hands-on use, not official documentation. AI tools change weekly, so verify flags, limits and model names against current vendor docs before relying on them. Review any agent-generated code and any script before running it, especially anything that runs unattended or with elevated permissions.
