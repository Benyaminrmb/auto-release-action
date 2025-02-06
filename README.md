# Auto Release Action 🚀
 
A GitHub Action that automatically creates semantic versioned releases based on conventional commits. This action automatically detects changes, bumps version numbers, and generates comprehensive changelogs with links to commits, PRs, and contributors.

## Features ✨

- 🔄 Automatic version bumping based on conventional commits
- 📝 Enhanced changelog generation with smart linking
- 🔗 Automatic linking of commits, PRs, issues, and contributors
- 📊 Detailed release statistics including lines changed
- 🎯 Support for breaking changes and conventional commits
- 🔀 Smart merge commit handling
- 👥 GitHub-style contributor attribution
- 📈 Comprehensive release statistics
- 🔍 Intelligent commit message parsing
- 🏷️ Proper git tag handling

## Usage 📋

1. Create `.github/workflows/release.yml` in your repository
2. Add the following content:

```yaml
name: Release

on:
  push:
    branches:
      - main  # Change this to your default branch if different

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: Benyaminrmb/auto-release-action@v1.4.0
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

3. Start using conventional commits in your repository!

## Commit Convention 📝

The action recognizes the following commit types:

| Type | Description | Version Bump |
|------|-------------|--------------|
| `BREAKING CHANGE` or `!:` | Breaking API changes | Major (`X.0.0`) |
| `feat:` | New features | Minor (`0.X.0`) |
| `fix:` | Bug fixes | Patch (`0.0.X`) |
| `docs:` | Documentation updates | None |
| `refactor:` | Code refactoring | None |
| `test:` | Adding/updating tests | None |
| `chore:` | Maintenance tasks | None |

### Examples:

```bash
git commit -m "feat: add new user authentication"
git commit -m "fix: resolve memory leak"
git commit -m "BREAKING CHANGE: rename core API methods"
git commit -m "fix: update user profile (#123)" # Links to PR #123
git commit -m "feat: add search functionality (fixes #456)" # Links to Issue #456
```

## Release Output Example 📦

```markdown
## 🎉 Release v1.3.0

### ✨ New Features
- [`abc1234`](https://github.com/user/repo/commit/abc1234) (#123): Add user authentication ([@username](https://github.com/username))

### 🐛 Bug Fixes
- [`def567`](https://github.com/user/repo/commit/def567) (fixes #456): Resolve memory leak ([@username](https://github.com/username))

### 📝 Documentation Updates
- [`ghi890`](https://github.com/user/repo/commit/ghi890): Update API documentation ([@username](https://github.com/username))

## 📊 Statistics
- Total Commits: `5`
- Contributors: `2`
- Lines Changed: `+123 -45`

## 🔗 Links
- [Full Changelog](https://github.com/user/repo/compare/v1.2.0...v1.3.0)
- [Release Notes](https://github.com/user/repo/releases/tag/v1.3.0)
```

## Release Features 🎯

- **Smart Linking**: Automatically links commits, PRs, and issues
- **GitHub Username Detection**: Properly detects and links GitHub usernames
- **Comprehensive Statistics**: Shows lines changed, commit counts, and contributor stats
- **Clean Commit Messages**: Intelligently cleans and formats commit messages
- **Multiple PR/Issue Links**: Supports multiple PR and issue references per commit
- **Proper Bot Identity**: Uses GitHub Actions bot identity for commits
- **Protected Branch Support**: Works with protected branches and required checks

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request.

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support 💬

If you encounter any issues or have questions:
1. Check existing issues
2. Open a new issue with:
    - Workflow file content
    - Action logs
    - Repository structure
    - Expected vs actual behavior
