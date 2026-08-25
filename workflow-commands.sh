#!/bin/bash
# Quick reference commands for GitHub Actions workflow

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo -e "GitHub Actions Workflow - Quick Commands"
echo -e "==========================================${NC}"
echo ""

# Function to print section
print_section() {
    echo -e "${GREEN}$1${NC}"
    echo "---"
}

# 1. Manual Trigger via GitHub CLI
print_section "1. Trigger Build via GitHub CLI"
echo -e "${YELLOW}# Install GitHub CLI (if not installed)${NC}"
echo "sudo apt install gh  # atau brew install gh"
echo ""
echo -e "${YELLOW}# Login${NC}"
echo "gh auth login"
echo ""
echo -e "${YELLOW}# Trigger full APK build${NC}"
echo "gh workflow run build-apk.yml --field build_type=other --field create_release=false"
echo ""
echo -e "${YELLOW}# Trigger libbox only build${NC}"
echo "gh workflow run build-libbox.yml --field go_version=1.24.7"
echo ""

# 2. Create Release Tag
print_section "2. Create Release Tag (Automated Build + Release)"
echo -e "${YELLOW}# Tag current commit${NC}"
echo "git tag -a v1.14.0 -m 'Release v1.14.0 - Custom SSH WebSocket'"
echo ""
echo -e "${YELLOW}# Push tag to trigger workflow${NC}"
echo "git push origin v1.14.0"
echo ""
echo -e "${YELLOW}# Workflow will automatically create GitHub release${NC}"
echo ""

# 3. Check Workflow Status
print_section "3. Check Workflow Status"
echo -e "${YELLOW}# List all workflows${NC}"
echo "gh workflow list"
echo ""
echo -e "${YELLOW}# View recent runs${NC}"
echo "gh run list --workflow=build-apk.yml --limit 5"
echo ""
echo -e "${YELLOW}# Watch specific run${NC}"
echo "gh run watch <run-id>"
echo ""
echo -e "${YELLOW}# View run logs${NC}"
echo "gh run view <run-id> --log"
echo ""

# 4. Download Artifacts
print_section "4. Download Build Artifacts"
echo -e "${YELLOW}# List artifacts from a run${NC}"
echo "gh run view <run-id>"
echo ""
echo -e "${YELLOW}# Download all artifacts${NC}"
echo "gh run download <run-id>"
echo ""
echo -e "${YELLOW}# Download specific artifact${NC}"
echo "gh run download <run-id> --name apk-other-abc123f"
echo ""

# 5. Trigger via API
print_section "5. Trigger via GitHub API (Advanced)"
echo -e "${YELLOW}# Set your GitHub token${NC}"
echo "export GITHUB_TOKEN=your_github_token"
echo ""
echo -e "${YELLOW}# Trigger workflow${NC}"
cat << 'EOF'
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/workflows/build-apk.yml/dispatches \
  -d '{
    "ref": "main",
    "inputs": {
      "build_type": "other",
      "create_release": "false"
    }
  }'
EOF
echo ""

# 6. Local Testing Before Push
print_section "6. Local Testing (Before Pushing to GitHub)"
echo -e "${YELLOW}# Test libbox build locally${NC}"
echo "cd sing-box"
echo "make lib_android"
echo ""
echo -e "${YELLOW}# Test full Android build locally${NC}"
echo "./build-ssh-ws-android.sh"
echo ""

# 7. Install APK
print_section "7. Install APK to Device"
echo -e "${YELLOW}# After downloading artifacts, extract and install${NC}"
echo "unzip apk-other-*.zip"
echo ""
echo -e "${YELLOW}# Install to connected device${NC}"
echo "adb install SFA-*-arm64-v8a-*.apk"
echo ""
echo -e "${YELLOW}# Install and replace existing${NC}"
echo "adb install -r SFA-*-arm64-v8a-*.apk"
echo ""
echo -e "${YELLOW}# Install to specific device${NC}"
echo "adb -s <device-id> install SFA-*-arm64-v8a-*.apk"
echo ""

# 8. Monitoring & Debug
print_section "8. Monitoring & Debug"
echo -e "${YELLOW}# View workflow file${NC}"
echo "cat .github/workflows/build-apk.yml"
echo ""
echo -e "${YELLOW}# Validate workflow syntax (requires act)${NC}"
echo "act -l  # List jobs"
echo "act --dry-run  # Dry run"
echo ""
echo -e "${YELLOW}# Check Actions tab on GitHub${NC}"
echo "https://github.com/YOUR_USERNAME/sing-box/actions"
echo ""

# 9. Common Issues
print_section "9. Troubleshooting Commands"
echo -e "${YELLOW}# Re-run failed workflow${NC}"
echo "gh run rerun <run-id>"
echo ""
echo -e "${YELLOW}# Re-run only failed jobs${NC}"
echo "gh run rerun <run-id> --failed"
echo ""
echo -e "${YELLOW}# Cancel running workflow${NC}"
echo "gh run cancel <run-id>"
echo ""
echo -e "${YELLOW}# Delete workflow run${NC}"
echo "gh run delete <run-id>"
echo ""

# 10. Cleanup
print_section "10. Cleanup Old Artifacts"
echo -e "${YELLOW}# List all runs${NC}"
echo "gh run list --limit 100"
echo ""
echo -e "${YELLOW}# Delete old runs (cleanup)${NC}"
cat << 'EOF'
# Delete runs older than 30 days
gh run list --limit 100 --json databaseId,createdAt \
  --jq '.[] | select(.createdAt < (now - 2592000)) | .databaseId' \
  | xargs -I {} gh run delete {}
EOF
echo ""

# Example Workflow
echo ""
print_section "📋 Example: Complete Build & Release Workflow"
echo ""
echo -e "${BLUE}Step 1: Make changes to sing-box${NC}"
echo "vim sing-box/some-file.go"
echo ""
echo -e "${BLUE}Step 2: Commit changes${NC}"
echo "git add ."
echo "git commit -m 'feat: add custom SSH payload'"
echo ""
echo -e "${BLUE}Step 3: Push to trigger build${NC}"
echo "git push origin main"
echo ""
echo -e "${BLUE}Step 4: Monitor build${NC}"
echo "gh run list --workflow=build-apk.yml"
echo "gh run watch"
echo ""
echo -e "${BLUE}Step 5: Download APK${NC}"
echo "gh run download <run-id>"
echo ""
echo -e "${BLUE}Step 6: Install to device${NC}"
echo "adb install apk-other-*/SFA-*-arm64-v8a-*.apk"
echo ""
echo -e "${BLUE}Step 7: (Optional) Create release tag${NC}"
echo "git tag -a v1.14.1 -m 'Release v1.14.1'"
echo "git push origin v1.14.1"
echo ""

echo -e "${GREEN}=========================================="
echo -e "For detailed documentation, see:"
echo -e "  README-BUILD.md"
echo -e "==========================================${NC}"
