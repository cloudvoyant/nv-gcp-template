# nv-gcp-template

![Version](https://img.shields.io/github/v/release/cloudvoyant/nv-gcp-template?label=version)
![Release](https://github.com/cloudvoyant/nv-gcp-template/workflows/Release/badge.svg)

`nv-gcp-template` is a language-agnostic template for building projects with automated versioning, testing, and GitHub Action powered CI/CD workflows. It uses GCP Artifact Registry for publishing generic packages by default, but can be easily adapted for npm, PyPI, NuGet, CodeArtifact, etc.

## Features

Here's what this template gives you off the bat:

- A language-agnostic self-documenting command interface via `just`. Keep all your project commands organized in one file!
- Auto-load environment variables and configure shell environment with `direnv` - share project scoped shell configurations and simplify scripting and CLI tool usage without needing to pass around flags and inline environment variables.
- CI/CD with GitHub Actions - run test on MR commits, tag and release on merges to main.
- Easy CI/CD customization with language-agnostic bash scripting - No need to get too deep into GitHub Actions for customization. Modify the publish recipe, set GitHub Secrets and you're good to go.
- Trunk based development and automated versioning with conventional commits - semantic-release will handle version bumping for you! Work on feature branches and merge to main for bumps.
- GCP Artifact Registry publishing (easily modified for other registries)
- Cross-platform (macOS, Linux, Windows via WSL) - use the setup script to install dependencies, or alternately develop with Dev Containers or run tasks via Docker

## Requirements

- bash 3.2+
- just

Run `just setup` to install remaining dependencies (just, direnv).

Optional: `just setup --dev` for development tools, `just setup --template` for template testing.

## Quick Start

Scaffold a new project:

```bash
# Option 1: Nedavellir CLI (automated)
nv create your-project-name --platform nv-gcp-template

# Option 2: GitHub template + scaffold script
# Click "Use this template" on GitHub, then:
git clone <your-new-repo>
cd <your-new-repo>
bash scripts/scaffold.sh --project your-project-name
```

Install dependencies and adapt the template for your needs:

```bash
just setup --dev        # Install all dependencies including Claude CLI and Claudevoyant plugin
just scaffold           # Scaffold project - apply project name and reset version
claude /adapt           # Guided customization for your language / package manager
```

Type `just` to see all the tasks at your disposal:

```bash
❯ just
Available recipes:
    [dev]
    load                 # Load environment
    install              # Install dependencies
    build                # Build the project
    run                  # Run project locally
    test                 # Run tests
    clean                # Clean build artifacts

[ OUTPUT TRUNCATED ]
```

Build run and test with `just`. The template will show TODO messages in console prior to adapting.

```bash
❯ just run
TODO: Implement build for nv-gcp-template@1.9.1
TODO: Implement run

❯ just test
TODO: Implement build for nv-gcp-template@1.9.1
TODO: Implement test
```

Note how just runs the necessary dependencies for a task on it's own!

Commit using conventional commits (`feat:`, `fix:`, `docs:`). Merge/push to main and CI/CD will run automatically bumping your project version and publishing a package.

## Documentation

To learn more about using this template, read the docs:

- [User Guide](docs/user-guide.md) - Complete setup and usage guide
- [Architecture](docs/architecture.md) - Design and implementation details

## TODO

- [ ] Pre-release publishing
- [ ] Template docs improvements

## References

- [just command runner](https://github.com/casey/just)
- [direnv environment management](https://direnv.net/)
- [semantic-release](https://semantic-release.gitbook.io/)
- [bats-core bash testing](https://bats-core.readthedocs.io/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
