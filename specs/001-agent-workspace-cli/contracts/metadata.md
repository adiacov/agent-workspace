# Metadata Contract: `.agent-workspace/`

Workspace metadata is committed by default and must contain only non-private project setup facts.

## Directory

```text
.agent-workspace/
└── workspace.json
```

## `workspace.json` shape

```json
{
  "schemaVersion": 1,
  "toolName": "agent-ws",
  "toolVersion": "<version-or-unknown>",
  "templateRevision": "<release-tag-commit-or-unknown>",
  "profile": "general",
  "agents": ["pi"],
  "generatedFiles": {
    "AGENTS.md": {
      "kind": "adapter",
      "agent": "pi",
      "template": "adapters/pi/AGENTS.md"
    },
    "WORKFLOWS.md": {
      "kind": "default",
      "template": "default/WORKFLOWS.md"
    }
  },
  "createdAt": "<iso-8601-timestamp>",
  "updatedAt": "<iso-8601-timestamp>"
}
```

## Required fields

- `schemaVersion`
- `toolName`
- `profile`
- `agents`
- `generatedFiles`
- `createdAt`
- `updatedAt`

## Privacy rules

Metadata MUST NOT include:

- absolute machine-specific paths;
- user names or personal project registry information;
- private memory content from `STATE.md`, `MEMORY.md`, legacy `BRAINSTORM.md`, or similar files;
- secrets, credentials, tokens, or environment-specific configuration.

## Compatibility rules

- `.agent-workspace/` is the only new metadata directory for the global model.
- `.agent/` is a legacy signal only and is not created by new initialization.
- `bin/agent-workspace` is a legacy signal only and is not created by new initialization.

## Validation expectations

- Invalid JSON is reported during status/audit.
- Metadata that references unavailable template revisions is reported as stale.
- Missing metadata in a legacy-shaped project is reported as a migration opportunity.
- Active files remain valid project-owned files when metadata is invalid or stale.
- Unknown future fields are ignored unless they conflict with required privacy rules.
