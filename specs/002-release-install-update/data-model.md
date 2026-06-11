# Data Model: Release, Install, and Update Hardening

## Entity: Release Version

Represents a public version of Agent Workspace that can be installed or updated to.

**Fields**:

- `version`: canonical release identifier, e.g. `v0.1.0`.
- `source`: public source location for the release, normally a GitHub release or tag archive.
- `stable`: whether the release is eligible for default latest install/update.
- `available`: whether the release can currently be resolved and downloaded.

**Validation rules**:

- Stable release identifiers must not contain alpha, beta, rc, or prerelease suffixes.
- A pinned release must resolve exactly to the requested identifier.
- The installed payload must include the same version in the root version source.

## Entity: Installed Command

Represents the active `agent-ws` command available to the user.

**Fields**:

- `command_path`: active executable path.
- `prefix`: installation prefix containing command and supporting files.
- `version`: installed version reported by the command.
- `support_files`: required libraries, templates, and version source.
- `validated`: whether the command can run and report version information.

**Validation rules**:

- The command is valid only if it can execute `version` successfully.
- Supporting files must be colocated according to the documented installed layout.
- Activation must not occur unless the staged candidate is valid.

## Entity: Staged Installation

Represents a candidate install/update prepared before it replaces the active install.

**Fields**:

- `stage_path`: temporary staging location.
- `requested_version`: user-selected version or latest stable.
- `resolved_version`: concrete release identifier selected for installation.
- `validation_result`: success or failure of command validation.
- `ready_for_activation`: whether the staged payload may replace the active install.

**State transitions**:

```text
created -> downloaded -> installed_to_stage -> validated -> activated
   |          |                 |                 |
   v          v                 v                 v
 failed     failed            failed            failed
```

**Validation rules**:

- A failed staged installation must be removable without changing the active install.
- `ready_for_activation` is true only after version validation succeeds.

## Entity: Install Location

Represents the destination where the active command and support files live.

**Fields**:

- `prefix`: user-selected or default install prefix.
- `bin_dir`: command directory under the prefix.
- `lib_dir`: supporting library directory under the prefix.
- `template_dir`: installed template directory under the prefix.
- `path_visible`: whether `bin_dir` is on the user's `PATH`.
- `writable`: whether the installer can write to the destination.

**Validation rules**:

- Install/update must fail clearly when the destination is not writable.
- If `bin_dir` is not on `PATH`, installation can still succeed but must report the required PATH guidance.

## Entity: Lifecycle Operation

Represents one install or update attempt.

**Fields**:

- `operation_type`: install or update.
- `requested_version`: optional pinned version.
- `previous_version`: version active before the operation, if any.
- `result_version`: version active after success.
- `failure_stage`: release resolution, download, staging, validation, or activation.
- `active_install_preserved`: whether a pre-existing active install remains usable after failure.

**Validation rules**:

- On failure, `active_install_preserved` must be true whenever a previous valid install existed.
- On success, `result_version` must match the staged candidate's validated version.
