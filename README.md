# Auto Release Action 🚀
 
A GitHub Action that automatically creates semantic versioned releases based on conventional commits. This action automatically detects changes, bumps version numbers, and generates comprehensive changelogs with links to commits, PRs, and contributors.

## Features ✨

- 🔄 Automatic version bumping based on conventional commits
- 📝 Detailed changelog generation
- 🔗 Smart linking of commits, PRs, and contributors
- 📊 Release statistics
- 🎯 Support for breaking changes
- 🔀 Merge commit handling
- 👥 Proper attribution to contributors

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
      - uses: Benyaminrmb/auto-release-action@v1.2.1
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
| `docs:` | Documentation only | None |
| `refactor:` | Code refactoring | None |
| `test:` | Adding tests | None |
| `chore:` | Maintenance | None |

### Examples:

```bash
git commit -m "feat: add new user authentication"
git commit -m "fix: resolve memory leak in processing"
git commit -m "BREAKING CHANGE: rename core API methods"
```

## Release Output Example 📦

```markdown
## 🎉 Release v1.2.0

### ✨ New Features
- [`abc1234`]: Add user authentication (@username)

### 🐛 Bug Fixes
- [`def567`]: Fix memory leak (#123) (@username)

## 📊 Statistics
- Total Commits: `5`
- Contributors: `2`
```

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