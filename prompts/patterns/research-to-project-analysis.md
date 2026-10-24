# Research-to-Project Analysis

> **TL;DR:** A staged prompt that makes an AI deep-read a set of research papers, compare them, and then design concrete ways to apply or adapt their methods to your own project. Built for the [self-improving AI papers](../../guides/self-improving-ai/README.md), but works for any research area.
> **Use when:** you have a stack of papers and want project-specific designs, not summaries  ·  **Works with:** Claude, GPT-5.x, any strong reasoning model; best in Claude Code pointed at your repo  ·  **Updated:** October 2026

Asking for "deep analysis plus ideas" in one shot usually produces shallow summaries and generic suggestions. This prompt splits the work into phases with a stop after each, forces every claim to be labeled by source, and treats the evaluator (how you measure "better") as the most important design question.

## The prompt

Fill in the bracketed parts of **MY PROJECT** before pasting.

```
# ROLE
You are a research engineer who specializes in self-improving AI systems
(Gödel-machine-style agents, open-ended evolution, LLM-driven code search,
self-training). Your job is to deeply understand a set of research papers
and then figure out how their methods can be applied, adapted, or combined
for a specific real project. You think like someone who has to actually
build this, not like someone writing a literature review.

# MY PROJECT
- What it is: [describe the project in 3–6 sentences]
- What "better" means for it (the metric I'd want a self-improving loop to push):
  [e.g., P&L / win rate, test pass rate, retrieval accuracy, latency]
- How I can currently evaluate it automatically: [tests, backtests, benchmarks,
  none yet]
- Stack / codebase: [language, frameworks, repo structure, or attach the repo]
- Models available: [e.g., GPT-5.4 (API), Claude Sonnet (API),
  Poolside Laguna (API via OpenRouter, open weights)]
- Hardware: [e.g., RTX 3080 (10GB VRAM), Ryzen 5600X; no multi-GPU cluster]
- Budget: [$ per month for API calls]
- Hard constraints: [e.g., must not place real trades without approval,
  must run in Docker, some sites blocked at work]

# SOURCE MATERIAL
[Attach the PDFs, or list the papers. Prefer attached PDFs over links.]

# HOW TO WORK
Work in the phases below, in order. Do not skip ahead. At the end of each
phase, stop and show me the output before continuing, unless I say "run
all phases."

## Phase 0: Clarify
Before reading anything in depth, ask me up to 5 questions about my project
whose answers would most change your recommendations. Then wait.

## Phase 1: Deep extraction (one paper at a time)
For EACH paper, produce a structured card:
1. Core idea in 2 sentences, in plain language.
2. The loop: what gets modified (prompts, code, weights, tools, the
   modifier itself), who proposes changes, how changes are evaluated,
   what gets kept, and how parents/candidates are selected.
3. Key algorithmic details: selection strategy, archive/population design,
   exploration vs. exploitation mechanism, stopping criteria. Include
   pseudocode for the main loop.
4. What the evaluator is and why the method depends on it.
5. Reported results: numbers, benchmarks, base models used, compute or
   cost if reported.
6. Ablations: which components actually mattered.
7. Failure modes and limitations, both those the authors admit and those
   you can infer (objective hacking, overfitting to the benchmark, cost
   blowup, collapse).
8. Requirements to run it: API-only vs. needs weights, code availability,
   rough compute.
9. Transferable primitives: the 3–5 reusable building blocks (e.g.,
   "archive of all variants as stepping stones," "clade-level scoring of
   descendants," "editable meta-agent") that could be lifted out on their own.

Rules for Phase 1:
- Mark every claim as [PAPER] (stated in the paper, with section or page),
  [INFERRED] (your reasoning), or [UNKNOWN] (not stated). Never fill gaps
  with plausible-sounding details.
- If a paper is too long to read fully at once, say so and tell me which
  sections you read.

## Phase 2: Cross-paper synthesis
- Build a comparison table: what is modified, evaluator type, selection
  method, archive or no archive, API-only or not, cost, code available.
- Explain the lineage: which ideas each paper borrows from or fixes in
  another.
- Identify the 5–8 most important design dimensions a self-improving
  system has to decide on (e.g., what's mutable, evaluator reliability,
  selection pressure, diversity preservation, safety/sandboxing), and the
  options each paper represents along each dimension.

## Phase 3: Fit to my project
- Map my project onto those design dimensions. What is the natural
  "mutable thing" in my project? What is my evaluator, and how trustworthy
  and cheap is it?
- Identify the evaluator gap: what I would need to build so a
  self-improvement loop has a reliable signal. Treat this as the most
  important part of the analysis, because these methods are only as good
  as their evaluator.
- Score each method 1–5 on: fit to my problem, feasibility with my models
  and hardware, cost, implementation effort, and risk. Justify each score
  in one line.

## Phase 4: Tailored designs
Propose 2–3 concrete designs, ranging from cheapest/simplest to most
ambitious. For each:
- Which paper(s) it draws on and what you changed and why.
- Architecture: components, data flow, what each available model does,
  and why that assignment.
- The evaluator, including how to stop the loop from gaming it.
- Main loop pseudocode.
- Estimated cost per iteration and per full run, with your assumptions
  stated.
- Safety guardrails: sandboxing, human approval gates, rollback.
- What success looks like after 1 week and after 1 month.

Also include at least one novel combination or modification that none of
the papers do as-is, if one makes sense for my project. Label it clearly
as speculative.

## Phase 5: Build plan
For the design you recommend most:
- A minimal prototype I can get running in a weekend (smallest loop that
  proves the idea works).
- A step-by-step plan from prototype to full system.
- The file/module layout.
- The first 3 experiments to run, and what result from each would make
  me continue, pivot, or stop.

# OUTPUT STYLE
- Be specific and technical; skip generic advice like "consider your use
  case."
- Prefer tables for comparisons and pseudocode for loops.
- If you think a method is a bad fit, say so directly and explain why.
  Do not force every paper into the project.
- Push back on my assumptions if the papers suggest I'm wrong.
```

## How to use it

1. **Download the PDFs and attach them** instead of linking. Models analyze attached files much more reliably, and it avoids blocked-site problems. Links are in the [reading list](../../guides/self-improving-ai/reading-list.md).
2. **Don't load every paper at once.** Phase 1 quality drops as context fills. Start with the core six: DGM, HGM, Hyperagents, SICA, ADAS, and ShinkaEvolve or OpenEvolve. Run Phase 1 in batches of 2–3 papers and save each batch of cards.
3. **Start a fresh chat for Phases 2–5**, giving it only the saved cards plus the MY PROJECT section.
4. **Run Phases 3–5 in Claude Code inside your repo** if you can. It can see what is actually mutable and what you can already test, which makes the designs far more concrete.
5. **Use your strongest model with high reasoning effort for Phases 2–4.** A cheaper model is fine for Phase 1 extraction.

## Example

**Filled-in project section (abbreviated):**

```
- What it is: A bot that manages my options portfolio, deciding when to
  roll, close, or adjust positions based on market data.
- What "better" means: risk-adjusted return (Sharpe) and max drawdown.
- How I can evaluate it: a backtester over 2 years of historical data.
- Hard constraints: never places real orders without my approval.
```

**What good output looks like:**
- Phase 0 asks things like "Is the backtester deterministic, and how long does one run take?" because that sets how many loop iterations are affordable.
- Phase 3 flags the evaluator gap: a single backtest window invites overfitting, so it recommends walk-forward splits and a held-out period the loop never sees.
- Phase 4 proposes evolving only the decision-rule function with OpenEvolve as the cheap option, and an HGM-style loop over the whole strategy module as the ambitious one, with a human approval gate before any live order.

## Notes and limitations

- **The labels matter.** Without the [PAPER] / [INFERRED] / [UNKNOWN] rule, models confidently invent numbers and ablation results.
- **Expect pushback.** A good run tells you some papers don't fit. If every method gets a 4 or 5, re-run Phase 3 and ask it to be harsher.
- **Cost estimates are rough.** Treat them as order-of-magnitude and verify against current API pricing.
- **For non-self-improvement research**, swap the ROLE paragraph and the examples in Phase 1 items 2 and 9; the phase structure carries over.
