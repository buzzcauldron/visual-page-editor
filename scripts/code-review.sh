#!/bin/bash
# Automated code review script for visual-page-editor
# Runs linting, syntax checks, and other validations

# Don't exit on error - we want to check all files and report all issues
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to print section header
print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${YELLOW}Warning: $1 not found. Skipping $1 checks.${NC}"
        return 1
    fi
    return 0
}

# Function to count errors
count_error() {
    ERRORS=$((ERRORS + 1))
    echo -e "${RED}✗ $1${NC}"
}

# Function to count warnings
count_warning() {
    WARNINGS=$((WARNINGS + 1))
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to report success
report_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_section "Code Review - Visual Page Editor"

# Check JavaScript files
print_section "JavaScript Files"
if check_command jshint; then
    JS_FILES=$(find js -name "*.js" -not -name "*.min.js" 2>/dev/null | head -20)
    for file in $JS_FILES; do
        if [ -f "$file" ]; then
            echo "Checking $file..."
            if jshint "$file" 2>&1; then
                report_success "$file"
            else
                count_error "$file has linting errors"
            fi
        fi
    done
fi

# Check HTML files
print_section "HTML Files"
HTML_FILES=$(find html -name "*.html" 2>/dev/null)
for file in $HTML_FILES; do
    if [ -f "$file" ]; then
        echo "Checking $file..."
        # Basic check: file exists and is readable
        if [ -r "$file" ]; then
            # Check for basic HTML structure
            if grep -q "<!DOCTYPE html>" "$file" || grep -q "<html" "$file"; then
                report_success "$file (basic check)"
            else
                count_warning "$file may not have proper HTML structure"
            fi
        else
            count_error "$file is not readable"
        fi
    fi
done

# Check XSLT files
print_section "XSLT Files"
if check_command xmlstarlet; then
    XSLT_FILES=$(find xslt -name "*.xslt" 2>/dev/null)
    for file in $XSLT_FILES; do
        if [ -f "$file" ]; then
            echo "Validating $file..."
            if xmlstarlet val -e "$file" 2>&1; then
                report_success "$file"
            else
                count_error "$file has XML validation errors"
            fi
        fi
    done
fi

# Check XSD files
print_section "XSD Files"
if check_command xmlstarlet; then
    XSD_FILES=$(find xsd -name "*.xsd" 2>/dev/null)
    for file in $XSD_FILES; do
        if [ -f "$file" ]; then
            echo "Validating $file..."
            if xmlstarlet val -e "$file" 2>&1; then
                report_success "$file"
            else
                count_error "$file has XML validation errors"
            fi
        fi
    done
fi

# Check PHP files
print_section "PHP Files"
if check_command php; then
    PHP_FILES=$(find web-app -name "*.php" 2>/dev/null)
    for file in $PHP_FILES; do
        if [ -f "$file" ]; then
            echo "Checking $file..."
            if php -l "$file" 2>&1 | grep -q "No syntax errors"; then
                report_success "$file"
            else
                count_error "$file has PHP syntax errors"
                php -l "$file" 2>&1 || true
            fi
        fi
    done
fi

# Check Shell scripts
print_section "Shell Scripts"
SHELL_SCRIPTS=$(find . -type f \( -name "*.sh" -o -name "*.bash" \) -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./nwjs*/*" -not -path "./build-*/*" 2>/dev/null)
for file in $SHELL_SCRIPTS; do
    if [ -f "$file" ]; then
        echo "Checking $file..."
        if bash -n "$file" 2>&1; then
            report_success "$file"
        else
            count_error "$file has shell syntax errors"
            bash -n "$file" 2>&1 || true
        fi
    fi
done

# Check Batch files (basic)
print_section "Batch Files"
BATCH_FILES=$(find . -name "*.bat" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./nwjs*/*" -not -path "./build-*/*" 2>/dev/null)
for file in $BATCH_FILES; do
    if [ -f "$file" ]; then
        # Basic check: file exists and has content
        if [ -s "$file" ]; then
            report_success "$file (basic check)"
        else
            count_warning "$file is empty"
        fi
    fi
done

# Check PowerShell files
print_section "PowerShell Files"
if check_command pwsh || check_command powershell; then
    PS_FILES=$(find . -name "*.ps1" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./nwjs*/*" -not -path "./build-*/*" 2>/dev/null)
    for file in $PS_FILES; do
        if [ -f "$file" ]; then
            echo "Checking $file..."
            if pwsh -Command "& { Get-Content '$file' | Out-Null }" 2>&1 || powershell -Command "& { Get-Content '$file' | Out-Null }" 2>&1; then
                report_success "$file (basic check)"
            else
                count_warning "$file may have issues"
            fi
        fi
    done
fi

# Check for common issues
print_section "Common Code Issues"

# Check for console.log in production code (warnings only)
CONSOLE_LOGS=$(grep -r "console\.log" js/*.js 2>/dev/null | grep -v "\.min\.js" | grep -v "node_modules" | wc -l | tr -d ' ')
if [ "$CONSOLE_LOGS" -gt 0 ]; then
    count_warning "Found $CONSOLE_LOGS console.log statements (consider removing for production)"
fi

# Check for TODO/FIXME comments
TODO_COUNT=$(grep -r "TODO\|FIXME" js/*.js html/*.html 2>/dev/null | grep -v "\.min\.js" | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Found $TODO_COUNT TODO/FIXME comments${NC}"
fi

# Check for potential security issues (exclude vendor: xmllint.js, *.min.js)
if grep -r "eval(" js/*.js 2>/dev/null | grep -v "\.min\.js" | grep -v "xmllint\.js" | grep -v "node_modules" | grep -q "."; then
    count_warning "Found eval() usage in app code (potential security risk)"
fi

# Check file permissions
print_section "File Permissions"
if [ -f "bin/visual-page-editor" ] && [ ! -x "bin/visual-page-editor" ]; then
    count_warning "bin/visual-page-editor is not executable"
fi

if [ -f "bin/visual-page-editor.bat" ] && [ -x "bin/visual-page-editor.bat" ]; then
    count_warning "bin/visual-page-editor.bat should not be executable on Unix systems"
fi

# Check for required files
print_section "Required Files"
REQUIRED_FILES=("package.json" "README.md" "LICENSE.md" "html/index.html")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        report_success "$file exists"
    else
        count_error "$file is missing"
    fi
done

# Summary
print_section "Review Summary"
echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Review completed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}✗ Review found $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
