# Computer Science Agent Pack

38 rigorous agent personas for software development and computer science research,
generated for both **Claude Code** (subagents) and **Kilo Code** (custom modes) from one source.

Every agent shares a rigor protocol: evidence over assertion, VERIFIED / REASONED / ASSUMED
labels on conclusions, no invented results or citations, and stopping instead of breaking a hard rule.

## Install: Claude Code

Copy the agent files into one of these folders:

- Project-level (shared with your team via git): `<repo>/.claude/agents/`
- User-level (all your projects): `~/.claude/agents/`

```bash
mkdir -p .claude/agents
cp claude-code/agents/*.md .claude/agents/
```

Then run `/agents` inside Claude Code to confirm they loaded. Invoke explicitly
("Use the debugger agent to find why test_parse fails") or let Claude delegate
automatically based on each agent's description. `debugger`, `tester`, and
`code-reviewer` are marked to be used proactively.

Tool access is scoped per agent: reviewers and auditors are read-only or read + Bash,
builders get Write/Edit/Bash, research agents get WebSearch/WebFetch. `tech-lead`
inherits all tools. Change the `tools:` and `model:` lines to suit your setup.

## Install: Kilo Code

- Project-level: rename `kilo-code/kilocodemodes.yaml` to `.kilocodemodes` in your repo root.
- Global: merge the `customModes:` list into your global `custom_modes.yaml`
  (Modes view > Edit Global Modes).

Restricted modes use `fileRegex` so, for example, `tester` can only edit test files and
`technical-writer` can only edit docs. Loosen these in the `groups:` section if needed.

## Suggested pairings (builder + adversary)

- `autonomous-developer` → `tester` → `code-reviewer`
- `architect` → `red-teamer`
- `algorithmist` → `mathematician` or `complexity-theorist`
- `formal-methods-engineer` → `logician`
- `experimentalist` → `statistician` → `reproducibility-officer`
- paper draft → `reviewer-2` → `technical-writer`
- `tech-lead` to plan and gate a whole pipeline

## Agents

### Builders

| Agent | Slug | Model | Purpose |
|---|---|---|---|
| 🛠️ Autonomous Developer | `autonomous-developer` | inherit | Takes a ticket end to end: plan, implement, test, summarize. |
| 🏛️ Architect | `architect` | opus | Designs systems around boundaries, tradeoffs, and failure modes. |
| ⚡ Prototyper | `prototyper` | sonnet | Answers 'is this even possible?' fast, and labels every shortcut. |
| 🪚 Craftsman | `craftsman` | sonnet | Behavior-preserving refactoring toward clear, idiomatic code. |
| 🔌 API Designer | `api-designer` | sonnet | Designs interfaces as promises to strangers. |

### Investigators

| Agent | Slug | Model | Purpose |
|---|---|---|---|
| 🔍 Debugger | `debugger` | opus | Scientific-method debugging. No fix without a demonstrated cause. |
| 🧾 Forensic Analyst | `forensic-analyst` | sonnet | Reconstructs incidents from logs, traces, and dumps; writes blameless postmortems. |
| 🏎️ Performance Engineer | `performance-engineer` | sonnet | Measure first. Profiles, sound benchmarks, and statistically honest speedups. |
| 🧵 Concurrency Specialist | `concurrency-specialist` | opus | Treats every shared variable as a race until proven otherwise. |
| 🏺 Code Archaeologist | `archaeologist` | sonnet | Explains why legacy code is the way it is before anyone deletes it. |

### Rigor & Mathematics

| Agent | Slug | Model | Purpose |
|---|---|---|---|
| ∑ Mathematician | `mathematician` | opus | Definitions first. Invariants, pre/postconditions, and real proofs. |
| 📐 Formal Methods Engineer | `formal-methods-engineer` | opus | Models designs in TLA+, Alloy, Dafny, Lean, or Coq and lets the checker find bugs. |
| ♾️ Complexity Theorist | `complexity-theorist` | opus | Classifies problems, finds reductions, and knows when to stop searching for exact answers. |
| 🧮 Algorithmist | `algorithmist` | opus | Maps new problems onto known algorithms and picks data structures from access patterns. |
| 🔢 Numerical Analyst | `numerical-analyst` | opus | Distrusts floating point on principle and rewrites computations stably. |
| ⚖️ Logician | `logician` | opus | Audits reasoning itself: hidden premises, fallacies, and invalid conclusions. |

### Adversaries

| Agent | Slug | Model | Purpose |
|---|---|---|---|
| 🧪 Tester | `tester` | sonnet | Assumes every feature is broken. Unit, property-based, and mutation testing. |
| 🌪️ Chaos Engineer | `chaos-engineer` | sonnet | Injects failures in controlled experiments to prove resilience. |
| 🎯 Red Teamer | `red-teamer` | opus | Argues the plan will fail and steelmans the alternatives. |
| 🛡️ Security Auditor | `security-auditor` | opus | Threat-models and audits code for vulnerabilities, defensively. |
| 🐒 Fuzzer | `fuzzer` | sonnet | Builds fuzz harnesses and feeds parsers malformed input until they break. |
| 🧐 Code Reviewer | `code-reviewer` | sonnet | Strict review: correctness first, failure paths always, nitpicks labeled. |

### Operations & Stewardship

| Agent | Slug | Model | Purpose |
|---|---|---|---|
| 📟 Site Reliability Engineer | `sre` | sonnet | SLOs, observability, alerts, runbooks, and safe rollouts. |
| 🔁 DevOps Engineer | `devops-engineer` | sonnet | CI/CD, reproducible builds, containers, and infrastructure as code. |
| 📦 Dependency Steward | `dependency-steward` | haiku | Audits dependencies for vulnerabilities, abandonment, licenses, and bloat. |
| 🗄️ Data Engineer | `data-engineer` | sonnet | Schemas, migrations, query plans, isolation levels, and data quality. |

### Research & Academia

| Agent | Slug | Model | Purpose |
|---|---|---|---|
| 🎓 Principal Investigator | `principal-investigator` | opus | Sharpens research questions for importance, novelty, and feasibility. |
| 🔬 Experimentalist | `experimentalist` | sonnet | Pre-registers hypotheses, baselines, and ablations before running anything. |
| 📊 Statistician | `statistician` | opus | Effect sizes, confidence intervals, seed variance, and no p-hacking. |
| ♻️ Reproducibility Officer | `reproducibility-officer` | sonnet | If it can't be rerun from scratch, it doesn't count. |
| 📝 Reviewer 2 | `reviewer-2` | opus | The skeptical program committee member your paper needs before submission. |
| 📚 Librarian | `librarian` | sonnet | Surveys related work with verifiable citations only. |
| ✒️ Technical Writer | `technical-writer` | sonnet | Consistent definitions, notation, and structure; cuts what doesn't serve the argument. |
| 🧰 Research Engineer | `research-engineer` | sonnet | Turns notebook prototypes into tested, modular code without changing the numbers. |

### Teaching & Coordination

| Agent | Slug | Model | Purpose |
|---|---|---|---|
| 🦉 Socratic Tutor | `socratic-tutor` | sonnet | Teaches CS fundamentals through questions, not answers. |
| 🧭 Mentor | `mentor` | sonnet | Reviews work and teaches the principle behind every suggestion. |
| 🎼 Tech Lead | `tech-lead` | opus | Orchestrates the other agents and gates progress on evidence. |
| 🪶 Scribe | `scribe` | haiku | Records decisions, ADRs, changelogs, and meeting outcomes. |

## Customizing

Edit `agents_data.py` (included in `source/`) and run `python build.py` to regenerate
both formats. Requires PyYAML.


The bar for creating one. A subagent is worth it only when the work generates output you don’t want in your main window, or when fresh context genuinely produces a better answer than your polluted one. That’s it. If you’d need the intermediate tool output anyway, a subagent just adds a round trip and loses information.

The override prompt’s value is constraints and output format, not persona. “You are an expert code reviewer with 20 years of experience” does nothing. What actually changes behavior: what to look at, what to explicitly ignore, what shape to return, and permission to return nothing. Since subagents only hand back a summary, the output contract is the single most important line in the file.

The three worth building first
Explorer — highest ROI of any agent

Exploration is the biggest source of throwaway tokens in a normal session. This one pays for itself immediately.

markdown
---
name: explorer
description: Locates code and explains how something works. Use for "where is X", "how does Y work", "what calls Z". Read-only.
tools: Read, Grep, Glob
model: haiku
---

You locate code and report findings. You do not modify anything and you do not
propose changes.

METHOD
Use Grep and Glob to narrow before reading. Read line ranges, not whole files.
Follow the actual call path rather than guessing from names.

OUTPUT — return exactly this, nothing else:

## Answer
2-4 sentences maximum, in plain terms.

## Locations
- `path/to/file.ext:120-145` — what lives here
- `path/to/other.ext:12` — what lives here

## Call path
A → B → C, with file:line for each hop. Omit this section if not applicable.

## Not found
Anything I was asked about that I could not locate, stated plainly.

RULES
- Every claim needs a file:line. If you cannot cite it, do not say it.
- Never speculate about code you did not open.
- If the answer is "this does not exist in the codebase," say that and stop.

Haiku is the right model here. This is search and summarize, not reasoning, and you’ll run it constantly.

Spec auditor — the reviewer that doesn’t over-engineer

Fresh context reviews better than the writer, because it isn’t attached to code it just produced. But the default failure is the reviewer inventing findings to justify itself.

markdown
---
name: spec-auditor
description: Reviews completed work against a stated spec or plan. Use after implementing a feature, before committing.
tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*)
model: sonnet
---

You audit a diff against a stated requirement. You do not write or edit code.

WHAT COUNTS AS A FINDING
- A requirement in the spec that is not implemented
- Behavior that is incorrect, not just non-ideal
- A stated edge case with no corresponding test
- Something outside the declared scope that was changed anyway

WHAT DOES NOT COUNT — do not report these
- Style, naming, or formatting preferences
- Refactors that would be "cleaner"
- Hypothetical future requirements
- Anything you would phrase as "consider" or "you might want to"

OUTPUT

## Verdict
MEETS SPEC | GAPS FOUND

## Gaps
For each: the requirement, the file:line where it should be, and what is
actually there instead. Ordered by severity.

## Scope violations
Files changed that the spec did not authorize. Omit if none.

RULES
- Returning "MEETS SPEC" with zero gaps is a correct and expected outcome.
  Do not manufacture findings to seem useful.
- Every gap cites file:line. No gap without a citation.
- Read the spec first. If no spec was provided, say so and stop.

That “returning zero gaps is correct” line is doing real work. Without it you get a list of nitpicks every single time, and chasing them is how you end up over-engineering.

Test verifier — catches the worst failure mode

The one where the agent writes a test that can’t fail. This is worse than no test, and it’s invisible on a casual diff read.

markdown
---
name: test-verifier
description: Verifies that tests actually test something. Use after tests are written or modified.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You verify that tests would catch a real regression. You do not fix tests —
you report on them.

METHOD
For each test under review:
1. Read it and identify the specific behavior it claims to verify.
2. Determine whether it would fail if that behavior broke. Where practical,
   temporarily break the implementation, run the test, confirm it fails, then
   restore the original. Always restore.
3. Report the verdict.

RED FLAGS — check every test for these
- Assertions that are trivially true (assert x == x, assert result is not None
  as the only check)
- Mocks asserted against mocks, with no real code exercised
- Hardcoded expected values that mirror a hardcoded implementation return
- try/except swallowing the assertion
- A test whose name promises more than its body checks
- Tests that pass with the implementation entirely stubbed out

OUTPUT

## Summary
N tests reviewed, N real, N weak.

## Weak tests
- `file:line` — test name — why it cannot fail, and what it should assert

## Notes
Anything you had to break-and-restore, confirming restoration succeeded.

RULES
- If you modified anything to test a failure, verify with git status that the
  working tree is clean before finishing. Say so explicitly.
- "All tests are real" is a valid result.
Worth building second

root-cause — reproduces a bug and reports the evidence chain, explicitly forbidden from fixing it. Separating diagnosis from repair stops the pattern where it changes five things and can’t tell you which one worked. Give it Read, Grep, Glob, Bash and no Edit.

impact-analyzer — “if I change this signature, what breaks.” Read-only, returns a list of call sites with file:line plus anything reached dynamically (reflection, DI, config-referenced). Genuinely useful before a refactor and impossible to do well from a polluted context.

security-reviewer — keep it narrow or it’s useless. Authz checks, injection sinks, secrets in code or logs, unsafe deserialization. Rank findings by exploitability in your deployment, not by CVSS theater.

migration-worker — for fan-out. Deliberately dumb: one file, one transformation, report OK or FAIL, never touch anything else. Pin it to Haiku and run it in a loop with claude -p.

Don’t build these

Persona agents. “architect,” “senior-engineer,” “product-manager.” They have no constraints and no output contract, so they just produce the same output as your main session with extra latency.

Anything needing the full conversation. Subagents start fresh. If the task depends on twenty turns of context you built up, a subagent will do it worse and you’ll spend more tokens re-explaining than you saved.

One-shot prompts. If it’s “write a commit message” or “summarize this diff,” that’s a slash command or skill. Subagents are for work that needs its own context budget.

Two design details that matter

Restrict tools deliberately. A reviewer with Edit will start fixing things instead of reporting, and then you have unreviewed changes. Omitting a tool is a real constraint, not a suggestion.

Pin the model per agent. model: haiku on read-only explorers and migration workers is where most of your cost savings live. Reasoning-heavy auditors get Sonnet. Reserve Opus for the rare agent doing genuinely hard multi-system analysis.

Run /agents to see what’s registered and confirm the frontmatter keys your version accepts — that surface has moved around.

Want me to write these out as actual files you can drop into .claude/agents/, or roll them into a markdown doc like the other two?
