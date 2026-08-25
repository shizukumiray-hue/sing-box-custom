# GitHub Actions Workflows untuk sing-box Android

Direktori ini berisi GitHub Actions workflows untuk automated build sing-box Android APK.

## 📁 Struktur Files

```
.github/workflows/
├── build-apk.yml       # Main workflow: Build libbox.aar + Android APK
├── build-libbox.yml    # Reusable workflow: Build libbox.aar only
├── build.yml           # Existing: Multi-platform sing-box build
├── docker.yml          # Existing: Docker image build
└── linux.yml           # Existing: Linux build
```

## 🚀 Workflows Baru

### 1. `build-apk.yml` - Full Android APK Build

**Purpose:** Build complete Android APK dengan custom sing-box core

**Triggers:**
- Push ke branch: `main`, `dev`, `feature/*`
- Push tag: `v*` (auto-create release)
- Pull request ke `main`
- Manual dispatch (via Actions UI)

**Jobs:**
1. **build-libbox** - Build libbox.aar dari sing-box core
2. **build-apk** - Build Android APK (matrix: other/play/otherLegacy)
3. **create-release** - Create GitHub release (untuk tags)
4. **notify-completion** - Build summary

**Outputs:**
- Multi-architecture APK files (arm64-v8a, armeabi-v7a, x86_64, x86, universal)
- Build artifacts (retention: 30 days)
- GitHub releases (untuk version tags)

### 2. `build-libbox.yml` - Libbox Only Build

**Purpose:** Build libbox.aar saja untuk testing/development

**Triggers:**
- Manual dispatch
- Workflow call (dapat dipanggil dari workflow lain)

**Outputs:**
- libbox.aar file
- Build metadata JSON
- Artifact retention: 14 days

## 📖 Dokumentasi

Untuk panduan lengkap, lihat:
- **[README-BUILD.md](../README-BUILD.md)** - Complete documentation
- **[workflow-commands.sh](../workflow-commands.sh)** - Quick reference commands

## 🎯 Quick Start

### Via GitHub Web Interface

1. Go to **Actions** tab di repository
2. Pilih workflow "Build sing-box Android APK"
3. Click **Run workflow**
4. Pilih options dan click **Run**

### Via GitHub CLI

```bash
# Install gh CLI
sudo apt install gh  # atau: brew install gh

# Login
gh auth login

# Trigger build
gh workflow run build-apk.yml \
  --field build_type=other \
  --field create_release=false

# Monitor build
gh run watch

# Download artifacts
gh run download
```

### Via Git Tags (Recommended untuk Release)

```bash
# Create and push tag
git tag -a v1.14.0 -m "Release v1.14.0"
git push origin v1.14.0

# Workflow akan otomatis:
# 1. Build APK
# 2. Create GitHub Release
# 3. Upload APK ke release
```

## 🔧 Configuration

### Environment Variables

Defined di workflow files:

```yaml
env:
  GO_VERSION: '1.24.7'          # Go version untuk build libbox
  NDK_VERSION: '28.0.13004108'  # Android NDK version
  JAVA_VERSION: '17'            # Java version untuk Gradle
```

### Build Matrix

```yaml
matrix:
  build_type: [other, play, otherLegacy]
  # other: Min API 24 (Android 7.0+)
  # play: Min API 24 + Play Store features
  # otherLegacy: Min API 21 (Android 5.0+)
```

### Architecture Support

- ✅ arm64-v8a (64-bit ARM)
- ✅ armeabi-v7a (32-bit ARM)
- ✅ x86_64 (64-bit x86)
- ✅ x86 (32-bit x86)
- ✅ universal (all architectures)

## 📦 Artifacts

### Build Artifacts (GitHub Actions)

Setelah build selesai, download dari Actions tab:

```
artifacts/
├── libbox-aar/
│   └── libbox.aar
├── apk-other-{hash}/
│   ├── SFA-{version}-other-arm64-v8a-{hash}.apk
│   ├── SFA-{version}-other-armeabi-v7a-{hash}.apk
│   ├── SFA-{version}-other-x86_64-{hash}.apk
│   ├── SFA-{version}-other-x86-{hash}.apk
│   └── SFA-{version}-other-universal-{hash}.apk
└── build-info-other/
    └── build-info.txt
```

### Release Assets (GitHub Releases)

Untuk version tags, APK akan otomatis di-upload ke GitHub Releases.

## 🔍 Monitoring

### View Build Status

**Via GitHub Web:**
- Go to Actions tab
- Click pada workflow run
- View logs dan status

**Via GitHub CLI:**
```bash
# List recent runs
gh run list --workflow=build-apk.yml --limit 10

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log

# Watch real-time
gh run watch
```

### Build Summary

Setiap build menghasilkan summary dengan informasi:
- Version & commit hash
- Build status (success/failed)
- Available architectures
- Download links

## 🐛 Troubleshooting

### Common Issues

**1. Build Failed - Go Dependencies**
```bash
# Check go.mod validity
go mod verify

# Re-run workflow
gh run rerun <run-id>
```

**2. NDK Not Found**
```yaml
# Workflow sudah auto-install NDK
# Jika error, cek version match di workflow file
```

**3. Gradle Build Failed**
```bash
# Check artifact upload/download success
# Verify libbox.aar exists in build-apk job
```

**4. Out of Memory**
```yaml
# Workflow sudah include --no-daemon flag
# Jika masih error, contact maintainer
```

### Re-run Failed Jobs

```bash
# Re-run entire workflow
gh run rerun <run-id>

# Re-run only failed jobs
gh run rerun <run-id> --failed
```

### Cancel Running Workflow

```bash
gh run cancel <run-id>
```

## 🔐 Security

### Secrets (Optional, untuk Production)

Untuk production builds dengan signing:

1. Settings → Secrets → Actions
2. Add secrets:
   - `KEYSTORE_BASE64` - Base64 encoded keystore
   - `KEYSTORE_PASSWORD` - Keystore password
   - `KEY_ALIAS` - Key alias
   - `KEY_PASSWORD` - Key password

### Permissions

Workflows memerlukan:
- `contents: write` - Untuk create releases
- `actions: read` - Untuk download artifacts

## 📊 Performance

### Typical Build Times

| Job | Duration | Notes |
|-----|----------|-------|
| build-libbox | 2-8 min | Depends on cache |
| build-apk | 8-12 min | Per flavor |
| Total | 15-20 min | Complete workflow |

### Caching

Workflows menggunakan multiple caches:
- Go modules cache
- Gradle dependencies cache
- Android SDK cache

## 🤝 Contributing

Untuk modify workflows:

1. Edit workflow files di `.github/workflows/`
2. Test locally jika possible
3. Push dan monitor di Actions tab
4. Update documentation jika perlu

## 📚 References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Android Build Documentation](https://developer.android.com/studio/build)
- [sing-box Documentation](https://sing-box.sagernet.org/)

## 📝 Notes

- Workflows compatible dengan existing workflows (`build.yml`, `docker.yml`, dll)
- Tidak mengganggu existing CI/CD pipeline
- Dapat di-disable kapan saja via Settings → Actions

## 🆘 Support

Issues atau questions:
- Open GitHub Issue
- Check [README-BUILD.md](../README-BUILD.md) untuk detailed guide
- Run `./workflow-commands.sh` untuk quick reference

---

*Last updated: 2026-08-25*
