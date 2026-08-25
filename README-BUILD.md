# 🚀 Panduan Build sing-box Android APK dengan GitHub Actions

## 📋 Daftar Isi

1. [Fitur Workflow](#fitur-workflow)
2. [Prerequisites](#prerequisites)
3. [Setup Repository](#setup-repository)
4. [Cara Menggunakan](#cara-menggunakan)
5. [Struktur Workflow](#struktur-workflow)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Usage](#advanced-usage)

---

## ✨ Fitur Workflow

### `build-apk.yml` - Full Build Workflow

✅ **Automated Build Process**
- Build libbox.aar dari sing-box core
- Build APK untuk multiple architectures
- Support multi-flavor (other, play, otherLegacy)
- Automated versioning dengan git tags

✅ **Multiple Triggers**
- Push ke branch (main, dev, feature/*)
- Push tag (v*)
- Pull request
- Manual trigger (workflow_dispatch)

✅ **Multi-Architecture Support**
- arm64-v8a (64-bit ARM - device modern)
- armeabi-v7a (32-bit ARM)
- x86_64 (emulator/tablet x86 64-bit)
- x86 (emulator/tablet x86 32-bit)
- universal (semua architecture)

✅ **Auto Release**
- Create GitHub release otomatis untuk git tags
- Upload semua APK variants
- Include build information

✅ **Caching**
- Go modules cache
- Gradle dependencies cache
- Speed up subsequent builds

### `build-libbox.yml` - Reusable Libbox Builder

- Build libbox.aar only
- Reusable workflow untuk testing
- Dapat dipanggil dari workflow lain

---

## 📦 Prerequisites

### 1. Repository Requirements

Anda memerlukan 2 repositories:

1. **sing-box core** (repo ini)
   - Fork dari https://github.com/sagernet/sing-box
   - Dengan custom modifications (SSH WebSocket payload)

2. **sing-box-for-android**
   - Fork dari https://github.com/sagernet/sing-box-for-android
   - Atau gunakan repository: `reF1nd/sing-box-for-android`

### 2. GitHub Actions Enabled

Pastikan GitHub Actions enabled di repository settings:
- Settings → Actions → General → Allow all actions

### 3. Permissions

Workflow memerlukan permissions:
- `contents: write` (untuk create releases)
- `actions: read` (untuk download artifacts)

---

## 🔧 Setup Repository

### Step 1: Copy Workflow Files

Workflow sudah dibuat di:
```
sing-box/.github/workflows/
├── build-apk.yml          # Main build workflow
└── build-libbox.yml       # Libbox only workflow
```

### Step 2: Commit & Push

```bash
cd /home/daisy/mayumi/Experimen/golang/github/sing-box

# Add workflows
git add .github/workflows/

# Commit
git commit -m "ci: add GitHub Actions workflow for Android APK build"

# Push ke GitHub
git push origin main
```

### Step 3: Verify Workflow

1. Buka repository di GitHub
2. Go to **Actions** tab
3. Anda akan melihat workflow: "Build sing-box Android APK"

---

## 🎯 Cara Menggunakan

### Method 1: Push ke Branch (Automated)

Setiap kali push ke branch `main`, `dev`, atau `feature/*`:

```bash
# Make changes
git add .
git commit -m "feat: add new feature"
git push origin main
```

Workflow akan otomatis triggered dan build APK.

### Method 2: Create Release Tag (Recommended)

Untuk membuat official release:

```bash
# Tag dengan version
git tag -a v1.14.0 -m "Release v1.14.0 - Custom SSH WebSocket"

# Push tag
git push origin v1.14.0
```

Workflow akan:
- Build APK
- Create GitHub Release
- Upload APK ke release

### Method 3: Manual Trigger

Via GitHub Web Interface:

1. Go to **Actions** tab
2. Select workflow "Build sing-box Android APK"
3. Click **Run workflow**
4. Pilih options:
   - **Branch**: pilih branch yang akan dibuild
   - **Build type**: other / play / otherLegacy
   - **Create release**: centang jika ingin create release

### Method 4: Build Libbox Only

Untuk testing atau development:

1. Go to **Actions** tab
2. Select workflow "Build libbox.aar Only"
3. Click **Run workflow**
4. Pilih Go version (optional)

---

## 🏗️ Struktur Workflow

### Workflow: `build-apk.yml`

```yaml
Jobs:
  1. build-libbox         # Build libbox.aar dari sing-box core
     ├─ Setup Go
     ├─ Install Gomobile
     ├─ Build libbox.aar
     └─ Upload artifact
  
  2. build-apk            # Build Android APK
     ├─ Download libbox.aar
     ├─ Setup Java & NDK
     ├─ Build APK (matrix: other/play/otherLegacy)
     └─ Upload APK artifacts
  
  3. create-release       # Create GitHub Release (optional)
     ├─ Download all artifacts
     ├─ Create release
     └─ Upload APK to release
  
  4. notify-completion    # Build summary
     └─ Generate summary
```

### Build Matrix

| Build Type | Min API | Target Devices | Flavor |
|------------|---------|----------------|--------|
| `other` | 24 (Android 7.0) | Modern devices | Other |
| `play` | 24 (Android 7.0) | Google Play | Play |
| `otherLegacy` | 21 (Android 5.0) | Legacy devices | OtherLegacy |

---

## 📥 Download APK

### From GitHub Actions Artifacts

1. Go to **Actions** tab
2. Click pada workflow run yang sudah selesai
3. Scroll ke bagian **Artifacts**
4. Download: `apk-other-{commit_hash}.zip`
5. Extract dan install APK

### From GitHub Releases

1. Go to **Releases** page
2. Pilih release version
3. Download APK sesuai device architecture:
   - **arm64-v8a** → Untuk kebanyakan smartphone modern
   - **armeabi-v7a** → Untuk device 32-bit
   - **universal** → Support semua architecture (file besar)

---

## 🔍 Monitoring Build

### View Build Progress

1. Go to **Actions** tab
2. Click pada running workflow
3. Expand job untuk melihat logs real-time

### Build Summary

Setelah build selesai, akan muncul summary:

```
🚀 sing-box Android Build Summary

Build Information
- Version: v1.14.0
- Commit: abc123f
- Build Date: 2026-08-25T09:00:00Z

Build Status
- Build libbox: ✅ Success
- Build APK: ✅ Success

Artifacts
- ✅ arm64-v8a
- ✅ armeabi-v7a
- ✅ x86_64
- ✅ x86
- ✅ universal
```

---

## 🐛 Troubleshooting

### Issue 1: Build Failed - Go Dependencies

**Error:**
```
go: downloading failed
```

**Solution:**
```yaml
# Workflow sudah include retry mechanism
# Cek di go.mod apakah dependencies valid
# Atau run manual:
go mod download
go mod verify
```

### Issue 2: Gradle Build Failed

**Error:**
```
Could not find libbox.aar
```

**Solution:**
- Pastikan job `build-libbox` success
- Check artifact upload/download
- Verify `app/libs/libbox.aar` exists

### Issue 3: NDK Not Found

**Error:**
```
NDK not configured
```

**Solution:**
Workflow sudah setup NDK otomatis, tapi pastikan version match:
```yaml
NDK_VERSION: '28.0.13004108'
```

### Issue 4: Out of Memory

**Error:**
```
java.lang.OutOfMemoryError
```

**Solution:**
Workflow sudah include `--no-daemon` flag. Jika masih error, modify:
```yaml
# Add gradle properties
run: |
  echo "org.gradle.jvmargs=-Xmx4096m" >> gradle.properties
  ./gradlew assemble...
```

### Issue 5: Artifact Not Found

**Error:**
```
Unable to download artifact
```

**Solution:**
- Check artifact retention (default: 30 days)
- Verify artifact name match
- Re-run workflow

---

## 🚀 Advanced Usage

### Custom Go Version

Edit workflow file:

```yaml
env:
  GO_VERSION: '1.24.7'  # Change this
```

### Custom NDK Version

```yaml
env:
  NDK_VERSION: '28.0.13004108'  # Change this
```

### Build Specific Architecture Only

Modify matrix in workflow:

```yaml
strategy:
  matrix:
    include:
      - build_type: other
        # Remove architectures you don't need
```

### Add Custom Build Steps

Add step sebelum build:

```yaml
- name: Custom preprocessing
  run: |
    # Your custom commands
    echo "Custom build step"
```

### Modify APK Signing

Untuk production builds, tambahkan signing config:

```yaml
- name: Setup keystore
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > app/release.keystore
    
- name: Create local.properties
  run: |
    cat > local.properties << EOF
    KEYSTORE_PASS=${{ secrets.KEYSTORE_PASSWORD }}
    ALIAS_NAME=${{ secrets.KEY_ALIAS }}
    ALIAS_PASS=${{ secrets.KEY_PASSWORD }}
    EOF
```

**Setup secrets:**
1. Settings → Secrets → Actions
2. Add secrets:
   - `KEYSTORE_BASE64` (base64 encoded keystore)
   - `KEYSTORE_PASSWORD`
   - `KEY_ALIAS`
   - `KEY_PASSWORD`

### Auto Deploy to Play Store

Tambahkan job untuk upload ke Play Store:

```yaml
deploy-play:
  needs: build-apk
  runs-on: ubuntu-latest
  steps:
    - name: Upload to Play Store
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.SERVICE_ACCOUNT_JSON }}
        packageName: io.nekohasekai.sfa
        releaseFiles: apk-output/*.apk
        track: beta
```

---

## 📊 Build Performance

### Typical Build Times

| Job | Duration | Notes |
|-----|----------|-------|
| build-libbox | 5-8 min | First run without cache |
| build-libbox | 2-3 min | With cache |
| build-apk | 8-12 min | Per flavor |
| Total | 15-20 min | Complete workflow |

### Cache Strategy

Workflow menggunakan 3 level caching:

1. **Go modules cache** (build-libbox)
   ```yaml
   key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
   ```

2. **Gradle cache** (build-apk)
   ```yaml
   key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*') }}
   ```

3. **Artifact cache** (between jobs)
   ```yaml
   retention-days: 30
   ```

---

## 📝 Example Commands

### Check Workflow Status (via CLI)

Install GitHub CLI:
```bash
# Install gh
sudo apt install gh

# Login
gh auth login

# List workflows
gh workflow list

# View runs
gh run list --workflow=build-apk.yml

# View specific run
gh run view <run-id>

# Download artifacts
gh run download <run-id>
```

### Trigger Build via API

```bash
# Trigger workflow
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/sing-box/actions/workflows/build-apk.yml/dispatches \
  -d '{"ref":"main","inputs":{"build_type":"other","create_release":"false"}}'
```

### Install APK via ADB

```bash
# Download APK dari artifacts
unzip apk-other-*.zip

# Install ke device
adb install SFA-*-arm64-v8a-*.apk

# Atau install dan replace
adb install -r SFA-*-arm64-v8a-*.apk
```

---

## 🔐 Security Best Practices

### 1. Secret Management

❌ **JANGAN** commit credentials:
- Keystore files
- API keys
- Service account JSON

✅ **GUNAKAN** GitHub Secrets:
```yaml
${{ secrets.YOUR_SECRET }}
```

### 2. Branch Protection

Protect main branch:
- Settings → Branches → Add rule
- Require pull request reviews
- Require status checks (workflow success)

### 3. Artifact Security

- Set reasonable retention days
- Delete old artifacts
- Use private repositories untuk production builds

---

## 📚 References

### Official Documentation

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Android Build Guide](https://developer.android.com/studio/build)
- [sing-box Documentation](https://sing-box.sagernet.org/)

### Related Workflows

- Existing `build.yml` - Multi-platform build
- Existing `docker.yml` - Docker image build

### Support

- GitHub Issues: https://github.com/YOUR_USERNAME/sing-box/issues
- sing-box Telegram: https://t.me/sagernet

---

## 🎉 Success!

Jika workflow berjalan sukses, Anda akan mendapatkan:

✅ Multi-architecture APK files  
✅ Build artifacts di GitHub Actions  
✅ Automated GitHub releases  
✅ Build info & metadata  
✅ Professional CI/CD pipeline  

**Happy Building! 🚀**

---

*Last updated: 2026-08-25*  
*Workflow version: 1.0.0*
