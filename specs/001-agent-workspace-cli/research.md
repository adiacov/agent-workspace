# Research: Agent Workspace CLI

## Decision: Implement the first global CLI as Bash

**Rationale**: The repository already implements the bootstrap/local CLI in Bash and targets a simple curl/GitHub distribution flow. Bash keeps the MVP portable on Linux/macOS, avoids package manager choices, and allows incremental migration from existing behavior.

**Alternatives considered**:

- Node/Python/Rust CLI rewrite: better long-term structure and packaging options, but adds a runtime/toolchain decision before validating the new lifecycle model.
- Keep duplicated `bootstrap.sh` and `bin/agent-workspace`: preserves current behavior but conflicts with the clarified global `agent-ws` model and increases version drift.

## Decision: Use `agent-ws` as the installed command name

**Rationale**: `agent-ws` is shorter than `agent-workspace`, still recognizable, and less cumbersome for frequent project-local use. It also makes the new global CLI distinct from the older project-local `bin/agent-workspace` copy.

**Alternatives considered**:

- `agent-workspace`: explicit but longer and tied to the old local command name.
- `workspace-agent`: less natural and less aligned with existing project identity.
- `context-kit`: broader but loses continuity with the Agent Workspace project.

## Decision: Store project metadata under `.agent-workspace/`

**Rationale**: `.agent-workspace/` is explicit and less likely to collide than the generic `.agent/` folder. It communicates that the directory belongs to this tool and can be committed safely when metadata contains only non-private setup facts.

**Alternatives considered**:

- `.agent/`: already used by the current implementation but too generic and likely to conflict with other tooling.
- Root metadata file only: simpler but less extensible for future non-private metadata/checksums.

## Decision: Keep templates global, not per project

**Rationale**: In a global CLI model, canonical templates belong to the installed app/release. Projects should not carry repeated template caches. Users customize generated behavior by editing active instruction files after initialization.

**Alternatives considered**:

- Commit templates in every project: self-contained, but creates repeated vendor-like files and complicates sync.
- Keep ignored project-local template caches: matches the old design, but conflicts with global CLI ownership and makes projects carry hidden generated state.

## Decision: Commit workspace metadata by default

**Rationale**: Discovery, audit, and future sync are more reliable when metadata travels with the project. Metadata must avoid private memory, machine-specific paths, and personal project meaning.

**Alternatives considered**:

- Ignore metadata: safer for privacy by default but weakens discovery and reproducibility.
- Ask during init: flexible but adds a prompt to the primary quickstart and increases user confusion.

## Decision: Install/update from Git/GitHub releases or tags

**Rationale**: This matches the current repository/curl distribution style and avoids maintaining a package registry in the first global CLI version. It also supports explicit version selection and latest stable updates.

**Alternatives considered**:

- Package manager/registry publishing: better later for discoverability but adds release maintenance and ecosystem decisions now.
- Support both immediately: broader but increases testing and documentation complexity before the global model is proven.

## Decision: Migration should be documented first, automated carefully second

**Rationale**: Existing projects are few and local, but migration must preserve active instruction files and memory. A helper can be useful only if it previews intended changes before deleting or moving old `.agent/` or `bin/agent-workspace` artifacts.

**Alternatives considered**:

- No migration support: simplest, but risks confusion when users see old files.
- Automatic migration during init/audit: convenient, but unsafe without explicit preview and apply intent.

## Decision: README should lead with one primary quickstart

**Rationale**: The current README offers multiple equivalent flows, which makes first use feel cumbersome. The new README should explain one recommended path first, then place non-interactive, custom, migration, and advanced commands in separate sections.

**Alternatives considered**:

- Document every option up front: complete but counterintuitive for new users.
- Minimal README only: simple but insufficient for migration and lifecycle commands.
