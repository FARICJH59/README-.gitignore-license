# Contributing to AxiomCore

Thank you for your interest in contributing to AxiomCore! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Contribution Guidelines](#contribution-guidelines)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Contact](#contact)

## Code of Conduct

By participating in this project, you agree to maintain a respectful, inclusive, and professional environment. We expect all contributors to:

- Be respectful and constructive in communications
- Welcome diverse perspectives and experiences
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

Ensure you have the following installed:

- **PowerShell**: 7.0 or higher
- **Python**: 3.8 or higher
- **Node.js**: 18.x or higher (for frontend work)
- **Docker**: 24.x or higher (for containerization)
- **Git**: Latest version

### Repository Setup

1. **Fork the repository** on GitHub
2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/README-.gitignore-license.git
   cd README-.gitignore-license
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/FARICJH59/README-.gitignore-license.git
   ```
4. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### 1. Sync with Upstream

Before starting work, sync with the upstream repository:

```bash
git fetch upstream
git checkout main
git merge upstream/main
```

### 2. Create a Branch

Create a descriptive branch name:

```bash
git checkout -b feature/add-new-feature
# or
git checkout -b fix/fix-bug-description
# or
git checkout -b docs/update-documentation
```

### 3. Make Changes

- Write clear, concise commit messages
- Follow the coding standards (see below)
- Add tests for new features
- Update documentation as needed

### 4. Test Your Changes

Run the appropriate tests based on your changes:

```powershell
# For PowerShell scripts
.\scripts\axiom-compliance.ps1 -RepoPath .

# For Python code
pytest tests/

# For frontend
npm test
```

### 5. Commit Changes

Use descriptive commit messages following this format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example:
```
feat(api): add new endpoint for user authentication

- Implement JWT token generation
- Add rate limiting
- Include comprehensive error handling

Closes #123
```

## Contribution Guidelines

### What We're Looking For

- Bug fixes
- Feature enhancements
- Documentation improvements
- Performance optimizations
- Test coverage improvements
- Security enhancements

### What We're NOT Looking For

- Breaking changes without discussion
- Features that don't align with project goals
- Poorly documented changes
- Code without tests
- Dependency updates without justification

## Pull Request Process

### Before Submitting

1. **Update documentation** if you changed functionality
2. **Add tests** for new features or bug fixes
3. **Run all tests** and ensure they pass
4. **Check code quality**:
   ```powershell
   # PowerShell
   Invoke-ScriptAnalyzer -Path ./scripts -Recurse
   
   # Python
   pylint your_file.py
   black your_file.py
   ```
5. **Update CHANGELOG** (if applicable)

### Submitting a Pull Request

1. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create pull request** on GitHub with:
   - Clear title describing the change
   - Detailed description of what changed and why
   - Reference any related issues
   - Screenshots (if UI changes)
   - Test results

3. **PR Template**:
   ```markdown
   ## Description
   Brief description of the changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   - [ ] All existing tests pass
   - [ ] New tests added
   - [ ] Manual testing completed
   
   ## Checklist
   - [ ] Code follows project style guidelines
   - [ ] Self-review completed
   - [ ] Documentation updated
   - [ ] No new warnings generated
   ```

### Review Process

1. **Code Owner Review**: Required (see `.github/CODEOWNERS`)
2. **CI/CD Checks**: Must pass automated tests
3. **Discussion**: Address reviewer feedback
4. **Approval**: At least one approval required
5. **Merge**: Maintainer will merge when ready

### After Merge

- Delete your branch
- Pull latest changes from upstream
- Thank reviewers!

## Coding Standards

### PowerShell

- Use approved verbs (`Get-`, `Set-`, `New-`, etc.)
- Include comment-based help
- Use `Set-StrictMode -Version Latest`
- Follow PascalCase for functions
- Use meaningful variable names

Example:
```powershell
function Get-UserData {
    <#
    .SYNOPSIS
    Retrieves user data from the database
    
    .PARAMETER UserId
    The unique identifier for the user
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserId
    )
    
    Set-StrictMode -Version Latest
    # Implementation
}
```

### Python

- Follow PEP 8 style guide
- Use type hints
- Write docstrings for all functions
- Use meaningful variable names
- Keep functions focused and small

Example:
```python
def get_user_data(user_id: str) -> dict:
    """
    Retrieve user data from the database.
    
    Args:
        user_id: The unique identifier for the user
        
    Returns:
        Dictionary containing user data
        
    Raises:
        ValueError: If user_id is invalid
    """
    # Implementation
```

### JavaScript/TypeScript

- Use ESLint configuration
- Follow Airbnb style guide
- Use meaningful variable names
- Write JSDoc comments
- Prefer functional programming patterns

### Documentation

- Use Markdown for documentation
- Include code examples
- Keep explanations clear and concise
- Update relevant docs with code changes

## Testing

### Test Requirements

- **Unit Tests**: For all new functions/methods
- **Integration Tests**: For API endpoints and workflows
- **Coverage**: Maintain 80% minimum (as per project.yaml)

### Running Tests

```powershell
# PowerShell tests
Invoke-Pester

# Python tests
pytest tests/ --cov=. --cov-report=html

# JavaScript tests
npm test
```

### Test Guidelines

- Test both success and failure cases
- Use descriptive test names
- Keep tests independent
- Mock external dependencies
- Test edge cases

## Documentation

Update documentation when you:

- Add new features
- Change existing functionality
- Fix bugs that affect usage
- Update dependencies
- Modify configuration

Documentation locations:
- `/docs/` - Main documentation
- `README.md` - Project overview
- Code comments - Inline explanations
- `CHANGELOG.md` - Version history

## Contact

- **Primary Maintainer**: FARICJH59
- **Email**: farichva@gmail.com
- **Repository**: https://github.com/FARICJH59/README-.gitignore-license
- **Issues**: Use GitHub Issues for bugs and feature requests

## Recognition

Contributors will be recognized in:
- Project README
- Release notes
- Contributor list

Thank you for contributing to AxiomCore! 🚀

---

**Last Updated**: 2026-02-19  
**Version**: 1.0
