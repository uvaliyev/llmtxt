# llmtxt

Bash utility to concatenate documentation files into a single text file. Perfect for creating corpus files for LLM training or documentation archives.

## Features

- Recursively processes directories
- Handles multiple file types/patterns
- Strips markdown frontmatter
- Removes HTML/JSX tags
- Shows file processing progress
- Works on Linux, macOS, and Windows (via WSL/Git Bash)

## Installation

### Linux & macOS

1. Clone the repository:
   ```bash
   git clone https://github.com/uvaliyev/llmtxt.git
   cd llmtxt
   ```

2. Make the script executable:
   ```bash
   chmod +x main.sh
   ```

### Windows

**Option 1: Windows Subsystem for Linux (WSL)**
1. [Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
2. Open WSL terminal and follow Linux instructions

**Option 2: Git Bash**
1. [Install Git for Windows](https://gitforwindows.org/) (includes Git Bash)
2. Clone the repository in Git Bash and run the script there

**Option 3: VSCode Terminal**
1. Install WSL or Git Bash
2. In VSCode, select appropriate terminal (WSL or Git Bash) from the dropdown
3. Run commands as shown in examples below

## Usage

```bash
./main.sh [OPTIONS] INPUT_DIR OUTPUT_FILE
```

### Basic examples

```bash
# Basic usage
./main.sh docs output.txt

# Strip frontmatter and clean HTML
./main.sh -f -c docs clean_output.txt

# Custom file patterns
./main.sh -p "*.md,*.txt" docs output.txt

# Verbose output and custom title
./main.sh -v -t "MY PROJECT DOCS" docs output.txt

# Hide file paths in output
./main.sh -n docs output.txt
```

### Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-h` | `--help` | Show help message |
| `-p PATTERN` | `--pattern PATTERN` | Comma-separated patterns (default: `*.md,*.txt,*.mdx`) |
| `-t TITLE` | `--title TITLE` | Title for output file (default: `DOCS`) |
| `-s TEXT` | `--separator TEXT` | Separator between files (default: `---`) |
| `-n` | `--no-path` | Don't include file paths in output |
| `-v` | `--verbose` | Show verbose processing output |
| `-f` | `--no-frontmatter` | Strip frontmatter from markdown files |
| `-c` | `--clean` | Remove HTML tags and special formatting |

## Troubleshooting

### Common Issues

- **"Permission denied" error**: Make sure the script is executable with `chmod +x main.sh`
- **"Command not found" error on Windows**: Ensure you're using Git Bash or WSL
- **"mapfile: command not found" on older Bash versions**: This script requires Bash 4.0+, which is standard on Linux and newer macOS. For older systems, consider using Docker with a Linux image

### Windows-specific Notes

- File paths use forward slashes in the script (`/`) but Windows uses backslashes (`\`). When using the script in WSL or Git Bash, use forward slashes
- If input files have Windows line endings (CRLF), the script will handle them correctly in most cases

## Requirements

- Bash 4.0 or later
- Standard Unix tools (find, awk, sed)
- For Windows: WSL or Git Bash
