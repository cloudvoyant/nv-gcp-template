# Style Guide

## Documentation

Required files in `docs/`:
- `architecture.md` - design philosophy + implementation (overview → features → design → components → details)
- `user-guide.md` - usage for clients

Style:
- Concise and scannable
- Backticks for files, commands, code
- Minimal bold/emphasis
- Code examples where helpful

## Markdown Formatting

All markdown files (`.claude/`, `docs/`, `README.md`):

- Use bold for emphasis within sentences, not for headings
- Bold headings are unreadable in code editors
- Use bold for important keywords: **IMPORTANT**, **REQUIRED**, **CRITICAL**
- Keep text terse and structured

Examples:
```markdown
Good:
1. Configuration Settings
   - Update the file and **do not skip** validation

Bad:
1. **Configuration Settings**
   - Update the file and **Do Not Skip** validation
```

## Architectural Decision Records (ADRs)

Location: `docs/decisions/NNN-short-title.md`

Template:
```markdown
# ADR-NNN: Title

Status: Accepted | Superseded | Deprecated
Date: YYYY-MM-DD

## Context
What problem requires a decision?

## Decision
What you decided.

## Alternatives Considered

### Alternative 1
- Pros: Benefits
- Cons: Drawbacks

### Alternative 2
- Pros: Benefits
- Cons: Drawbacks

## Rationale
Why this choice? What factors led here?
```

When to create:
- Technology/tool choices
- Patterns/conventions
- Trade-off decisions
- Significant features

After creating:
1. Update `docs/decisions/README.md`
2. Update `docs/architecture.md` if needed
3. Reference ADR when explaining choices

## Justfile

- Description comment for every task
- `@` for silent execution
- `{{ARGS}}` for parameters
- Keep TODO if not implemented

## Bash

Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).

Template:
```bash
#!/usr/bin/env bash
: <<DOCUMENTATION
Description: What this script does
Usage: ./script.sh [options]
DOCUMENTATION

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"
set -euo pipefail
```

Use `scripts/utils.sh` functions. Test with bats.
