# Development Guide

> Developer onboarding and workflow guide for {{PROJECT_NAME}}

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Git** - Version control
- **just** - Command runner ([installation](https://github.com/casey/just#installation))
- **direnv** - Environment management ([installation](https://direnv.net/docs/installation.html))
- **Docker** - Container runtime (optional, for containerized development)

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YOUR-ORG/{{PROJECT_NAME}}.git
   cd {{PROJECT_NAME}}
   ```

2. **Run setup script**:
   ```bash
   bash scripts/setup.sh --dev
   ```

   This installs:
   - Development tools (docker, gcloud, shellcheck, shfmt)
   - Node.js and semantic-release
   - Claude CLI (AI coding assistant)

3. **Configure environment**:
   ```bash
   # Allow direnv to load .envrc
   direnv allow

   # Verify environment
   echo $PROJECT
   echo $VERSION
   ```

4. **Verify installation**:
   ```bash
   just --version
   direnv --version
   docker --version  # if installed
   ```

## Development Workflow

### Commands

Common commands using `just`:

```bash
# List all available commands
just

# Build the project
just build

# Run locally
just run

# Run tests
just test

# Format code
just format

# Lint code
just lint

# Clean build artifacts
just clean
```

### Making Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Write code
   - Add tests
   - Update documentation

3. **Test your changes**:
   ```bash
   just test
   just lint
   just format-check
   ```

4. **Commit using conventional commits**:
   ```bash
   # Feature
   git commit -m "feat: add new capability"

   # Bug fix
   git commit -m "fix: resolve issue with X"

   # Documentation
   git commit -m "docs: update README"

   # Refactoring
   git commit -m "refactor: restructure component Y"
   ```

5. **Push and create pull request**:
   ```bash
   git push -u origin feature/your-feature-name
   ```

### Pull Request Process

1. **Open PR** on GitHub
2. **Ensure CI passes**:
   - All tests pass
   - Code is formatted
   - No linting errors
3. **Request review** from team members
4. **Address feedback** and push updates
5. **Merge** when approved

## Project Structure

```
{{PROJECT_NAME}}/
├── .github/           # GitHub Actions workflows
├── .claude/           # AI assistant configuration
├── docs/              # Documentation
├── scripts/           # Build and setup scripts
├── src/               # Source code
├── test/              # Test files
├── .envrc             # Environment variables
├── .envrc.template    # Environment template
├── Dockerfile         # Container definition
├── justfile           # Command definitions
└── README.md          # Project overview
```

## Development Environment

### Using Docker

Development container for consistent environment:

```bash
# Build dev container
docker compose build dev

# Run in container
docker compose run --rm dev bash

# Inside container
just build
just test
```

### Using Dev Containers

If using VS Code:

1. Install "Dev Containers" extension
2. Open project in VS Code
3. Click "Reopen in Container" when prompted
4. Develop inside container with all tools pre-installed

## Testing

### Running Tests

```bash
# Run all tests
just test

# Run specific test file (TODO: Adjust based on test framework)
just test path/to/test_file

# Run with coverage (TODO: Add coverage support)
just test-coverage
```

### Writing Tests

TODO: Add language-specific testing guidelines

Example test structure:

```
test/
├── unit/         # Unit tests
├── integration/  # Integration tests
└── e2e/          # End-to-end tests
```

### Test Template

For template development:

```bash
# Install template testing tools
just setup --template

# Run template tests
just test-template
```

## Code Style

### Formatting

Code should be formatted before committing:

```bash
# Format all files
just format

# Check formatting without changing files
just format-check
```

### Linting

Run linters to catch issues:

```bash
# Run all linters
just lint

# Auto-fix linting issues (if available)
just lint-fix
```

### Best Practices

- Write clear, descriptive variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Write tests for new features
- Update documentation when changing behavior

## Debugging

### Local Debugging

TODO: Add language-specific debugging instructions

### Container Debugging

```bash
# Run container with interactive shell
docker compose run --rm dev bash

# Attach to running container
docker exec -it {{PROJECT_NAME}}-dev bash
```

### Common Issues

#### Environment not loading

```bash
# Check direnv status
direnv status

# Re-allow direnv
direnv allow
```

#### Build failures

```bash
# Clean and rebuild
just clean
just build
```

## AI-Assisted Development

This project uses Claude Code for AI-assisted development:

```bash
# Install Claude CLI (if not already installed)
npm install -g @anthropic-ai/claude-cli

# Verify installation
claude --version
```

### Claude Code Commands

Custom commands available in `.claude/commands/`:

```bash
# List available commands
ls .claude/commands/

# Use a command (in Claude Code CLI)
/command-name
```

## Versioning

This project uses semantic versioning (SemVer):

- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features (backwards compatible)
- **Patch** (0.0.1): Bug fixes

Versions are determined automatically by semantic-release based on commit messages.

### Version Management

```bash
# Check current version
just version

# Preview next version (dry-run)
just next-version
```

## Contributing Guidelines

### Code Review

- Be respectful and constructive
- Explain reasoning behind suggestions
- Approve when changes look good

### Documentation

- Update docs with code changes
- Keep README current
- Document new features
- Add ADRs for significant decisions

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code change (no feature/fix)
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

## Resources

### Documentation

- [Architecture Guide](./architecture.md)
- [User Guide](./user-guide.md)
- [Infrastructure Guide](./infrastructure.md)

### External Resources

TODO: Add links to relevant external resources:
- Language-specific docs
- Framework documentation
- API references

### Getting Help

- **Issues**: File a GitHub issue
- **Discussions**: Use GitHub Discussions
- **Chat**: TODO: Add team chat link

---

**Template**: {{TEMPLATE_NAME}} v{{TEMPLATE_VERSION}}
