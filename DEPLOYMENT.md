# 🚀 Deployment Guide - GitHub Actions Workflow

Panduan step-by-step untuk deploy GitHub Actions workflow ke repository.

## 📋 Pre-deployment Checklist

### ✅ Files yang Sudah Dibuat

```
sing-box/
├── .github/workflows/
│   ├── build-apk.yml          ✅ Main APK build workflow
│   ├── build-libbox.yml       ✅ Libbox-only workflow
│   └── README.md              ✅ Workflows documentation
│
├── README-BUILD.md             ✅ Complete build guide
├── WORKFLOW-TRIGGERS.md        ✅ Trigger examples
├── workflow-commands.sh        ✅ Quick reference script
└── validate-workflows.sh       ✅ Validation script
```

### ✅ Workflow Features

- Multi-architecture APK build (arm64-v8a, armeabi-v7a, x86_64, x86, universal)
- Auto-release untuk git tags
- Caching untuk Go modules dan Gradle
- Build artifacts dengan 30 days retention
- Build summary dan metadata

---

## 🔧 Step 1: Verify Repository Setup

### Check GitHub Repository

```bash
cd /home/daisy/mayumi/Experimen/golang/github/sing-box

# Verify git remote
git remote -v

# Should show:
# origin  https://github.com/YOUR_USERNAME/sing-box.git
```

### Check Branch

```bash
# Check current branch
git branch

# Ensure you're on main or appropriate branch
git checkout main
```

---

## 📤 Step 2: Commit & Push Workflows

### Stage Files

```bash
cd /home/daisy/mayumi/Experimen/golang/github/sing-box

# Add workflow files
git add .github/workflows/build-apk.yml
git add .github/workflows/build-libbox.yml
git add .github/workflows/README.md

# Add documentation
git add README-BUILD.md
git add WORKFLOW-TRIGGERS.md
git add IMPLEMENTATION-SUMMARY.md
git add workflow-commands.sh
git add validate-workflows.sh

# Check status
git status
```

### Commit

```bash
# Commit dengan descriptive message
git commit -m "ci: add GitHub Actions workflow for Android APK build

- Add build-apk.yml: Full APK build with multi-architecture support
- Add build-libbox.yml: Reusable libbox-only build workflow
- Add comprehensive documentation (README-BUILD.md, WORKFLOW-TRIGGERS.md)
- Add helper scripts (workflow-commands.sh, validate-workflows.sh)
- Support auto-release for version tags
- Include build caching for performance

Features:
- Multi-architecture: arm64-v8a, armeabi-v7a, x86_64, x86, universal
- Multi-flavor: other, play, otherLegacy
- Auto GitHub Release creation for tags
- Artifact retention: 30 days
- Build time: ~15-20 minutes (with cache: ~10-15 min)"
```

### Push

```bash
# Push ke GitHub
git push origin main

# Jika ada error, bisa force push (hati-hati!)
# git push origin main --force
```

---

## ⚙️ Step 3: Enable GitHub Actions

### Via GitHub Web Interface

1. **Go to Repository**
   ```
   https://github.com/YOUR_USERNAME/sing-box
   ```

2. **Enable Actions** (jika belum)
   - Settings → Actions → General
   - Under "Actions permissions":
     - ✅ Select "Allow all actions and reusable workflows"
   - Click **Save**

3. **Set Workflow Permissions**
   - Settings → Actions → General
   - Scroll to "Workflow permissions"
   - ✅ Select "Read and write permissions"
   - ✅ Check "Allow GitHub Actions to create and approve pull requests"
   - Click **Save**

---

## 🧪 Step 4: First Test Run

### Method 1: Via GitHub Web Interface

1. **Go to Actions Tab**
   ```
   https://github.com/YOUR_USERNAME/sing-box/actions
   ```

2. **Select Workflow**
   - Click "Build sing-box Android APK" dari list kiri

3. **Run Workflow**
   - Click tombol **"Run workflow"** (kanan atas)
   - Select branch: `main`
   - Build type: `other`
   - Create release: unchecked
   - Click **"Run workflow"**

4. **Monitor Progress**
   - Workflow akan muncul di list
   - Click untuk melihat details
   - Monitor setiap job:
     - build-libbox (~5-8 min)
     - build-apk (~10-15 min)
     - notify-completion

### Method 2: Via GitHub CLI

```bash
# Install gh CLI (jika belum)
# Ubuntu: sudo apt install gh
# macOS: brew install gh

# Login
gh auth login

# Trigger workflow
gh workflow run build-apk.yml \
  --field build_type=other \
  --field create_release=false

# Watch progress
gh run watch

# Or list recent runs
gh run list --workflow=build-apk.yml
```

---

## 📥 Step 5: Download & Test APK

### Download dari GitHub Actions

#### Via Web Interface

1. Go to Actions tab
2. Click pada completed workflow run
3. Scroll ke "Artifacts" section
4. Download: `apk-other-{hash}.zip`
5. Extract zip file

#### Via GitHub CLI

```bash
# Download artifacts dari latest run
gh run download

# Atau dari specific run
gh run download <run-id>

# List untuk check
ls -lh apk-other-*/
```

### Install APK ke Device

```bash
# Connect device via USB dan enable USB debugging

# Check device connected
adb devices

# Install APK (arm64-v8a untuk most modern devices)
adb install apk-other-*/SFA-*-arm64-v8a-*.apk

# Atau install dengan replace existing
adb install -r apk-other-*/SFA-*-arm64-v8a-*.apk

# Check installation
adb shell pm list packages | grep sfa
```

---

## 🏷️ Step 6: Create First Release

### Update Version (Optional)

Jika ingin custom version:

```bash
cd /home/daisy/mayumi/Experimen/golang/github/sing-box-for-android

# Edit version.properties
vim version.properties

# Set version
VERSION_CODE=724
VERSION_NAME=1.14.0

# Commit
git add version.properties
git commit -m "chore: bump version to 1.14.0"
git push
```

### Create Release Tag

```bash
cd /home/daisy/mayumi/Experimen/golang/github/sing-box

# Create annotated tag
git tag -a v1.14.0 -m "Release v1.14.0 - sing-box Android with custom SSH WebSocket

Features:
- Custom SSH WebSocket payload support
- Multi-architecture builds
- Optimized for Android 7.0+

Built with GitHub Actions"

# Push tag to trigger release workflow
git push origin v1.14.0
```

### Verify Release

1. **Check Actions Tab**
   - Workflow akan otomatis triggered
   - Monitor progress

2. **Check Releases Page**
   ```
   https://github.com/YOUR_USERNAME/sing-box/releases
   ```
   - Release akan otomatis created
   - APK files akan ter-upload
   - Build info included

---

## 🔍 Step 7: Verify Workflow Success

### Check Build Logs

```bash
# List recent runs
gh run list --workflow=build-apk.yml --limit 5

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log
```

### Check Artifacts

```bash
# List artifacts
gh run view <run-id>

# Should show:
# - libbox-aar
# - apk-other-{hash}
# - build-info-other
```

### Check GitHub Release (untuk tags)

```bash
# List releases
gh release list

# View specific release
gh release view v1.14.0

# Should show APK files attached
```

---

## 🎯 Step 8: Setup for Team (Optional)

### Add Branch Protection

1. Settings → Branches
2. Add rule untuk `main` branch
3. Enable:
   - ✅ Require pull request reviews
   - ✅ Require status checks to pass
   - ✅ Select: "Build sing-box Android APK"

### Setup Secrets (untuk Production Signing)

Jika ingin APK signed untuk production:

```bash
# 1. Convert keystore to base64
base64 -i release.keystore > keystore.txt

# 2. Add secrets di GitHub
# Settings → Secrets and variables → Actions → New repository secret
```

Add secrets:
- `KEYSTORE_BASE64` - Content dari keystore.txt
- `KEYSTORE_PASSWORD` - Password keystore
- `KEY_ALIAS` - Alias key
- `KEY_PASSWORD` - Password key

### Setup Notifications (Optional)

Di workflow file, tambahkan notification step:

```yaml
- name: Send notification
  if: always()
  run: |
    # Slack, Discord, Telegram, dll
    curl -X POST ${{ secrets.WEBHOOK_URL }} \
      -d "Build ${{ job.status }}: ${{ github.run_id }}"
```

---

## 📊 Expected Build Times

### First Run (No Cache)

| Job | Duration |
|-----|----------|
| build-libbox | 5-8 minutes |
| build-apk | 10-15 minutes |
| **Total** | **15-23 minutes** |

### Subsequent Runs (With Cache)

| Job | Duration |
|-----|----------|
| build-libbox | 2-3 minutes |
| build-apk | 8-12 minutes |
| **Total** | **10-15 minutes** |

---

## 🐛 Troubleshooting

### Issue: Workflow Not Showing

**Symptom:** Workflow tidak muncul di Actions tab

**Solution:**
1. Verify file di `.github/workflows/` ter-push
2. Check YAML syntax valid
3. Refresh browser
4. Check Actions enabled di Settings

### Issue: Build Failed - Permission Denied

**Symptom:** Error "Permission denied" saat build

**Solution:**
1. Go to Settings → Actions → General
2. Set "Workflow permissions" ke "Read and write"
3. Re-run workflow

### Issue: libbox.aar Not Found

**Symptom:** build-apk job error "libbox.aar not found"

**Solution:**
1. Check build-libbox job completed successfully
2. Verify artifact uploaded
3. Check artifact download step in build-apk job
4. Re-run workflow

### Issue: NDK Not Found

**Symptom:** Error "NDK not configured"

**Solution:**
- Workflow should auto-install NDK
- Jika error persist, check NDK version di workflow match dengan app/build.gradle.kts
- Current version: 28.0.13004108

### Issue: Out of Memory

**Symptom:** Gradle build error "OutOfMemoryError"

**Solution:**
- Workflow sudah include `--no-daemon` flag
- Jika masih error, bisa tambahkan di workflow:
  ```yaml
  echo "org.gradle.jvmargs=-Xmx4096m" >> gradle.properties
  ```

---

## ✅ Success Indicators

After successful deployment:

✅ Workflow muncul di Actions tab  
✅ Manual trigger works  
✅ Build completes successfully  
✅ Artifacts generated (libbox.aar + APKs)  
✅ APK installable di Android device  
✅ Git tags trigger auto-release  
✅ GitHub Releases created dengan APK attached  

---

## 🎉 Deployment Complete!

Setelah semua steps selesai, you now have:

1. ✅ Automated APK build on every push
2. ✅ Multi-architecture support
3. ✅ GitHub Releases untuk version tags
4. ✅ Professional CI/CD pipeline
5. ✅ Build caching untuk performance
6. ✅ Production-ready workflows

---

## 📚 Next Steps

### Daily Usage

```bash
# 1. Make changes
vim some-file.go

# 2. Commit & push
git add .
git commit -m "feat: new feature"
git push origin main

# 3. Workflow runs automatically
# 4. Download APK dari Artifacts
gh run download
```

### Release Process

```bash
# 1. Update version (if needed)
# 2. Commit changes
# 3. Create tag
git tag -a v1.x.x -m "Release v1.x.x"
git push origin v1.x.x

# 4. GitHub Release created automatically
# 5. Share release link with users
```

### Monitoring

```bash
# Check recent builds
gh run list --workflow=build-apk.yml

# Watch current build
gh run watch

# View logs
gh run view --log
```

---

## 📞 Support

### Resources

- **Complete Guide:** README-BUILD.md
- **Trigger Examples:** WORKFLOW-TRIGGERS.md  
- **Quick Commands:** ./workflow-commands.sh
- **Validation:** ./validate-workflows.sh

### Get Help

- Check workflow logs di Actions tab
- Review documentation files
- Open GitHub Issue jika ada problem
- Check existing workflow runs untuk reference

---

## 📝 Deployment Checklist

Copy checklist ini untuk tracking:

```
Pre-deployment:
[ ] Workflows files created
[ ] Documentation written
[ ] Scripts executable
[ ] Git status clean

Deployment:
[ ] Files committed
[ ] Pushed to GitHub
[ ] Actions enabled
[ ] Permissions configured

Testing:
[ ] Manual trigger test passed
[ ] Build completed successfully
[ ] Artifacts downloaded
[ ] APK installed and tested

Release:
[ ] Version updated
[ ] Tag created and pushed
[ ] GitHub Release created
[ ] APK files attached

Post-deployment:
[ ] Team notified
[ ] Documentation shared
[ ] Branch protection setup (optional)
[ ] Secrets configured (optional)
```

---

**Status: Ready for Deployment! 🚀**

Last updated: 2026-08-25  
Version: 1.0.0

---

*Good luck with your deployment!*
