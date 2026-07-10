# AsciiDoc PDF Watch

A lightweight Docker image for generating PDF documentation from AsciiDoc with automatic hot-reloading.

Whenever an AsciiDoc file, image, theme, or font changes, the PDF is regenerated automatically. It works on macOS, Windows, and Linux by using polling instead of filesystem notifications, making it reliable across Docker Desktop platforms.

## Features

- 🚀 Automatic PDF regeneration
- 📄 Uses Asciidoctor PDF
- 🖼️ Watches AsciiDoc, images, themes, and fonts
- 🐳 Runs entirely inside Docker
- 💻 Cross-platform (macOS, Windows, Linux)
- 📁 Generates PDFs into a `build/` directory
- ⚙️ Zero configuration for most projects

## Requirements

- Docker
- Docker Compose

## Quick Start

Clone this repository.

```sh
git clone https://github.com/<your-account>/asciidoc-watch.git
cd asciidoc-watch
```

Point the container to your documentation project.

```sh
export DOCS_DIR=/path/to/your/docs
```

Or run it in one command:

```sh
DOCS_DIR=/path/to/your/docs docker compose up --build
```

The generated PDF will appear in:

```text
build/document.pdf
```

## Example Project

```text
docs/
├── index.adoc
├── chapters/
├── images/
├── themes/
│   └── my-theme-theme.yml
└── build/
```

## Configuration

The container can be configured using environment variables.

| Variable | Default | Description |
| --- | --- | --- |
| `DOCS_DIR` | `.` | Host directory to mount into the container |
| `INPUT_FILE` | `index.adoc` | Root AsciiDoc document |
| `OUTPUT_FILE` | `document.pdf` | Name of the generated PDF |
| `POLL_INTERVAL` | `1` | Poll interval in seconds |

Example:

```sh
DOCS_DIR=./docs \
INPUT_FILE=manual.adoc \
OUTPUT_FILE=manual.pdf \
docker compose up
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

The `build/` directory is ignored to prevent rebuild loops.

## Running In The Background

```sh
docker compose up -d
```

View the logs:

```sh
docker compose logs -f
```

Stop the watcher:

```sh
docker compose down
```

## How It Works

The container periodically calculates a checksum of all relevant files in the documentation project. When the checksum changes, it invokes Asciidoctor PDF to regenerate the document.

Polling is used instead of native filesystem events because it behaves consistently across macOS, Windows, and Linux when using Docker bind mounts.

## License

MIT
