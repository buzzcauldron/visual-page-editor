#!/bin/bash
# Mock installation check script for visual-page-editor
# This script simulates installation and checks for potential errors

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Visual Page Editor - Installation Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to report errors
report_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    ERRORS=$((ERRORS + 1))
}

# Function to report warnings
report_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

# Function to report success
report_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}Checking project structure...${NC}"

# Check required directories
REQUIRED_DIRS=("html" "js" "css" "bin" "xslt" "xsd" "examples")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$PROJECT_ROOT/$dir" ]; then
        report_error "Required directory missing: $dir"
    else
        report_success "Directory exists: $dir"
    fi
done

echo ""
echo -e "${BLUE}Checking required files...${NC}"

# Check required files
REQUIRED_FILES=(
    "package.json"
    "html/index.html"
    "bin/visual-page-editor"
    "README.md"
    "LICENSE.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$PROJECT_ROOT/$file" ]; then
        report_error "Required file missing: $file"
    else
        report_success "File exists: $file"
    fi
done

echo ""
echo -e "${BLUE}Checking JavaScript files...${NC}"

# Check critical JS files
CRITICAL_JS=(
    "js/page-canvas.js"
    "js/page-editor.js"
    "js/svg-canvas.js"
    "js/nw-app.js"
    "js/web-app.js"
)

for jsfile in "${CRITICAL_JS[@]}"; do
    if [ ! -f "$PROJECT_ROOT/$jsfile" ]; then
        report_error "Critical JS file missing: $jsfile"
    else
        # Check for syntax errors (basic check)
        if grep -q "function\|var\|=" "$PROJECT_ROOT/$jsfile" 2>/dev/null; then
            report_success "JS file exists: $jsfile"
        else
            report_warning "JS file may be empty or corrupted: $jsfile"
        fi
    fi
done

echo ""
echo -e "${BLUE}Checking shell scripts...${NC}"

# Check shell scripts for syntax
SHELL_SCRIPTS=(
    "bin/visual-page-editor"
    "build-macos.sh"
    "build-deb.sh"
    "build-docker.sh"
    "scripts/code-review.sh"
)

for script in "${SHELL_SCRIPTS[@]}"; do
    if [ ! -f "$PROJECT_ROOT/$script" ]; then
        report_error "Shell script missing: $script"
    else
        # Check syntax
        if bash -n "$PROJECT_ROOT/$script" 2>/dev/null; then
            report_success "Shell script syntax OK: $script"
        else
            report_error "Shell script syntax error: $script"
        fi
    fi
done

echo ""
echo -e "${BLUE}Checking file permissions...${NC}"

# Check executable permissions
EXECUTABLE_SCRIPTS=(
    "bin/visual-page-editor"
    "build-macos.sh"
    "build-deb.sh"
    "build-docker.sh"
)

for script in "${EXECUTABLE_SCRIPTS[@]}"; do
    if [ -f "$PROJECT_ROOT/$script" ]; then
        if [ -x "$PROJECT_ROOT/$script" ]; then
            report_success "Executable permission OK: $script"
        else
            report_warning "Missing executable permission: $script (run: chmod +x $script)"
        fi
    fi
done

echo ""
echo -e "${BLUE}Checking package.json...${NC}"

if [ -f "$PROJECT_ROOT/package.json" ]; then
    # Check if package.json is valid JSON
    if command -v node >/dev/null 2>&1; then
        if node -e "JSON.parse(require('fs').readFileSync('$PROJECT_ROOT/package.json', 'utf8'))" 2>/dev/null; then
            report_success "package.json is valid JSON"
        else
            report_error "package.json is not valid JSON"
        fi
    else
        report_warning "Node.js not found, skipping package.json validation"
    fi
    
    # Check for required fields
    if grep -q '"name"' "$PROJECT_ROOT/package.json" && \
       grep -q '"version"' "$PROJECT_ROOT/package.json" && \
       grep -q '"main"' "$PROJECT_ROOT/package.json"; then
        report_success "package.json has required fields"
    else
        report_error "package.json missing required fields"
    fi
fi

echo ""
echo -e "${BLUE}Checking HTML structure...${NC}"

if [ -f "$PROJECT_ROOT/html/index.html" ]; then
    # Check for required elements
    if grep -q "<!DOCTYPE html\|<html\|<head\|<body" "$PROJECT_ROOT/html/index.html" 2>/dev/null; then
        report_success "HTML structure appears valid"
    else
        report_warning "HTML structure may be incomplete"
    fi
    
    # Check for script tags
    SCRIPT_COUNT=$(grep -c "<script" "$PROJECT_ROOT/html/index.html" 2>/dev/null || echo "0")
    if [ "$SCRIPT_COUNT" -gt 0 ]; then
        report_success "HTML contains $SCRIPT_COUNT script tag(s)"
    else
        report_warning "HTML may be missing script tags"
    fi
fi

echo ""
echo -e "${BLUE}Checking XSLT files...${NC}"

XSLT_FILES=(
    "xslt/page2svg.xslt"
    "xslt/svg2page.xslt"
    "xslt/page2page.xslt"
)

for xslt in "${XSLT_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$xslt" ]; then
        report_success "XSLT file exists: $xslt"
    else
        report_warning "XSLT file missing: $xslt (may cause import/export issues)"
    fi
done

echo ""
echo -e "${BLUE}Checking XSD files...${NC}"

XSD_FILES=(
    "xsd/pagecontent_omnius.xsd"
    "xsd/pagecontent_searchink.xsd"
)

for xsd in "${XSD_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$xsd" ]; then
        report_success "XSD file exists: $xsd"
    else
        report_warning "XSD file missing: $xsd (may cause validation issues)"
    fi
done

echo ""
echo -e "${BLUE}Checking for common issues...${NC}"

# Check for hardcoded paths
if grep -r "/Users/\|/home/\|C:\\\\" "$PROJECT_ROOT/js" "$PROJECT_ROOT/bin" 2>/dev/null | grep -v ".min.js" | grep -v "node_modules" | head -5 | grep -q .; then
    report_warning "Found potential hardcoded paths in code"
else
    report_success "No hardcoded paths detected"
fi

# Check for missing dependencies in package.json
if [ -f "$PROJECT_ROOT/package.json" ]; then
    if grep -q '"dependencies"' "$PROJECT_ROOT/package.json"; then
        report_success "package.json has dependencies section"
    else
        report_warning "package.json missing dependencies section"
    fi
fi

# Check for .gitignore
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    report_success ".gitignore exists"
else
    report_warning ".gitignore missing"
fi

echo ""
echo -e "${BLUE}Checking build scripts for common errors...${NC}"

# Check build-macos.sh
if [ -f "$PROJECT_ROOT/build-macos.sh" ]; then
    # Check for required variables
    if grep -q "NWJS_VERSION\|APP_NAME\|BUILD_DIR" "$PROJECT_ROOT/build-macos.sh"; then
        report_success "build-macos.sh has required variables"
    else
        report_warning "build-macos.sh may be missing required variables"
    fi
fi

# Check build-deb.sh
if [ -f "$PROJECT_ROOT/build-deb.sh" ]; then
    # Check for required tools check
    if grep -q "check_requirements\|dpkg-buildpackage" "$PROJECT_ROOT/build-deb.sh"; then
        report_success "build-deb.sh has requirements check"
    else
        report_warning "build-deb.sh may be missing requirements check"
    fi
fi

echo ""
echo -e "${BLUE}Checking launcher script...${NC}"

if [ -f "$PROJECT_ROOT/bin/visual-page-editor" ]; then
    # Check for platform detection
    if grep -q "PLATFORM\|uname" "$PROJECT_ROOT/bin/visual-page-editor"; then
        report_success "Launcher has platform detection"
    else
        report_warning "Launcher may be missing platform detection"
    fi
    
    # Check for NW.js detection
    if grep -q "nwjs\|NW.js" "$PROJECT_ROOT/bin/visual-page-editor"; then
        report_success "Launcher has NW.js detection"
    else
        report_warning "Launcher may be missing NW.js detection"
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Installation Check Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Installation should work correctly.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Check completed with $WARNINGS warning(s)${NC}"
    echo -e "${YELLOW}  Installation should work, but review warnings above.${NC}"
    exit 0
else
    echo -e "${RED}✗ Check found $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo -e "${RED}  Please fix errors before installation.${NC}"
    exit 1
fi
