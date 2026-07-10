# AsciiDoc PDF Watch

A lightweight Docker image for generating PDF documentation from AsciiDoc with automatic hot-reloading.

Whenever an AsciiDoc file, image, theme, or font changes, the PDF is regenerated automatically. It works on macOS, Windows, and Linux by using polling instead of filesystem notifications, making it reliable across Docker Desktop platforms.

## Features

- 🚀 Automatic PDF regeneration
- 📄 Uses Asciidoctor PDF
- 🖼️ Watches AsciiDoc, images, themes, and fonts
- 🐳 Runs entirely inside Docker
- 💻 Cross-platform (macOS, Windows, Linux)
- 📁 Generates PDFs into an `output/` directory
- ⚙️ Zero configuration for most projects

## Requirements

- Docker

## Quick Start

Run the published Docker image directly. You do not need to clone this repository or use Docker Compose for normal usage.

The `-v` option mounts your local documentation folder into the container as `/work`. Anything written to `/work/output` appears in the local `output/` folder.

```sh
docker run --rm \
  --name asciidoc-watch \
  -v "/path/to/your/docs:/work" \
  jacobduijzer/asciidoc-watch:latest
```

When running from inside your documentation directory, you can use `$PWD`:

```sh
docker run --rm \
  --name asciidoc-watch \
  -v "$PWD:/work" \
  jacobduijzer/asciidoc-watch:latest
```

The command runs in the foreground so you can see rebuild output while working. Press `Ctrl+C` to stop the watcher.

The generated PDF will appear in your local documentation folder at:

```text
output/document.pdf
```

## Docker Compose

Docker Compose is optional. If you prefer it, create a `docker-compose.yml` next to your documentation files:

```yaml
services:
  asciidoc:
    image: jacobduijzer/asciidoc-watch:latest
    container_name: asciidoc-watch
    volumes:
      - .:/work
```

Then run:

```sh
docker compose up
```

To configure all variables in Docker Compose:

```yaml
services:
  asciidoc:
    image: jacobduijzer/asciidoc-watch:latest
    container_name: asciidoc-watch
    volumes:
      - .:/work
    environment:
      SOURCE_DIR: /work
      OUTPUT_DIR: /work/output
      INPUT_FILE: index.adoc
      OUTPUT_FILE: document.pdf
      POLL_INTERVAL: 1
```

## Example Project

```text
docs/
├── index.adoc
├── chapters/
├── images/
├── themes/
│   └── my-theme-theme.yml
└── output/
```

## Configuration

The container can be configured using environment variables.

| Variable | Default | Description |
| --- | --- | --- |
| `DOCS_DIR` | `.` | Host directory to mount into the container |
| `INPUT_FILE` | `index.adoc` | Root AsciiDoc document |
| `OUTPUT_DIR` | `/work/output` | Container directory where the PDF is written. With the default mount, this is your local `output/` folder. |
| `OUTPUT_FILE` | `document.pdf` | Name of the generated PDF |
| `POLL_INTERVAL` | `1` | Poll interval in seconds |
| `ONCE` | `false` | Set to `true` to build once and exit, useful for CI pipelines |

Example:

```sh
docker run --rm \
  --name asciidoc-watch \
  -v "$PWD/docs:/work" \
  -e INPUT_FILE=manual.adoc \
  -e OUTPUT_DIR=/work/output \
  -e OUTPUT_FILE=manual.pdf \
  jacobduijzer/asciidoc-watch:latest
```

## CI Usage

Use `ONCE=true` in CI so the container builds the PDF once and exits instead of watching for changes.

Example Azure Pipelines step:

```yaml
- script: |
    docker run --rm \
      -v "$(System.DefaultWorkingDirectory):/work" \
      -e INPUT_FILE=tech-screening.adoc \
      -e OUTPUT_FILE=tech-screening.pdf \
      -e ONCE=true \
      jacobduijzer/asciidoc-watch:latest
  displayName: Build PDF
```

## Theme Support

If your document contains:

```asciidoc
:pdf-theme: my-theme
:pdf-themesdir: themes
```

the project should contain:

```text
themes/
└── my-theme-theme.yml
```

The watcher will automatically rebuild whenever the theme changes.

## What Is Watched?

The watcher rebuilds whenever any of these files change:

- `*.adoc`
- `*.asciidoc`
- `*.yml`
- `*.yaml`
- `*.png`
- `*.jpg`
- `*.jpeg`
- `*.gif`
- `*.svg`
- `*.webp`
- `*.ttf`
- `*.otf`

The output directory is ignored to prevent rebuild loops.

## Stopping The Watcher

The recommended `docker run` command runs in the foreground so rebuild output is visible while you work. Stop it with `Ctrl+C`.

If you started it from another terminal, stop the named container with:

```sh
docker stop asciidoc-watch
```

## Publishing The Docker Image

This repository includes a GitHub Actions workflow that builds and pushes the Docker image on pushes to `main`, version tags such as `v1.0.0`, and manual workflow runs. The workflow calculates the version with GitVersion and publishes only `latest` and `vX.X.X` image tags.

Configure these repository secrets:

| Secret | Description |
| --- | --- |
| `REGISTRY_USERNAME` | Docker registry username |
| `REGISTRY_PASSWORD` | Docker registry password or access token |

Optional repository variables:

| Variable | Default | Description |
| --- | --- | --- |
| `DOCKER_REGISTRY` | `docker.io` | Registry hostname |
| `DOCKER_IMAGE_NAME` | GitHub repository name, for example `jacobduijzer/asciidoc-watch` | Image name to publish |

For Docker Hub, set `REGISTRY_USERNAME` to your Docker Hub username and `REGISTRY_PASSWORD` to a Docker Hub access token.

## How It Works

The container periodically calculates a checksum of all relevant files in the documentation project. When the checksum changes, it invokes Asciidoctor PDF to regenerate the document.

Polling is used instead of native filesystem events because it behaves consistently across macOS, Windows, and Linux when using Docker bind mounts.

## License

MIT
