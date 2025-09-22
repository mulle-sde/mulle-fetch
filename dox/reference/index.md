# mulle-fetch Command Reference

## Overview

**mulle-fetch** is a cross-platform command-line tool for retrieving and managing source code repositories and archives. It supports git repositories, zip/tar archives, and various other source formats with intelligent caching and mirroring capabilities.

## Command Categories

### Core Operations
- **[`fetch`](fetch.md)** - Explicitly fetch archive or repository into a directory
- **[`checkout`](checkout.md)** - Checkout branches or commits from repositories
- **[`update`](update.md)** - Update repository (git fetch equivalent)
- **[`status`](status.md)** - Show repository status information

### Convenient Operations
- **[`cfetch`](cfetch.md)** - Conveniently fetch and unpack URL by guessing a lot (default)

### Repository Management
- **[`search-local`](search-local.md)** - Search repository in folders given in MULLE_FETCH_SEARCH_PATH
- **[`set-url`](set-url.md)** - Set or change repository URL
- **[`upgrade`](upgrade.md)** - Upgrade repository (git pull equivalent)

### System Operations
- **[`list`](list.md)** - List available plugins
- **[`operation`](operation.md)** - List operations available (for mulle-sourcetree)
- **[`plugin`](plugin.md)** - Manage mulle-fetch plugins

### Utility Commands
- **[`allow`](allow.md)** - Allow this directory being symlinked by projects (default)
- **[`prevent`](prevent.md)** - Prevent this directory from being symlinked by other projects
- **[`exists`](exists.md)** - Check if URL is accessible (returns 0=YES)
- **[`uname`](uname.md)** - mulle-fetch's simplified uname(1)
- **[`version`](version.md)** - Print mulle-fetch version
- **[`libexec-dir`](libexec-dir.md)** - Print path to mulle-fetch libexec

### Advanced Operations
- **[`domain`](domain.md)** - Special commands to query remote tags

## Quick Start Examples

### Basic Fetch Operations
```bash
# Fetch a git repository
mulle-fetch fetch "https://github.com/user/repo.git"

# Convenient fetch with auto-detection
mulle-fetch "github:user/repo"

# Fetch with specific version
mulle-fetch "github:user/repo@v1.0.0"

# Fetch archive
mulle-fetch "https://github.com/user/repo/archive/main.zip"
```

### Repository Management
```bash
# Update existing repository
mulle-fetch update

# Check repository status
mulle-fetch status

# Upgrade to latest version
mulle-fetch upgrade

# Search local repositories
mulle-fetch search-local "repo-name"
```

### Configuration and Setup
```bash
# Set archive cache directory
export MULLE_FETCH_ARCHIVE_DIR="/tmp/cache"

# Set mirror directory for git repos
export MULLE_FETCH_MIRROR_DIR="/tmp/mirrors"

# Set local search paths
export MULLE_FETCH_SEARCH_PATH="/local/repos:/other/path"
```

## Command Reference Table

| Command | Category | Description |
|---------|----------|-------------|
| `fetch` | Core | Explicitly fetch archive or repository |
| `checkout` | Core | Checkout branches or commits |
| `update` | Core | Update repository (git fetch) |
| `status` | Core | Show repository status |
| `cfetch` | Convenient | Convenient fetch with auto-detection |
| `search-local` | Repository | Search in local folders |
| `set-url` | Repository | Set/change repository URL |
| `upgrade` | Repository | Upgrade repository (git pull) |
| `list` | System | List available plugins |
| `operation` | System | List available operations |
| `plugin` | System | Manage plugins |
| `allow` | Utility | Allow directory symlinking |
| `prevent` | Utility | Prevent directory symlinking |
| `exists` | Utility | Check URL accessibility |
| `uname` | Utility | Simplified uname |
| `version` | Utility | Print version |
| `libexec-dir` | Utility | Print libexec path |
| `domain` | Advanced | Query remote tags |

## Getting Help

### Command Help
```bash
# Get help for specific command
mulle-fetch <command> --help

# List all available commands
mulle-fetch --help

# Get detailed help with hidden commands
mulle-fetch -v help
```

### Documentation
- Each command has a dedicated documentation file in this reference
- Use `--help` for quick command usage
- Check `mulle-fetch status` for repository-specific information

## Common Workflows

### Initial Repository Setup
1. **Fetch** repository: `mulle-fetch fetch <url>`
2. **Checkout** specific branch: `mulle-fetch checkout <branch>`
3. **Verify** status: `mulle-fetch status`

### Repository Maintenance
1. **Update** from remote: `mulle-fetch update`
2. **Check** for changes: `mulle-fetch status`
3. **Upgrade** if needed: `mulle-fetch upgrade`

### Local Development
1. **Search** local repos: `mulle-fetch search-local <name>`
2. **Set** alternative URL: `mulle-fetch set-url <new-url>`
3. **Configure** symlinking: `mulle-fetch allow` or `mulle-fetch prevent`

## Troubleshooting

### Fetch Failures
```bash
# Check URL accessibility
mulle-fetch exists <url>

# Try with verbose output
mulle-fetch fetch --verbose <url>

# Clear cache and retry
rm -rf $MULLE_FETCH_ARCHIVE_DIR/*
mulle-fetch fetch <url>
```

### Repository Issues
```bash
# Check repository status
mulle-fetch status

# Reset and update
mulle-fetch update --force

# Check for local conflicts
mulle-fetch status --verbose
```

### Permission Problems
```bash
# Allow symlinking for project
mulle-fetch allow

# Check current permissions
ls -la .mulle/etc/fetch/
```

## Advanced Usage

### Custom Fetch Options
```bash
# Force operation
mulle-fetch fetch --force <url>

# Recursive git fetch
mulle-fetch fetch --recursive <url>

# Specify target directory
mulle-fetch fetch <url> <directory>
```

### Environment Configuration
```bash
# Custom archive cache
export MULLE_FETCH_ARCHIVE_DIR="/custom/cache"

# Custom mirror directory
export MULLE_FETCH_MIRROR_DIR="/custom/mirrors"

# Custom search paths
export MULLE_FETCH_SEARCH_PATH="/path1:/path2:/path3"
```

### Plugin Management
```bash
# List available plugins
mulle-fetch list

# Use specific plugin
mulle-fetch plugin <plugin-name> <args>

# Plugin-specific help
mulle-fetch plugin <plugin-name> --help
```

## Related Documentation

- **[TODO.md](../TODO.md)** - Documentation creation process and guidelines
- **[README.md](../../README.md)** - Project overview and installation
- **[mulle-sde.md](../mulle-sde.md)** - Build system guidelines