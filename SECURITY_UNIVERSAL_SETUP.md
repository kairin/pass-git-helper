# Universal Safety Security Setup Guide

This guide helps you deploy Safety CLI security scanning across all your repositories with a universal configuration.

## Quick Setup (For New Repositories)

### 1. Download and Run Universal Setup
```bash
# Download the universal setup script
curl -O https://raw.githubusercontent.com/langtech-bsc/pass-git-helper/main/scripts/setup-universal-security.sh
chmod +x setup-universal-security.sh

# Run universal setup (will configure Safety globally)
./setup-universal-security.sh
```

### 2. Copy Security Files to Your Repository
```bash
# Copy the multi-layer security scanner
curl -O https://raw.githubusercontent.com/langtech-bsc/pass-git-helper/main/scripts/security-scan.sh
chmod +x security-scan.sh

# Copy GitHub Actions workflow
mkdir -p .github/workflows
curl -O https://raw.githubusercontent.com/langtech-bsc/pass-git-helper/main/.github/workflows/security-scan.yml
mv security-scan.yml .github/workflows/
```

### 3. Add Security Tools to Requirements
Add to your `requirements-dev.txt` or `pyproject.toml`:
```text
safety>=3.0.0
pip-audit>=2.6.0
bandit[toml]>=1.7.0
```

### 4. Configure GitHub Repository Secret
1. Go to your repository on GitHub
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `SAFETY_API_KEY`
5. Value: `cbfb5d21-6a92-451d-8002-b4405bb6ca83`

## Manual Setup Steps

### Environment Configuration

The universal setup creates `~/.safety_env` with:
```bash
# Safety CLI Universal Configuration
export SAFETY_API_KEY="cbfb5d21-6a92-451d-8002-b4405bb6ca83"
export SAFETY_STAGE="development"

# Safety aliases for quick access
alias safety-scan="safety --key $SAFETY_API_KEY scan"
alias safety-check="safety --key $SAFETY_API_KEY check"
alias safety-license="safety --key $SAFETY_API_KEY license"
alias safety-review="safety --key $SAFETY_API_KEY review"

# Firewall protection for all package managers
export SAFETY_FIREWALL=true
```

### Shell Integration

The setup automatically adds to your shell profile:
```bash
# Load Safety configuration
if [ -f ~/.safety_env ]; then
    source ~/.safety_env
fi
```

### Repository-Level Configuration

Each repository gets a local security scanner (`scripts/security-scan.sh`) that:

1. **Primary**: Uses Safety CLI with your API key
2. **Fallback**: Uses pip-audit + bandit if Safety fails
3. **Output**: Comprehensive security report

## GitHub Actions Integration

The workflow file provides:
- **Automated scanning** on push/PR
- **Weekly schedule** (Sundays 2 AM UTC)
- **Multi-layer protection** (Safety + pip-audit + bandit)
- **Clear reporting** with next steps

## Usage Examples

### Local Development
```bash
# Quick security scan
./scripts/security-scan.sh

# Individual tools
safety-scan                    # Premium vulnerability scan
pip-audit --desc              # Free dependency audit
bandit -r . -f txt            # Source code analysis
```

### CI/CD Integration
The GitHub Actions workflow runs automatically but you can also:
```bash
# Test the workflow locally
act push

# Manual trigger
gh workflow run security-scan.yml
```

## Universal Commands

Once configured, these work in ANY repository:

```bash
# Global Safety commands (work everywhere)
safety-scan
safety-check  
safety-license
safety-review

# Global environment
echo $SAFETY_API_KEY          # Your API key
echo $SAFETY_STAGE           # development/cicd
echo $SAFETY_FIREWALL        # Protection status
```

## Troubleshooting

### Safety API Key Issues
```bash
# Check if configured
safety auth status

# Re-authenticate if needed
safety auth login
```

### GitHub Actions Issues
1. Verify `SAFETY_API_KEY` secret is set
2. Check workflow permissions
3. Review action logs for specific errors

### Local Scanner Issues
```bash
# Test individual components
python -c "import safety; print(safety.__version__)"
pip-audit --version
bandit --version
```

## Security Benefits

### Multi-Layer Protection
- **Safety CLI**: Premium vulnerability database, policy enforcement
- **pip-audit**: Free OSV database scanning  
- **bandit**: Static source code analysis
- **Safety Firewall**: Real-time package installation protection

### Universal Coverage
- Same configuration across all repositories
- Consistent security policies
- Centralized API key management
- Automated deployment via scripts

### Cost-Effective
- Premium Safety features when available
- Free fallback tools ensure coverage
- No vendor lock-in
- Scalable across unlimited repositories

## Template Files

You can use this repository as a template for new projects:

1. Fork or clone `pass-git-helper`
2. Run `./scripts/setup-universal-security.sh`
3. Copy `scripts/security-scan.sh` and `.github/workflows/security-scan.yml`
4. Add GitHub repository secret `SAFETY_API_KEY`

This ensures consistent security setup across your entire codebase portfolio.

## Support

- Safety CLI Documentation: https://docs.safetycli.com/
- pip-audit: https://pypi.org/project/pip-audit/
- bandit: https://bandit.readthedocs.io/
- GitHub Actions: https://docs.github.com/en/actions
