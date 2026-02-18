# axiomcore

AxiomCore MVP — backend, frontend, AI orchestration

## Description

This repository serves as the foundation for the AxiomCore MVP platform, providing backend services, frontend interfaces, and AI orchestration capabilities. The project is a comprehensive full-stack solution supporting both PowerShell and Python development environments.

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

#### Option 1: Clone the Repository

Clone the repository:

```bash
git clone https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git
cd axiomcore
```

#### Option 2: Create a New Repository

If you need to create a new axiomcore repository, you can use the provided scripts:

**Using Bash (Linux/macOS):**
```bash
./create-repo.sh
```

**Using PowerShell (Windows/Cross-platform):**
```powershell
./create-repo.ps1
```

**Or manually with GitHub CLI:**
```bash
gh repo create TechFusion-Quantum-Global-Platform/axiomcore \
  --private \
  --description "AxiomCore MVP — backend, frontend, AI orchestration" \
  --confirm
```

After creating the repository, you can initialize it with your project files:

```bash
# Clone the empty repository
git clone https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git
cd axiomcore

# Copy your project files into the directory
# Then commit and push them
git add .
git commit -m "Initial commit"
git push -u origin main
```

> **Note**: Option 2 requires GitHub CLI (`gh`) to be installed and authenticated. The repository will be created as private under the TechFusion-Quantum-Global-Platform organization.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
