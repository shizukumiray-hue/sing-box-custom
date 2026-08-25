# GitHub Actions Trigger Examples

Kumpulan contoh untuk trigger GitHub Actions workflows.

## 📋 Table of Contents

- [Via GitHub Web Interface](#via-github-web-interface)
- [Via GitHub CLI](#via-github-cli)
- [Via Git Commands](#via-git-commands)
- [Via GitHub API](#via-github-api)
- [Automated Triggers](#automated-triggers)

---

## 🌐 Via GitHub Web Interface

### Trigger Manual Build

1. **Navigate to Actions**
   ```
   https://github.com/YOUR_USERNAME/sing-box/actions
   ```

2. **Select Workflow**
   - Click "Build sing-box Android APK" dari list

3. **Run Workflow**
   - Click tombol **"Run workflow"**
   - Pilih options:
     - **Use workflow from**: `main` (atau branch lain)
     - **Build type**: `other` / `play` / `otherLegacy`
     - **Create release**: ☐ (unchecked untuk build only)

4. **Monitor**
   - Workflow akan mulai running
   - Click pada run untuk melihat progress

---

## 💻 Via GitHub CLI

### Setup GitHub CLI

```bash
# Install (Ubuntu/Debian)
sudo apt install gh

# Install (macOS)
brew install gh

# Install (Windows)
winget install GitHub.cli

# Login
gh auth login
```

### Trigger Workflows

#### 1. Trigger Full APK Build

```bash
# Build dengan default settings (other flavor)
gh workflow run build-apk.yml

# Build dengan specific options
gh workflow run build-apk.yml \
  --field build_type=other \
  --field create_release=false

# Build play flavor
gh workflow run build-apk.yml \
  --field build_type=play \
  --field create_release=false

# Build legacy version
gh workflow run build-apk.yml \
  --field build_type=otherLegacy \
  --field create_release=false

# Build dan create release
gh workflow run build-apk.yml \
  --field build_type=other \
  --field create_release=true
```

#### 2. Trigger Libbox Only Build

```bash
# Build dengan default Go version
gh workflow run build-libbox.yml

# Build dengan specific Go version
gh workflow run build-libbox.yml \
  --field go_version=1.24.7
```

#### 3. Monitor Workflows

```bash
# List recent runs
gh run list --limit 10

# List specific workflow runs
gh run list --workflow=build-apk.yml --limit 5

# Watch latest run (real-time updates)
gh run watch

# Watch specific run
gh run watch <run-id>

# View run details
gh run view <run-id>

# View run logs
gh run view <run-id> --log

# View specific job logs
gh run view <run-id> --log --job=build-apk
```

#### 4. Download Artifacts

```bash
# Download all artifacts from latest run
gh run download

# Download from specific run
gh run download <run-id>

# Download specific artifact
gh run download <run-id> --name apk-other-abc123f

# List artifacts
gh run view <run-id>
```

#### 5. Manage Runs

```bash
# Re-run workflow
gh run rerun <run-id>

# Re-run only failed jobs
gh run rerun <run-id> --failed

# Cancel running workflow
gh run cancel <run-id>

# Delete workflow run
gh run delete <run-id>
```

---

## 🔖 Via Git Commands

### Push to Branch (Auto-trigger)

```bash
# Make changes
vim some-file.go

# Commit
git add .
git commit -m "feat: add new feature"

# Push to trigger workflow
git push origin main       # Triggers on main
git push origin dev        # Triggers on dev
git push origin feature/x  # Triggers on feature branches
```

### Create Release Tag (Auto-trigger + Release)

```bash
# Create annotated tag
git tag -a v1.14.0 -m "Release v1.14.0 - Custom SSH WebSocket"

# Push tag
git push origin v1.14.0

# Workflow akan:
# 1. Build libbox.aar
# 2. Build APK semua architectures
# 3. Create GitHub Release
# 4. Upload APK ke release
```

### Create Pre-release Tag

```bash
# Alpha release
git tag -a v1.14.0-alpha.1 -m "Alpha release 1.14.0-alpha.1"
git push origin v1.14.0-alpha.1

# Beta release
git tag -a v1.14.0-beta.1 -m "Beta release 1.14.0-beta.1"
git push origin v1.14.0-beta.1

# Release candidate
git tag -a v1.14.0-rc.1 -m "Release candidate 1.14.0-rc.1"
git push origin v1.14.0-rc.1

# Akan create GitHub Release dengan flag "pre-release"
```

### Delete Tag (if needed)

```bash
# Delete local tag
git tag -d v1.14.0

# Delete remote tag
git push origin :refs/tags/v1.14.0
```

---

## 🔌 Via GitHub API

### Setup

```bash
# Set your GitHub token
export GITHUB_TOKEN="ghp_your_token_here"

# Or create ~/.github-token
echo "ghp_your_token_here" > ~/.github-token
chmod 600 ~/.github-token
export GITHUB_TOKEN=$(cat ~/.github-token)
```

### Trigger Workflow

```bash
# Trigger build-apk.yml
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/workflows/build-apk.yml/dispatches \
  -d '{
    "ref": "main",
    "inputs": {
      "build_type": "other",
      "create_release": "false"
    }
  }'

# Trigger build-libbox.yml
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/workflows/build-libbox.yml/dispatches \
  -d '{
    "ref": "main",
    "inputs": {
      "go_version": "1.24.7"
    }
  }'
```

### List Workflow Runs

```bash
# List all runs
curl -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/runs

# List runs for specific workflow
curl -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/workflows/build-apk.yml/runs
```

### Get Run Status

```bash
# Get specific run
curl -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/runs/RUN_ID

# Get run jobs
curl -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/runs/RUN_ID/jobs
```

### Download Artifacts

```bash
# List artifacts
curl -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/runs/RUN_ID/artifacts

# Download artifact (returns redirect URL)
curl -L -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/artifacts/ARTIFACT_ID/zip \
  -o artifact.zip
```

---

## ⚙️ Automated Triggers

### On Push Events

Workflow otomatis trigger pada:

```yaml
on:
  push:
    branches:
      - main
      - dev
      - 'feature/**'
```

**Cara kerja:**
1. Push commit ke branch `main`, `dev`, atau `feature/*`
2. Workflow otomatis run
3. Build APK untuk semua architectures
4. Upload artifacts ke GitHub Actions

### On Tag Push

```yaml
on:
  push:
    tags:
      - 'v*'
```

**Cara kerja:**
1. Push tag dengan format `v*` (e.g., `v1.14.0`)
2. Workflow otomatis run
3. Build APK
4. Create GitHub Release
5. Upload APK ke release

### On Pull Request

```yaml
on:
  pull_request:
    branches:
      - main
```

**Cara kerja:**
1. Create Pull Request ke `main`
2. Workflow otomatis run untuk testing
3. Build APK (tidak create release)
4. Status check muncul di PR

---

## 📝 Example Scenarios

### Scenario 1: Development Build

**Goal:** Build untuk testing, tidak create release

```bash
# Option 1: Push ke dev branch
git checkout dev
git add .
git commit -m "test: new feature"
git push origin dev

# Option 2: Manual trigger
gh workflow run build-apk.yml \
  --field build_type=other \
  --field create_release=false

# Download hasil build
gh run download
```

### Scenario 2: Release Build

**Goal:** Create official release dengan GitHub Release

```bash
# 1. Update version di version.properties
echo "VERSION_CODE=724" > version.properties
echo "VERSION_NAME=1.14.1" >> version.properties

# 2. Commit changes
git add version.properties
git commit -m "chore: bump version to 1.14.1"

# 3. Create and push tag
git tag -a v1.14.1 -m "Release v1.14.1"
git push origin main
git push origin v1.14.1

# 4. Workflow akan otomatis create release
# Check di: https://github.com/YOUR_USERNAME/sing-box/releases
```

### Scenario 3: Quick Test Build (Libbox Only)

**Goal:** Test build libbox saja tanpa build full APK

```bash
# Trigger libbox build only
gh workflow run build-libbox.yml

# Wait dan download
gh run watch
gh run download
```

### Scenario 4: Multi-flavor Build

**Goal:** Build semua flavors (other, play, legacy)

```bash
# Build other flavor
gh workflow run build-apk.yml --field build_type=other

# Build play flavor
gh workflow run build-apk.yml --field build_type=play

# Build legacy flavor
gh workflow run build-apk.yml --field build_type=otherLegacy

# Atau edit workflow untuk build semua sekaligus via matrix
```

### Scenario 5: Automated CI/CD Pipeline

**Setup:**
1. Development di feature branch
2. PR ke main untuk review
3. Merge trigger build
4. Manual tag untuk release

```bash
# 1. Create feature branch
git checkout -b feature/ssh-websocket

# 2. Make changes dan commit
git add .
git commit -m "feat: add SSH WebSocket support"
git push origin feature/ssh-websocket

# 3. Create PR (workflow runs for testing)
gh pr create --title "Add SSH WebSocket" --body "Implementation"

# 4. After review, merge PR
gh pr merge --merge

# 5. Create release tag
git checkout main
git pull
git tag -a v1.15.0 -m "Release v1.15.0"
git push origin v1.15.0

# 6. GitHub Release created automatically!
```

---

## 🔍 Monitoring & Debugging

### Real-time Monitoring

```bash
# Watch latest run
gh run watch

# View live logs
gh run view --log --watch
```

### Check Build Status

```bash
# Quick status check
gh run list --workflow=build-apk.yml --limit 1

# Detailed view
gh run view $(gh run list --workflow=build-apk.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

### Troubleshooting Failed Builds

```bash
# View failed run logs
gh run view FAILED_RUN_ID --log

# Re-run failed jobs only
gh run rerun FAILED_RUN_ID --failed

# Re-run entire workflow
gh run rerun FAILED_RUN_ID
```

---

## 🚀 Quick Reference

| Action | Command |
|--------|---------|
| Trigger build | `gh workflow run build-apk.yml` |
| Watch build | `gh run watch` |
| List runs | `gh run list --workflow=build-apk.yml` |
| Download artifacts | `gh run download` |
| Create release | `git tag -a v1.0.0 -m "Release" && git push origin v1.0.0` |
| Cancel run | `gh run cancel <run-id>` |
| Re-run failed | `gh run rerun <run-id> --failed` |

---

**Pro Tips:**
- Gunakan `gh alias set` untuk create shortcuts
- Setup GitHub CLI autocomplete: `gh completion -s bash > /etc/bash_completion.d/gh`
- Monitor via mobile: Install GitHub mobile app

---

*Last updated: 2026-08-25*
