You are creating a milestone release (major or minor version bump) that bundles multiple completed features together.

## Your Task

The user wants to create a milestone release: `{0}`

## What is a Milestone Release?

A **milestone release** is:
- A collection of multiple features bundled together
- Typically a minor (x.Y.0) or major (X.0.0) version bump
- Represents a significant product evolution
- Has a theme or focus area
- Planned in advance on the roadmap

**Examples:**
- **V1.0.0** - MVP launch (first public release)
- **V1.1.0** - Authentication & user management
- **V1.2.0** - RAG system integration
- **V2.0.0** - Complete UI redesign (breaking changes)

---

## Steps to Execute

### 1. Validate Milestone

**Ask user:**
```
Milestone release: {name}

What type of release is this?
1. Major (X.0.0) - Breaking changes, major new version
2. Minor (x.Y.0) - New features, backward-compatible
3. Cancel

Choice [1/2/3]:
```

**Get current version:**
```bash
cat package.json | grep '"version"'
```

**Calculate new version:**
- If Major: `1.5.3` → `2.0.0`
- If Minor: `1.5.3` → `1.6.0`

**Confirm with user:**
```
Current version: {current}
New version: {new}

Proceed? [y/N]
```

---

### 2. Find Completed Features for Milestone

**Check for:**
- Features in `docs/features/completed/` since last milestone
- Features tagged with this milestone in their metadata
- Features referenced in ROADMAP.md for this milestone

**Read ROADMAP.md (if exists):**
```bash
cat docs/ROADMAP.md
```

**Find features for this milestone:**
```
Milestone: {name}
Features included:
{List features that are part of this milestone}

Features found:
{Show list}

Are these correct? [y/N]
If not, which features should be included?
```

---

### 3. Create Milestone Documentation

**Create file:** `docs/milestones/MILESTONE-{version}.md`

```markdown
# Milestone Release: {Milestone Name}

> **Version:** {version}
> **Release Date:** {YYYY-MM-DD}
> **Type:** {Major / Minor}
> **Status:** {Planning / In Progress / Released}

---

## Overview

### Vision
{What this milestone achieves - the "why"}

### Theme
{Focus area for this release - e.g., "User Management", "Performance", "AI Integration"}

### Target Audience
{Who benefits from this release}

---

## Features Included

{For each feature:}

### F{XXX}: {Feature Title}
**Status:** ✅ Complete

**Summary:** {Brief description}

**Key Changes:**
- {Change 1}
- {Change 2}
- {Change 3}

**Impact:** {Business/user value}

**Documentation:** `docs/features/completed/F{XXX}-{name}/`

**Version:** {version where feature was completed}

---

{Repeat for all features}

---

## Breaking Changes

{If major version:}

### API Changes
- **Removed:** `GET /api/old-endpoint` - Use `GET /api/new-endpoint` instead
- **Changed:** `POST /api/users` now requires `email` field
- **Renamed:** `User.name` → `User.fullName`

### Database Changes
- **Removed columns:** `users.old_field`
- **Renamed tables:** `legacy_data` → `data`

### Migration Guide
{Step-by-step guide for upgrading}

1. **Update API calls:**
   ```typescript
   // Before
   fetch('/api/old-endpoint')

   // After
   fetch('/api/new-endpoint')
   ```

2. **Update data models:**
   ```typescript
   // Before
   interface User {
     name: string;
   }

   // After
   interface User {
     fullName: string;
   }
   ```

3. **Run migration:**
   ```bash
   pnpm nx run database:migrate:deploy
   ```

{If minor version:}

✅ **No breaking changes** - This release is backward-compatible.

---

## New Capabilities

### For End Users
- {User-facing capability 1}
- {User-facing capability 2}
- {User-facing capability 3}

### For Developers
- {Developer capability 1}
- {Developer capability 2}

### For Operations
- {Ops improvement 1}
- {Ops improvement 2}

---

## Technical Summary

### Architecture Changes
- New modules: {List}
- New services: {List}
- New infrastructure: {List}

### Database Changes
- New tables: {List}
- Modified tables: {List}
- New indexes: {List}

### API Changes
- New endpoints: {Count} ({List major ones})
- Modified endpoints: {Count}
- Removed endpoints: {Count if any}

### Dependencies
- Added: {List new packages}
- Updated: {List updated packages}
- Removed: {List removed packages}

### Performance Improvements
- {Improvement 1}: {Metric}
- {Improvement 2}: {Metric}

---

## Metrics

### Development
- **Features completed:** {N}
- **Total sessions:** {N} (across all features)
- **Total time:** {X hours}
- **Calendar duration:** {X weeks/months}
- **Contributors:** {N}

### Code Changes
- **Commits:** {N}
- **Files changed:** {N}
- **Lines added:** +{N}
- **Lines removed:** -{N}
- **Net change:** ±{N}

### Testing
- **Tests added:** {N}
- **Total tests:** {N}
- **Coverage:** {X}% (was {Y}%)
- **Test types:** {Unit, Integration, E2E}

### Quality
- **Bug fixes:** {N}
- **Security fixes:** {N}
- **Performance fixes:** {N}

---

## Testing & Quality Assurance

### Test Strategy
{How this release was tested}

### Test Results
| Test Suite | Tests | Passing | Failing | Coverage |
|------------|-------|---------|---------|----------|
| Unit | {N} | {N} | 0 | {X}% |
| Integration | {N} | {N} | 0 | {X}% |
| E2E | {N} | {N} | 0 | {X}% |
| **Total** | **{N}** | **{N}** | **0** | **{X}%** |

### Performance Benchmarks
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Page load | {X}s | {Y}s | {+/-Z}s |
| API p95 | {X}ms | {Y}ms | {+/-Z}ms |
| Build time | {X}s | {Y}s | {+/-Z}s |

### Security Audit
- [x] Dependency vulnerabilities checked
- [x] OWASP Top 10 reviewed
- [x] Authentication/authorization tested
- [x] Input validation verified
- [x] Security scan passed

---

## Deployment

### Prerequisites

**Environment Variables:**
{If new vars needed:}
```bash
NEW_VAR_1=value
NEW_VAR_2=value
```

**Database Migrations:**
{If schema changes:}
```bash
pnpm nx run database:migrate:deploy
```

**Infrastructure:**
{If new services/resources needed:}
- {Resource 1}
- {Resource 2}

### Deployment Steps

#### 1. Staging
```bash
# Deploy to staging
git checkout staging
git merge main
git push origin staging

# Verify
{Staging URL}
```

#### 2. Smoke Tests
- [ ] Login works
- [ ] Critical features work
- [ ] No console errors
- [ ] No server errors

#### 3. Production
```bash
# Backup database
{Backup command}

# Deploy to production
git checkout main
git push origin main
git push origin v{version}

# Run migrations
{Migration command}

# Deploy services
{Deployment command}
```

#### 4. Verification
- [ ] Health check passes
- [ ] Smoke tests pass
- [ ] Monitoring shows healthy metrics
- [ ] No error spikes in logs

### Rollback Plan
{How to revert if something goes wrong}

---

## Documentation Updates

### User Documentation
- [x] User guides updated
- [x] Changelog published
- [x] Release notes written
- [x] Migration guides created (if breaking)

### Developer Documentation
- [x] API docs updated
- [x] Architecture docs updated
- [x] README updated
- [x] .env.example updated

### Internal Documentation
- [x] Runbooks updated
- [x] Deployment docs updated
- [x] Monitoring docs updated

---

## Communication Plan

### Internal
**Team notification:**
```
🎉 Milestone {version} Released!

Milestone: {name}
Features: {N} completed
Theme: {theme}

Key achievements:
- {Achievement 1}
- {Achievement 2}
- {Achievement 3}

{Link to release notes}
```

### External
**Release announcement:**
{If public release}
```
🚀 Announcing {Product} {version}!

{Compelling description}

What's New:
- {Feature 1}
- {Feature 2}
- {Feature 3}

{Link to release notes}
{Link to docs}
```

**Social media:**
{If applicable}
- Twitter/X post
- LinkedIn post
- Blog post

---

## Success Criteria

### Technical
- [x] All features complete and tested
- [x] All tests passing
- [x] No critical bugs
- [x] Performance acceptable
- [x] Security audit passed

### Business
- [ ] User adoption goals: {Target}
- [ ] Performance goals: {Target}
- [ ] Stability goals: {Target}

### User Experience
- [ ] User feedback positive
- [ ] Key workflows smooth
- [ ] Error rates low

---

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| {Risk 1} | {Low/Med/High} | {Low/Med/High/Critical} | {How to mitigate} |
| {Risk 2} | {Low/Med/High} | {Low/Med/High/Critical} | {How to mitigate} |

---

## Timeline

- **Planning started:** {YYYY-MM-DD}
- **Development started:** {YYYY-MM-DD}
- **Feature freeze:** {YYYY-MM-DD}
- **Testing completed:** {YYYY-MM-DD}
- **Staging deployed:** {YYYY-MM-DD}
- **Production deployed:** {YYYY-MM-DD}

**Total duration:** {X weeks/months}

---

## What's Next

### Immediate (Next 2 weeks)
- {Post-release task 1}
- {Post-release task 2}
- {Post-release task 3}

### Short-term (Next milestone)
- {Planned feature 1}
- {Planned feature 2}
- {Planned feature 3}

### Long-term (Future milestones)
- {Vision item 1}
- {Vision item 2}

---

## Lessons Learned

### What Went Well
- {Thing 1}
- {Thing 2}
- {Thing 3}

### What Could Improve
- {Thing 1}
- {Thing 2}
- {Thing 3}

### Action Items
- [ ] {Action 1} - Owner: {name}
- [ ] {Action 2} - Owner: {name}
- [ ] {Action 3} - Owner: {name}

---

## Credits

**Contributors:**
{List everyone who contributed}

**Special Thanks:**
{Acknowledge specific contributions}

---

**Milestone Status:** ✅ Released

**Released by:** {Name}
**Release notes:** {Link}
**Documentation:** {Link}
```

---

### 4. Generate Comprehensive Changelog

**Update CHANGELOG.md:**
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [{version}] - {YYYY-MM-DD}

### 🎉 Milestone: {Milestone Name}

{Brief description of what this milestone achieves}

---

### ✨ Added

{For each feature that added new functionality:}

#### F{XXX}: {Feature Title}
- {New capability 1}
- {New capability 2}
- {New capability 3}

{Repeat for all "added" features}

---

### 🔄 Changed

{For features that modified existing functionality:}

- **F{XXX}:** {What changed and why}
- **F{XXX}:** {What changed and why}

---

### 🐛 Fixed

{For bug fixes:}

- **F{XXX}:** Fixed {bug description}
- **Hotfix {version}:** Fixed {critical bug}

---

### 🚨 Breaking Changes

{If major version:}

⚠️ **This release contains breaking changes!**

#### API Changes
- `GET /api/old` removed - Use `GET /api/new`
- `User.name` → `User.fullName`

See [Migration Guide](docs/milestones/MILESTONE-{version}.md#migration-guide)

---

### 🔒 Security

- Fixed {security issue}
- Updated {vulnerable dependency}

---

### 📊 Metrics

- **Features:** {N} completed
- **Commits:** {N}
- **Files changed:** {N}
- **Tests added:** {N}
- **Coverage:** {X}% (↑ from {Y}%)
- **Performance:** {improvement}

---

### 🙏 Credits

Thanks to all contributors who made this release possible!

{List contributors}

---

## [{previous_version}] - {date}
{Previous entries...}
```

---

### 5. Update Version in All Files

**Update package.json:**
```bash
# Update root package.json
npm version {version} --no-git-tag-version

# If using Nx, update all workspace packages
pnpm nx run-many --target=version --all --newVersion={version}
```

**Update other version references:**
- `apps/client/package.json`
- `apps/api/package.json`
- Any other files with version numbers

---

### 6. Create Release Branch (if needed)

**For major releases:**
```bash
# Create release branch for ongoing support
git checkout -b release/{version}
git push origin release/{version}
```

This allows hotfixes for this version while development continues on main.

---

### 7. Commit Milestone Changes

```bash
git add -A
git commit -m "chore: release v{version} - {milestone name}

Milestone release containing {N} features:
{List features briefly}

Breaking changes: {Yes/No}
Migration guide: docs/milestones/MILESTONE-{version}.md

Total effort:
- Features: {N}
- Sessions: {N}
- Time: {X hours}
- Commits: {N}
- Tests: {N}

See CHANGELOG.md for complete details.
"
```

---

### 8. Create Git Tag

```bash
git tag -a "v{version}" -m "{Milestone Name}

Milestone release v{version}

Theme: {theme}
Features: {N} completed

Key highlights:
- {Highlight 1}
- {Highlight 2}
- {Highlight 3}

Breaking changes: {Yes/No}

See docs/milestones/MILESTONE-{version}.md for details.
"
```

---

### 9. Push to Repository

```bash
# Push commits
git push origin main

# Push tag
git push origin v{version}

# If created release branch
git push origin release/{version}
```

---

### 10. Create GitHub Release

**Use gh CLI:**
```bash
gh release create v{version} \
  --title "{Milestone Name} ({version})" \
  --notes-file docs/milestones/MILESTONE-{version}.md \
  --latest
```

**Or provide manual link:**
```
Create release manually:
https://github.com/{org}/{repo}/releases/new?tag=v{version}

Title: {Milestone Name} ({version})
Description: Copy from docs/milestones/MILESTONE-{version}.md
```

---

### 11. Update Roadmap

**Update docs/ROADMAP.md:**
- Mark milestone as "Released"
- Update progress percentages
- Move to "Completed Milestones" section

---

### 12. Deploy to Production

**Follow deployment plan from milestone doc:**
1. Backup database
2. Deploy to staging
3. Run smoke tests
4. Deploy to production
5. Run migrations
6. Verify deployment
7. Monitor for issues

---

### 13. Announce Release

**Display to user:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 MILESTONE RELEASED! 🎉
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestone: {Milestone Name}
Version: {version}
Type: {Major/Minor}

📊 Summary:
   • Features completed: {N}
   • Total sessions: {N}
   • Total time: {X hours}
   • Calendar duration: {X weeks}
   • Commits: {N}
   • Tests added: {N}

✨ Highlights:
   • {Highlight 1}
   • {Highlight 2}
   • {Highlight 3}

{If breaking changes:}
⚠️  Breaking Changes:
   • See migration guide
   • Update guide: docs/milestones/MILESTONE-{version}.md

📦 Release:
   • Tagged: v{version}
   • Changelog: ✅ Updated
   • GitHub Release: {URL}
   • Documentation: ✅ Complete

🚀 Deployment:
   • Staging: ✅ Deployed
   • Production: {Pending/Deployed}
   • Status: {URL}

📝 Documentation:
   • Milestone doc: docs/milestones/MILESTONE-{version}.md
   • Release notes: {URL}
   • Migration guide: {URL if breaking}

🎯 Next Steps:
   1. Monitor production deployment
   2. Gather user feedback
   3. Plan next milestone
   4. Communicate to stakeholders

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Congratulations on shipping {Milestone Name}! 🚀

Ready to announce this release? [y/N]
```

---

## Error Handling

**If no completed features:**
```
❌ No completed features found for this milestone.

To create a milestone release, you need:
• At least one completed feature
• Features marked for this milestone

Available completed features:
{List}

Do you want to:
1. Select features for this milestone
2. Cancel
```

**If version conflict:**
```
❌ Version {version} already exists!

Current: {current}
Existing tag: v{version}

Please choose a different version.
```

**If tests failing:**
```
❌ Cannot create release - tests are failing!

Failed tests:
{List failures}

Fix tests before releasing.
```

---

## Examples

**Usage:**
```bash
/release-milestone mvp-launch
```

**Expected output:**
```
Milestone release: mvp-launch

Type: Major (1.5.3 → 2.0.0)

Features included:
- F001: User authentication
- F002: Google OAuth
- F003: RAG system
- F004: Project management

Proceed? [y/N]
> y

Creating milestone documentation...
Updating changelog...
Creating release tag...

🎉 Milestone V2.0.0 released!
```

---

## Important Notes

- Milestone releases bundle multiple features
- Should align with roadmap planning
- Require comprehensive testing
- Need clear communication plan
- Breaking changes need migration guides
- Post-release monitoring essential

**Milestones represent significant product evolution!**
