# SyncWeaver 🧵

**Weaving your data safety net**

A flexible bash-based backup automation tool that uses XML configuration files to orchestrate multiple rsync operations. Configure all your backup strategies in one place with SSH support, password or key authentication, smart exclusions, and selective execution.

[![Version](https://img.shields.io/badge/version-1.2-blue.svg)](https://github.com/yourusername/syncweaver)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-brightgreen.svg)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/python-2.7%2B%20%7C%203.x-blue.svg)](https://www.python.org/)

## Features

- **XML-based configuration**: Define all backup operations in a single, human-readable XML file
- **Multiple backup scenarios**: Support for local-to-local, remote-to-local, and local-to-remote backups
- **SSH connectivity**: Built-in SSH support with custom port configuration
- **SSH Config awareness**: Automatically reads `~/.ssh/config` for hostname aliases and port configurations
- **Selective execution**: Run specific backups or all backups at once
- **Exclude patterns**: Define file/folder exclusion patterns per backup
- **Flexible options**: Pass custom rsync options per backup
- **Robust connectivity checks**: Pre-flight checks with SSH config integration and comprehensive error handling
- **Verbose logging**: Optional detailed output for debugging

## Prerequisites

- Bash shell (Linux/Unix)
- Python 2.7+ or 3.x with `lxml` library
- `rsync` command-line tool
- `nc` (netcat) for connectivity checks
- SSH access to remote hosts (if backing up to/from remote systems)
- `expect` (optional, required for password-based authentication)

## Installation

1. Clone or download this repository:
   ```bash
   git clone https://github.com/alfaori1977/syncweaver.git
   cd syncweaver
   ```

2. Install Python dependencies:
   ```bash
   pip install lxml
   ```

3. Ensure scripts are executable:
   ```bash
   chmod +x makeBackups.sh backup.sh
   ```

## Configuration

### Creating Your Backup Configuration

Create an XML configuration file (or use the provided `sample/backupList.xml` as a template):

```xml
<?xml version="1.0" encoding="utf-8"?>
<backupList>
  <backup name="my-backup-name">
    <srcUser>username</srcUser>
    <srcHost>hostname-or-ip</srcHost>
    <srcPort>22</srcPort>
    <srcPath>/path/to/source/</srcPath>
    <tgtPath>/path/to/destination/</tgtPath>
    <excludeList>*.tmp *.log</excludeList>
    <options>-v</options>
  </backup>
</backupList>
```

### Configuration Parameters

Each `<backup>` element supports the following child elements:

| Element | Required | Default | Description |
|---------|----------|---------|-------------|
| `name` | Yes | - | Unique identifier for the backup (attribute) |
| `srcUser` | No | Current user | Source username for SSH |
| `srcHost` | No | - | Source hostname/IP (omit for local source) |
| `srcPort` | No | 22 | SSH port for source connection |
| `srcPath` | Yes | - | Source path to backup from |
| `srcPass` | No | - | Source password for SSH (uses expect) |
| `tgtUser` | No | Current user | Target username for SSH |
| `tgtHost` | No | - | Target hostname/IP (omit for local target) |
| `tgtPort` | No | 22 | SSH port for target connection |
| `tgtPath` | Yes | - | Target path to backup to |
| `tgtPass` | No | - | Target password for SSH (uses expect) |
| `excludeList` | No | - | Space-separated list of patterns to exclude |
| `options` | No | - | Additional rsync options (e.g., `-v`, `-n`) |

### Backup Scenarios

#### 1. Remote to Local
```xml
<backup name="remote-to-local">
  <srcUser>root</srcUser>
  <srcHost>server.example.com</srcHost>
  <srcPath>/home/data/</srcPath>
  <tgtPath>/mnt/backups/server-data/</tgtPath>
  <options>-v</options>
</backup>
```

#### 2. Local to Remote
```xml
<backup name="local-to-remote">
  <srcPath>/home/mydata/</srcPath>
  <tgtHost>backup-server</tgtHost>
  <tgtPath>/backups/mydata/</tgtPath>
  <options>-v</options>
</backup>
```

#### 3. Local to Local
```xml
<backup name="local-to-local">
  <srcPath>/mnt/source/photos/</srcPath>
  <tgtPath>/mnt/backup/photos/</tgtPath>
  <options>-v</options>
</backup>
```

#### 4. With Custom Port and Exclusions
```xml
<backup name="camera-backup">
  <srcUser>user</srcUser>
  <srcHost>192.168.1.33</srcHost>
  <srcPort>2222</srcPort>
  <srcPath>/storage/photos/</srcPath>
  <tgtPath>/mnt/backups/phone-photos/</tgtPath>
  <excludeList>*.tmp nohup.out* .cache/</excludeList>
  <options>-vn</options>
</backup>
```

#### 5. Mobile Device Backup with Password Authentication
```xml
<backup name="phone-photos">
  <srcUser>alfaori</srcUser>
  <srcHost>192.168.1.33</srcHost>
  <srcPort>2222</srcPort>
  <srcPass>admin</srcPass>
  <srcPath>/storage/emulated/0/DCIM/Camera/</srcPath>
  <tgtPath>/mnt/backups/phone/DCIM/Camera/</tgtPath>
  <excludeList>.thumbnails .Shared</excludeList>
  <options>-v --stats --progress</options>
</backup>
```

#### 6. Using Environment Variables
```xml
<backup name="home-backup">
  <srcUser>myuser</srcUser>
  <srcHost>server.example.com</srcHost>
  <srcPath>/home/myuser/</srcPath>
  <tgtPath>$HOME/BACKUPS/server-home/</tgtPath>
  <excludeList>*.log cache/</excludeList>
  <options>-v</options>
</backup>
```

#### 7. Bidirectional Sync Setup (NAS to External Drive)
```xml
<!-- Backup from NAS to local drive -->
<backup name="nas-to-4tb">
  <srcUser>alfaori</srcUser>
  <srcHost>NASI</srcHost>
  <srcPass>mypassword</srcPass>
  <srcPath>/volume2/photo/</srcPath>
  <tgtPath>/mnt/4TB/photo/</tgtPath>
  <excludeList>.thumbnails @eaDir .DS_Store</excludeList>
  <options>-v --stats --progress</options>
</backup>

<!-- Backup from local drive to NAS -->
<backup name="4tb-to-nas">
  <srcPath>/mnt/4TB/photo/</srcPath>
  <tgtUser>alfaori</tgtUser>
  <tgtHost>NASI</tgtHost>
  <tgtPass>mypassword</tgtPass>
  <tgtPath>/volume2/photo/</tgtPath>
  <excludeList>.thumbnails @eaDir .DS_Store</excludeList>
  <options>-v --stats --progress</options>
</backup>
```

## Usage

### Basic Syntax

```bash
./makeBackups.sh [-B <backupXmlFile>] [-v] <backup_list> | all
```

### Options

- `-B <backupXmlFile>` : Specify a custom XML configuration file (default: `backupList.xml`)
- `-v` : Enable verbose mode for detailed output
- `-h` : Display help message

### Parameters

- `<backup_list>` : Space-separated list of backup names to execute
- `all` : Execute all backups defined in the XML file

### Examples

1. **Run all backups with verbose output:**
   ```bash
   ./makeBackups.sh -v all
   ```

2. **Run specific backups:**
   ```bash
   ./makeBackups.sh backup1 backup2 backup3
   ```

3. **Run with custom configuration file:**
   ```bash
   ./makeBackups.sh -B /path/to/custom-config.xml all
   ```

4. **Run a single backup verbosely:**
   ```bash
   ./makeBackups.sh -v camera@poco7_2_photo@d
   ```

5. **List all available backups:**
   ```bash
   python getBackupInfo.py backupList sample/backupList.xml
   ```

## Project Structure

```
syncweaver/
├── backup.sh              # Core backup execution script
├── makeBackups.sh         # Main entry point
├── commonVars             # Common variables and settings
├── getBackupInfo.py       # XML parser for backup configurations
├── getProductInfo.py      # Product information utility
├── utils.sh               # Utility functions
├── m_scp_exec.exp         # Expect script for password authentication
├── rsyncR2R.sh            # Remote-to-remote rsync helper
├── sample/
│   └── backupList.xml     # Sample configuration file
└── README.md              # This file
```

## How It Works

1. **Configuration Parsing**: The `getBackupInfo.py` script parses the XML configuration file and extracts backup parameters.

2. **Backup Selection**: The `makeBackups.sh` script processes command-line arguments to determine which backups to run.

3. **Execution**: For each selected backup, `backup.sh` is invoked with the appropriate parameters:
   - Determines backup type (remote-to-local, local-to-remote, or local-to-local)
   - Performs connectivity checks for remote hosts
   - Creates target directories if needed
   - Executes rsync with configured options and exclusions

4. **Logging**: All operations are logged for audit and debugging purposes.

## Authentication Methods

### SSH Key Authentication (Recommended)

For secure, passwordless operation, set up SSH key-based authentication:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096

# Copy public key to remote host
ssh-copy-id -p <port> <user>@<host>

# Test connection
ssh -p <port> <user>@<host>
```

### Password Authentication (Using Expect)

If SSH key authentication is not available, you can use password-based authentication by adding `srcPass` or `tgtPass` fields to your backup configuration. The tool uses the `expect` utility to automate password entry.

**Important Security Note**: Storing passwords in plain text configuration files is less secure than SSH key authentication. Use this method only when SSH keys are not feasible, and ensure your configuration files have restricted permissions.

#### Installing Expect

On most systems, you can install expect:

```bash
# Ubuntu/Debian
sudo apt-get install expect

# CentOS/RHEL
sudo yum install expect

# macOS
brew install expect
```

#### Configuration Example with Password

```xml
<backup name="remote-with-password">
  <srcUser>myuser</srcUser>
  <srcHost>192.168.1.50</srcHost>
  <srcPort>2222</srcPort>
  <srcPass>mypassword</srcPass>
  <srcPath>/data/important/</srcPath>
  <tgtPath>$HOME/backups/important/</tgtPath>
  <options>-v</options>
</backup>
```

For local-to-remote backups with password:

```xml
<backup name="local-to-remote-with-password">
  <srcPath>/home/data/</srcPath>
  <tgtUser>backupuser</tgtUser>
  <tgtHost>backup.server.com</tgtHost>
  <tgtPass>securepassword</tgtPass>
  <tgtPath>/mnt/backups/data/</tgtPath>
  <options>-v</options>
</backup>
```

#### How Password Authentication Works

1. When `srcPass` or `tgtPass` is specified, the tool uses the `m_scp_exec.exp` expect script
2. The expect script automatically responds to SSH password prompts
3. It also handles SSH host key verification prompts (answering "yes" automatically)
4. The password is passed securely to the expect script via command-line arguments

#### Securing Password-Protected Configurations

If you must use password authentication:

1. **Restrict file permissions** on your configuration file:
   ```bash
   chmod 600 backupList.xml
   ```

2. **Store configuration outside version control**:
   ```bash
   # Add to .gitignore
   echo "backupList.xml" >> .gitignore
   echo "**/backupList*.xml" >> .gitignore
   ```

3. **Use environment variables** for sensitive values (future enhancement)

4. **Migrate to SSH keys** as soon as possible for better security

## SSH Configuration Integration

SyncWeaver intelligently integrates with your SSH configuration file (`~/.ssh/config`), allowing you to use SSH host aliases and benefit from pre-configured settings.

### Using SSH Config Aliases

Define host aliases in `~/.ssh/config`:

```ssh-config
Host myserver
    HostName 192.168.1.100
    Port 2222
    User myuser
    IdentityFile ~/.ssh/id_rsa_backup

Host nas
    HostName nas.local
    Port 22
    User admin
```

Then reference these aliases in your backup configuration:

```xml
<backup name="server-backup">
  <srcHost>myserver</srcHost>  <!-- Uses settings from ~/.ssh/config -->
  <srcPath>/data/important/</srcPath>
  <tgtPath>/mnt/backups/server/</tgtPath>
  <options>-v</options>
</backup>
```

### Port Override Behavior

SyncWeaver has intelligent port handling:

1. **SSH Config Priority**: If a host is defined in `~/.ssh/config` with a port, that port is used
2. **XML Override**: If you specify `<srcPort>` or `<tgtPort>` in XML and it differs from the SSH config, the XML value takes precedence
3. **Default Fallback**: If no port is specified anywhere, defaults to port 22

Example with port override:

```xml
<backup name="temp-override">
  <srcHost>myserver</srcHost>
  <srcPort>3333</srcPort>  <!-- Overrides SSH config port 2222 -->
  <srcPath>/tmp/data/</srcPath>
  <tgtPath>/backups/temp/</tgtPath>
</backup>
```

### Benefits of SSH Config Integration

- **Centralized SSH settings**: Manage all SSH configurations in one place
- **Shorter configuration**: No need to repeat port numbers and usernames
- **ProxyJump support**: Leverage SSH tunneling and jump hosts
- **Key management**: Use different SSH keys per host automatically
- **Host verification**: SSH config `StrictHostKeyChecking` settings are honored

## Troubleshooting

### Connection Issues
- Verify remote host is accessible: `nc -z <host> <port>`
- Check SSH connectivity: `ssh -p <port> <user>@<host>`
- Test with SSH config alias: `ssh <alias>` (if using SSH config)
- Ensure SSH keys are properly configured
- **New**: Check that `nc` (netcat) is installed: `which nc`
- **New**: Verify SSH config syntax: `ssh -G <host>` shows resolved configuration

### Permission Issues
- Verify source path permissions on remote host
- Ensure target directory is w
  - **Enhanced connectivity checks** with SSH config integration
  - Robust error handling and input validation
  - Automatic SSH config hostname and port resolutionritable
- Check that user has appropriate sudo rights if needed

### XML Parsing Errors
- Validate XML syntax: `xmllint --noout backupList.xml`
- Ensure all required fields are present
- Check for special characters that need escaping

### Rsync Errors
- Test rsync command manually with verbose flag: `rsync -av --dry-run ...`
- Review exclude patterns for syntax errors
- Verify paths end with `/` for directory syncing

## rsync Options Reference

Common options that can be added to the `<options>` element:

- `-v` : Verbose output
- `-n` : Dry run (no changes made)
- `--delete` : Delete files in destination that don't exist in source
- `--progress` : Show progress during transfer
- `-z` : Compress data during transfer
- `--bwlimit=KBPS` : Limit bandwidth usage

## Security Considerations

- **Use SSH keys over passwords**: SSH key authentication is more secure than password-based authentication
- **Protect configuration files**: If using password authentication (`srcPass`/`tgtPass`), set strict file permissions:
  ```bash
  chmod 600 backupList.xml
  ```
- **Exclude sensitive files**: Store configuration files outside version control
  ```bash
  echo "backupList.xml" >> .gitignore
  ```
- Use `rsync --partial` for large transfers that may be interrupted
- Regularly review and update exclude patterns to avoid backing up sensitive temporary files
- Use `--dry-run` (`-n`) option to test backups before running them
- **Never commit passwords** to version control systems
- Consider using a separate configuration file for production with restricted access

## Why SyncWeaver?

Traditional backup scripts scatter configuration across multiple files or hardcode parameters. SyncWeaver **weaves** all your backup strategies into a single, maintainable XML configuration. Whether you're syncing mobile photos, backing up servers, or maintaining NAS redundancy, SyncWeaver orchestrates it all with simple, declarative syntax.

## License

MIT License - See [LICENSE](LICENSE) file for details

## Author

**SyncWeaver** - XML-driven backup automation

Created with ❤️ for sysadmins, power users, and anyone who values their data.

## Version History

- **v1.2** (2026) - Current stable release
  - XML-based configuration
  - Password and SSH key authentication
  - Multi-scenario support (local, remote, bidirectional)
  - Smart exclusion patterns
  - Selective backup execution

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Support

- 🐛 **Bug Reports**: [Open an issue](https://github.com/yourusername/syncweaver/issues)
- 💡 **Feature Requests**: [Start a discussion](https://github.com/yourusername/syncweaver/discussions)
- 📖 **Documentation**: Check this README or browse the [wiki](https://github.com/yourusername/syncweaver/wiki)
- ⭐ **Star this repo** if SyncWeaver helps you!

---

*"Don't just backup - weave a safety net for your data."* 🧵
