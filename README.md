# AxiomCorePlatformRepo

A full stack platform repo for AxiomCore

## Description

This repository serves as the foundation for the AxiomCore platform, providing a comprehensive full-stack solution. The project supports both PowerShell and Python development environments.

## Features

- Full-stack platform architecture
- PowerShell scripting support
- Python application development
- Cross-platform compatibility

## Getting Started

### Prerequisites

- PowerShell 7.0 or higher
- Python 3.8 or higher

### Installation

#### Option 1: Clone an Existing Repository

Clone the repository:

```bash
git clone https://github.com/<your-org>/AxiomCorePlatformRepo.git
cd AxiomCorePlatformRepo
```

#### Option 2: Initialize a New Repository

If you're starting a new AxiomCore project from scratch:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin git@github.com:<your-org>/AxiomCorePlatformRepo.git
git push -u origin main
```

> **Note**: Option 1 uses HTTPS for cloning (works without SSH keys), while Option 2 uses SSH for pushing (requires SSH key setup). You can use either protocol for both operations based on your preference and authentication setup.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Reviewing Pull Requests

To review and test a pull request locally:

1. Navigate to your local repository:

```bash
cd /path/to/AxiomCorePlatformRepo
```

2. Fetch the PR branch (replace `<PR_NUMBER>` with the actual PR number):

```bash
git fetch origin pull/<PR_NUMBER>/head:pr-<PR_NUMBER>
```

3. Check out the PR branch:

```bash
git checkout pr-<PR_NUMBER>
```

4. Test the changes as needed, then return to your main branch:

```bash
git checkout main
```

**Example**: To review PR #42:

```bash
git fetch origin pull/42/head:pr-42
git checkout pr-42
# Test the changes...
git checkout main
```
