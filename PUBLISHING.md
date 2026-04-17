# Publishing Guide for baresip_flutter

## ✅ Pre-Publication Checklist

The package is ready for publication! Here's what has been prepared:

### Required Files ✅
- [x] `pubspec.yaml` - Package metadata and dependencies
- [x] `README.md` - Comprehensive documentation (20 KB)
- [x] `CHANGELOG.md` - Version history
- [x] `LICENSE` - MIT License
- [x] `.pubignore` - Excludes AAR files and build artifacts
- [x] `lib/` - Plugin source code
- [x] `example/` - Working example app

### Package Validation ✅
- Package size: **135 KB** (AAR files excluded)
- No blocking errors
- 2 warnings (non-blocking):
  1. Modified files in git (normal during development)
  2. Missing repository URL (add before publishing)

---

## 📋 Steps to Publish

### 1. Set Up Repository (Required)

Create a GitHub repository and update `pubspec.yaml`:

```yaml
homepage: https://github.com/nishantsoftvan-a11y/baresip-flutter-plugin
repository: https://github.com/nishantsoftvan-a11y/baresip-flutter-plugin
issue_tracker: https://github.com/nishantsoftvan-a11y/baresip-flutter-plugin/issues

```

### 2. Commit All Changes

```bash
cd baresip_flutter
git add .
git commit -m "Prepare v0.1.0 for publication"
git tag v0.1.0
git push origin main --tags
```

### 3. Verify Package

Run a final dry-run to ensure everything is correct:

```bash
flutter pub publish --dry-run
```

Expected output:
- ✅ Package size: ~135 KB
- ✅ No errors
- ⚠️ Warnings about repository URL (should be fixed after step 1)

### 4. Publish to pub.dev

**Important:** You need a verified pub.dev account.

```bash
flutter pub publish
```

You'll be prompted to:
1. Confirm the package details
2. Authenticate with your Google account
3. Verify your email (first-time publishers)

### 5. Post-Publication

After successful publication:

1. **Verify on pub.dev:**
   - Visit https://pub.dev/packages/baresip_flutter
   - Check that README renders correctly
   - Verify example code is visible

2. **Update README in your app:**
   ```yaml
   dependencies:
     baresip_flutter: ^0.1.0
   ```

3. **Announce:**
   - Share on Flutter community forums
   - Tweet about it
   - Add to your portfolio

---

## 📦 What Gets Published

The `.pubignore` file excludes:
- ✅ AAR files (users build their own)
- ✅ Build artifacts
- ✅ IDE files
- ✅ Git metadata

**Included in package:**
- ✅ Dart source code (`lib/`)
- ✅ Android plugin code (`android/src/`)
- ✅ Example app (`example/`)
- ✅ Documentation (README, CHANGELOG, LICENSE)
- ✅ Build configuration (`android/build.gradle.kts`)

---

## 🔄 Publishing Updates

### Patch Release (0.1.1)

For bug fixes:

```bash
# Update version in pubspec.yaml
version: 0.1.1

# Update CHANGELOG.md
## 0.1.1
- Fixed: [describe bug fix]

# Commit and publish
git commit -am "Release v0.1.1"
git tag v0.1.1
git push origin main --tags
flutter pub publish
```

### Minor Release (0.2.0)

For new features:

```bash
# Update version
version: 0.2.0

# Update CHANGELOG.md
## 0.2.0
- Added: [new feature]
- Improved: [enhancement]

# Publish
git commit -am "Release v0.2.0"
git tag v0.2.0
git push origin main --tags
flutter pub publish
```

### Major Release (1.0.0)

For breaking changes:

```bash
# Update version
version: 1.0.0

# Update CHANGELOG.md
## 1.0.0
**Breaking Changes:**
- Changed: [breaking change]
- Removed: [deprecated feature]

**Migration Guide:**
[Instructions for upgrading]

# Publish
git commit -am "Release v1.0.0"
git tag v1.0.0
git push origin main --tags
flutter pub publish
```

---

## 🚨 Common Issues

### "Package validation failed"

**Cause:** Missing required files or invalid pubspec.yaml

**Fix:**
```bash
# Check what's missing
flutter pub publish --dry-run

# Ensure all required files exist
ls -la README.md CHANGELOG.md LICENSE pubspec.yaml
```

### "Package size too large"

**Cause:** AAR files or build artifacts included

**Fix:**
```bash
# Verify .pubignore is working
flutter pub publish --dry-run | grep "Total compressed"

# Should show ~135 KB, not 29 MB
```

### "Authentication failed"

**Cause:** Not logged in to pub.dev

**Fix:**
```bash
# Login to pub.dev
flutter pub login

# Follow the authentication flow
```

### "Version already exists"

**Cause:** Trying to republish the same version

**Fix:**
```bash
# Increment version in pubspec.yaml
version: 0.1.1  # or 0.2.0, 1.0.0

# Update CHANGELOG.md
# Then publish again
```

---

## 📊 Package Score

After publication, pub.dev will score your package on:

1. **Popularity** (0-100)
   - Downloads
   - Likes
   - Usage in other packages

2. **Pub Points** (0-130)
   - Documentation quality: ✅ (comprehensive README)
   - Platform support: ✅ (Android)
   - Null safety: ✅ (Dart 3.3+)
   - Dependencies: ✅ (minimal, up-to-date)
   - Example: ✅ (working example app)

3. **Likes**
   - User engagement
   - Community feedback

**Expected initial score:** 100+ pub points

---

## 🎯 Maintenance Checklist

### Weekly
- [ ] Monitor issue tracker
- [ ] Respond to questions
- [ ] Review pull requests

### Monthly
- [ ] Update dependencies
- [ ] Check for Flutter SDK updates
- [ ] Review and close stale issues

### Quarterly
- [ ] Test with latest Flutter stable
- [ ] Update documentation
- [ ] Plan new features

---

## 📞 Support

After publication, users can:
- Report issues: GitHub issue tracker
- Ask questions: pub.dev package page
- Contribute: Pull requests welcome

---

## ✅ Ready to Publish!

Your package is **publication-ready**. Just:
1. Create GitHub repository
2. Update repository URLs in pubspec.yaml
3. Commit changes
4. Run `flutter pub publish`

Good luck! 🚀
