# AxiomCore Devcontainer Configuration

This directory contains the configuration for GitHub Codespaces and VS Code Dev Containers.

## Files

- **devcontainer.json**: Main configuration file defining the development environment

## What This Configuration Provides

### Development Tools

- **PowerShell 7.x**: For running .ps1 scripts and PowerShell-based automation
- **Python 3.8+**: For Python applications and AI services
- **Node.js 18.x**: For frontend development and npm packages
- **Git**: Version control
- **GitHub CLI**: For GitHub operations
- **Docker**: For containerization (Docker-in-Docker)

### VS Code Extensions

Pre-installed extensions for optimal development experience:
- PowerShell language support
- Python language support with Pylance
- ESLint for JavaScript/TypeScript linting
- Prettier for code formatting
- YAML language support
- GitHub Pull Requests integration
- GitLens for enhanced Git capabilities
- Docker extension

### Port Forwarding

Automatically forwards these ports when services start:
- **8080**: API Server
- **3000**: Frontend Dev Server
- **5000**: Python Service

### Automatic Setup

When the Codespace is created:
1. Displays welcome message
2. Makes shell scripts executable
3. Configures Git safe directory

### Environment Variables

Sets `AXIOMCORE_ENV=codespaces` to identify the environment

## Customization

To customize this configuration for your needs:

1. Edit `devcontainer.json`
2. Add/remove VS Code extensions
3. Modify port forwarding
4. Update post-creation commands
5. Commit and push changes

The next time you create a Codespace, it will use your updated configuration.

## Resources

- [Devcontainer Specification](https://containers.dev/)
- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/remote/containers)
