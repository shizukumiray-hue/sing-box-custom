#!/bin/bash
# Validation script untuk GitHub Actions workflows
# Run sebelum commit untuk memastikan workflows valid

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_DIR="$SCRIPT_DIR/.github/workflows"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================"
echo -e "GitHub Actions Workflow Validator"
echo -e "======================================${NC}"
echo ""

# Check if workflows directory exists
if [ ! -d "$WORKFLOW_DIR" ]; then
    echo -e "${RED}❌ Error: Workflows directory not found: $WORKFLOW_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}📂 Workflow directory: $WORKFLOW_DIR${NC}"
echo ""

# Count workflows
WORKFLOW_COUNT=$(find "$WORKFLOW_DIR" -name "*.yml" -o -name "*.yaml" | wc -l)
echo -e "${GREEN}Found $WORKFLOW_COUNT workflow files${NC}"
echo ""

# Function to check YAML syntax
check_yaml_syntax() {
    local file=$1
    local filename=$(basename "$file")
    
    echo -n "Checking $filename... "
    
    # Check if yq or python is available for YAML validation
    if command -v yq &> /dev/null; then
        if yq eval '.' "$file" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Valid YAML${NC}"
            return 0
        else
            echo -e "${RED}✗ Invalid YAML${NC}"
            return 1
        fi
    elif command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✓ Valid YAML${NC}"
            return 0
        else
            echo -e "${RED}✗ Invalid YAML${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ Skipped (no YAML validator found)${NC}"
        return 0
    fi
}

# Function to check required fields
check_required_fields() {
    local file=$1
    local filename=$(basename "$file")
    
    echo "Checking required fields in $filename..."
    
    # Check for 'name' field
    if ! grep -q "^name:" "$file"; then
        echo -e "  ${RED}✗ Missing 'name' field${NC}"
        return 1
    else
        echo -e "  ${GREEN}✓ Has 'name' field${NC}"
    fi
    
    # Check for 'on' field
    if ! grep -q "^on:" "$file"; then
        echo -e "  ${RED}✗ Missing 'on' field${NC}"
        return 1
    else
        echo -e "  ${GREEN}✓ Has 'on' field${NC}"
    fi
    
    # Check for 'jobs' field
    if ! grep -q "^jobs:" "$file"; then
        echo -e "  ${RED}✗ Missing 'jobs' field${NC}"
        return 1
    else
        echo -e "  ${GREEN}✓ Has 'jobs' field${NC}"
    fi
    
    return 0
}

# Function to check for common issues
check_common_issues() {
    local file=$1
    local filename=$(basename "$file")
    
    echo "Checking common issues in $filename..."
    
    local issues=0
    
    # Check for tabs (should use spaces)
    if grep -q $'\t' "$file"; then
        echo -e "  ${YELLOW}⚠ Warning: Found tabs (should use spaces)${NC}"
        issues=$((issues + 1))
    fi
    
    # Check for trailing whitespace
    if grep -q " $" "$file"; then
        echo -e "  ${YELLOW}⚠ Warning: Found trailing whitespace${NC}"
        issues=$((issues + 1))
    fi
    
    # Check for very long lines
    if awk 'length > 120' "$file" | grep -q .; then
        echo -e "  ${YELLOW}⚠ Warning: Found lines longer than 120 characters${NC}"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        echo -e "  ${GREEN}✓ No common issues found${NC}"
    fi
    
    return 0
}

# Function to extract and display workflow info
display_workflow_info() {
    local file=$1
    local filename=$(basename "$file")
    
    echo ""
    echo -e "${BLUE}=== Workflow Info: $filename ===${NC}"
    
    # Extract name
    local name=$(grep "^name:" "$file" | head -1 | sed 's/name: *//')
    echo -e "Name: ${GREEN}$name${NC}"
    
    # Extract triggers
    echo "Triggers:"
    if grep -A 20 "^on:" "$file" | grep -q "push:"; then
        echo -e "  ${GREEN}✓ push${NC}"
    fi
    if grep -A 20 "^on:" "$file" | grep -q "pull_request:"; then
        echo -e "  ${GREEN}✓ pull_request${NC}"
    fi
    if grep -A 20 "^on:" "$file" | grep -q "workflow_dispatch:"; then
        echo -e "  ${GREEN}✓ workflow_dispatch${NC}"
    fi
    if grep -A 20 "^on:" "$file" | grep -q "workflow_call:"; then
        echo -e "  ${GREEN}✓ workflow_call${NC}"
    fi
    
    # Extract jobs
    echo "Jobs:"
    grep "^  [a-zA-Z_-]*:" "$file" | sed 's/:$//' | sed 's/^  /  - /'
    
    echo ""
}

# Main validation loop
echo -e "${YELLOW}Starting validation...${NC}"
echo ""

TOTAL_ERRORS=0
TOTAL_WARNINGS=0

for workflow in "$WORKFLOW_DIR"/*.yml "$WORKFLOW_DIR"/*.yaml; do
    if [ -f "$workflow" ]; then
        echo -e "${BLUE}=====================================+${NC}"
        
        # YAML syntax check
        if ! check_yaml_syntax "$workflow"; then
            TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
            continue
        fi
        
        # Required fields check
        if ! check_required_fields "$workflow"; then
            TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
            continue
        fi
        
        # Common issues check
        check_common_issues "$workflow"
        
        # Display info
        display_workflow_info "$workflow"
    fi
done

echo -e "${BLUE}======================================${NC}"
echo ""

# Summary
echo -e "${BLUE}=== Validation Summary ===${NC}"
echo -e "Total workflows checked: ${GREEN}$WORKFLOW_COUNT${NC}"
echo -e "Errors: ${RED}$TOTAL_ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$TOTAL_WARNINGS${NC}"
echo ""

if [ $TOTAL_ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Validation failed with $TOTAL_ERRORS error(s)${NC}"
    echo ""
    echo -e "${YELLOW}Tips:${NC}"
    echo "  1. Install yq for better YAML validation: brew install yq"
    echo "  2. Check workflow syntax at: https://github.com/YOUR_REPO/actions"
    echo "  3. Use GitHub Actions extension for VS Code"
    exit 1
else
    echo -e "${GREEN}✅ All workflows are valid!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Commit workflows: git add .github/workflows/ && git commit -m 'ci: add workflows'"
    echo "  2. Push to GitHub: git push origin main"
    echo "  3. Check Actions tab: https://github.com/YOUR_REPO/actions"
    exit 0
fi
