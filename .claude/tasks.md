# Common Task Templates

## All Tasks

1. Update plan.md checkbox on completion

## Updating Configuration

1. Edit `.envrc` for environment variables
2. Edit `.releaserc.json` for semantic-release
3. Edit `justfile` for commands
4. Test changes locally

## Test Template

1. Run `just template-test`

## Future Work

### /adapt Command Enhancement

The `/adapt` command needs to be updated to handle `install.sh.template`:
- When adapting a project to this template, check if install.sh already exists
- If it does, ask user whether to keep existing or generate from template
- If generating, prompt for GitHub org and project name
- Process install.sh.template with substitutions
- Remove install.sh.template after processing
