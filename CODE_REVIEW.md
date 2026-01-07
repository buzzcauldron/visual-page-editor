# Automated Code Review

This project includes automated code review tools to ensure code quality and catch issues before they're committed.

## Quick Start

Run the automated code review:

```bash
npm run review
# or
./scripts/code-review.sh
```

## What Gets Checked

### JavaScript Files
- **JSHint**: Syntax and style checking
- **Node.js syntax check**: Validates JavaScript syntax
- **Common issues**: Console.log statements, TODO comments, eval() usage

### HTML Files
- **XML/HTML validation**: Checks for well-formed HTML
- **Basic structure**: Ensures required elements exist

### XSLT Files
- **XML validation**: Validates XML structure
- **XSLT syntax**: Checks for valid XSLT syntax

### XSD Files
- **XML Schema validation**: Ensures valid XML Schema definitions

### PHP Files
- **PHP syntax**: Checks for PHP syntax errors using `php -l`

### Shell Scripts
- **Bash syntax**: Validates shell script syntax using `bash -n`
- **File permissions**: Checks executable permissions

### Batch Files (Windows)
- **Basic validation**: Checks file existence and content

### PowerShell Files
- **Basic validation**: Checks PowerShell script structure

## Pre-commit Hook

The git pre-commit hook automatically runs code review before each commit. It checks:

1. **Modified files only**: Only checks files that are being committed
2. **Version updates**: Automatically updates version strings in modified files
3. **Syntax validation**: Runs appropriate validators for each file type
4. **Blocks commits**: Prevents commits if errors are found

### Setting up the pre-commit hook

```bash
# The hook is automatically set up when you run:
./githook-pre-commit
```

Or manually:
```bash
ln -s ../../githook-pre-commit .git/hooks/pre-commit
```

## GitHub Actions

Automated code review runs on every push and pull request via GitHub Actions. The workflow:

- Runs on Ubuntu
- Installs required tools (jshint, xmlstarlet)
- Runs comprehensive code review
- Reports results in the GitHub Actions tab

## Manual Review

You can run the review script manually at any time:

```bash
# Full review
./scripts/code-review.sh

# Or via npm
npm run review
```

## Configuration

### JSHint Configuration

JSHint settings are in `.jshintrc`. Key settings:
- ES6 support enabled
- Browser and Node.js globals
- jQuery support
- Undefined variable checking
- Unused variable warnings

### Customizing Checks

Edit `scripts/code-review.sh` to:
- Add new file types
- Modify validation rules
- Add custom checks
- Change error thresholds

## Common Issues and Fixes

### JSHint Errors

**Undefined variable:**
```javascript
// Bad
myVar = 5;

// Good
var myVar = 5;
```

**Unused variable:**
```javascript
// Remove unused variables or prefix with underscore
var _unusedVar = 5;
```

### XML Validation Errors

**Malformed XML:**
- Check for unclosed tags
- Verify attribute quoting
- Ensure proper nesting

### Shell Script Errors

**Syntax errors:**
- Check for proper quoting
- Verify variable expansion
- Ensure proper line endings (Unix format)

## Continuous Integration

The code review is integrated into:
- **Git pre-commit hooks**: Runs before each commit
- **GitHub Actions**: Runs on push/PR
- **Manual execution**: Run anytime with `npm run review`

## Exit Codes

- `0`: All checks passed
- `1`: Errors found (commit will be blocked)
- Warnings don't block commits but are reported

## Troubleshooting

### JSHint not found
```bash
npm install -g jshint
```

### xmlstarlet not found
```bash
# macOS
brew install xmlstarlet

# Ubuntu/Debian
sudo apt-get install xmlstarlet

# Fedora/RHEL
sudo dnf install xmlstarlet
```

### Review script not executable
```bash
chmod +x scripts/code-review.sh
```

## Best Practices

1. **Run review before committing**: Use `npm run review` before `git commit`
2. **Fix warnings**: Address warnings even if they don't block commits
3. **Keep dependencies updated**: Ensure review tools are up to date
4. **Review CI results**: Check GitHub Actions for automated review results
