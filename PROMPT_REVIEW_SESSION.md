# PROMPT_REVIEW_SESSION.md

## Description

Living document tracking the evolution of prompts and instruction files. Records reviews, findings, decisions, improvements, tradeoffs, and open questions. Update after every prompt-review session so future reviews can continue from the latest state instead of repeating previous analysis.

## Contents

I am working on a repository of reusable AI-agent instruction files. The goal is to create a maintainable, tool-agnostic framework that can be used across coding agents (Claude Code, Codex, Cursor, Pi, and future agents).

We are not optimizing individual prompts in isolation. We are optimizing the entire instruction system and the responsibilities of each file.

Current instruction architecture:

* AGENTS.md / CLAUDE.md / Cursor rules / INSTRUCTIONS.md → agent adapters
* WORKFLOWS.md → collaboration and workflow authority
* ENGINEERING.md → engineering standards and implementation guidance
* STATE.md → project state
* BRAINSTORM.md → durable ideas and discoveries
* BRIEF.md → project scope

Work completed:

1. Reviewed and improved ENGINEERING.md.

   * Reduced duplication.
   * Kept language/framework agnostic.
   * Added stronger verification guidance.
   * Added explicit tooling investigation requirements.
   * Added guidance to inspect existing tooling and consult documentation when working with specialized tools.
   * Added stronger Docker/container build guidance.
   * Added explicit final verification pass.

2. Reviewed and improved WORKFLOWS.md.

   * Established WORKFLOWS.md as the primary workflow authority.
   * Added collaboration-style guidance.
   * Added stronger memory reconciliation guidance.
   * Added planning before implementation.
   * Clarified that memory is a hint, not a source of truth.
   * Added explicit ENGINEERING.md loading for implementation work.

3. Reviewed all agent-specific adapter files:

   * Pi AGENTS.md
   * Codex AGENTS.md
   * CLAUDE.md
   * Cursor agent-workspace.mdc
   * Generic INSTRUCTIONS.md

Findings:

* All adapters contained nearly identical instructions.
* Collaboration and workflow behavior was duplicated across adapters and WORKFLOWS.md.
* This duplication would create maintenance problems and configuration drift.

Decision:

* Adapters should only bootstrap the agent into the project.
* WORKFLOWS.md owns collaboration and workflow behavior.
* ENGINEERING.md owns engineering behavior.
* Adapters should remain minimal.

Result:

* Replaced large adapters with lightweight bootstrap files.
* Adapters now:

  * load WORKFLOWS.md;
  * load memory files referenced by WORKFLOWS.md;
  * load ENGINEERING.md for implementation work;
  * update memory on completion.

Important design principles agreed upon:

* Prefer small, focused instruction files with clear responsibilities.
* Avoid duplicated rules across files.
* Optimize for maintainability over prompt size.
* Use workflow design to improve agent behavior rather than adding more prompt text.
* Verification is more important than prompt length.
* Tooling-specific research belongs in ENGINEERING.md, not adapter files.
* Agent adapters should stay as small as possible.

Current status:

The instruction system has been refactored and is considered complete for this iteration.

The next session should continue from this architecture rather than redesigning it from scratch.
