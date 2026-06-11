# Research: Release, Install, and Update Hardening

## Decision: Use `vMAJOR.MINOR.PATCH` as the public version format

**Rationale**: GitHub releases and tags commonly use a leading `v`, and the feature brief examples use `v0.1.0`. Using the same value in `VERSION` and public tags avoids translating between internal and external formats during early distribution.

**Alternatives considered**:

- `MAJOR.MINOR.PATCH` in `VERSION` with `v` only on tags: conventional in some ecosystems, but introduces mapping logic and documentation ambiguity.
- Arbitrary build strings: flexible, but weaker for stable public release expectations.

## Decision: Add root `VERSION` as the single source of version truth

**Rationale**: A root file is inspectable, easy for shell scripts to read, copied into release archives, and independent of package-manager metadata that this phase explicitly defers.

**Alternatives considered**:

- Hardcode version inside `bin/agent-ws`: easy but risks drift across scripts and docs.
- Derive version only from Git tags: works in a clone but not reliably from installed archive payloads.
- Store version in README or metadata JSON: less direct and harder for shell scripts.

## Decision: Install from GitHub tag archives for this phase

**Rationale**: Tag archives require no custom release asset build pipeline and are deterministic once tags are immutable by convention. They contain the same shell scripts, libraries, templates, and `VERSION` file needed for installation.

**Alternatives considered**:

- Release assets: better for checksums and curated payloads later, but adds packaging/release workflow before external usage exists.
- Raw files at a tag: simple for one file but awkward for libraries/templates and harder to validate as a coherent payload.
- Clone repository: reliable for developers, but violates the goal that users should not need to manually clone.

## Decision: Resolve latest stable via GitHub release/tag metadata with stable filtering

**Rationale**: The default install/update should not use a development branch. A latest stable resolver should prefer official releases if present and otherwise use tags that do not contain alpha, beta, rc, or prerelease suffixes.

**Alternatives considered**:

- Hardcoded latest version in install script: deterministic but requires editing the installer for every release.
- Always use `main`: easiest, but explicitly rejected by the feature.
- Require users to pin every install: reproducible but poor first-run experience.

## Decision: Default install prefix remains `$HOME/.local`

**Rationale**: This matches the existing installer behavior, is user-writable on Linux, and commonly places commands at `$HOME/.local/bin`.

**Alternatives considered**:

- `$HOME/.agent-workspace`: isolates all files but makes PATH setup less standard and changes the existing install contract.
- `/usr/local`: familiar system path but often requires elevated permissions and increases failure risk.

## Decision: Stage and validate before activation for install and update

**Rationale**: The core safety requirement is that failed lifecycle operations must not break the active command. Staging into a temporary location and validating `agent-ws version` before replacement provides a simple, testable safety gate.

**Alternatives considered**:

- Replace files in place: simpler but can corrupt active installs on partial failure.
- Keep multiple managed versions: safer rollback story but too much lifecycle complexity for this phase.

## Decision: Preserve local checkout install path

**Rationale**: Contributors still need to run `./install.sh --prefix ...` from a repository checkout for development and tests. Remote/curl install should extend, not replace, this behavior.

**Alternatives considered**:

- Separate scripts for local and remote install: clearer separation, but risks behavior drift.
- Remote-only installer: breaks current development and test workflows.
