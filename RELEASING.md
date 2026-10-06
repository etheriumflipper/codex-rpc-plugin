# Release procedure

Use existing PowerShell and git. Upstream updates require a review of changed behavior, upstream license and GitHub asset digest; change `runtime.json` explicitly. Do not switch to a moving latest-release URL or skip the checksum.

1. Update both plugin manifest versions and CHANGELOG.md.
2. Run `scripts/check.ps1`, inspect the staged files, and commit.
3. Create a version tag matching the manifest, such as `git tag v0.1.0`.
4. Run `scripts/package.ps1 -Ref v0.1.0` to build a git-tracked ZIP and SHA256SUMS; private runtime state is excluded.
5. Push main and the version tag, then create the GitHub release with the ZIP and SHA256SUMS.
6. Download the published assets, validate SHA-256 and archive entries, and check the Windows CI result. Test the Git-backed marketplace install as well.

Keep connection evidence distinct from visible Discord card verification. Do not put account names, session logs or Codex configuration in release assets.
