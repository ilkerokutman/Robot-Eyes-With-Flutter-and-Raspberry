# Robot Eyes Deployment Script

Automated deployment script that handles the entire build and deployment pipeline in one command.

## Features

- **Commit & Sync**: Automatically commits changes and pushes to GitHub
- **Remote Build**: Fetches latest code on build server and triggers Flutter build
- **Artifact Management**: Copies built bundle to versioned artifacts folder
- **Target Deployment**: Deploys executable to target Pi with proper permissions
- **Parameterized**: Supports custom branches, IPs, and versions

## Prerequisites

- SSH key-based authentication configured for both build server and target Pi
- Build server has Flutter SDK installed at `/opt/flutter/bin/flutter`
- Target Pi has `/opt/eyes/` directory created with proper permissions
- macOS with git and standard Unix tools

## Usage

### Basic Deployment (Default Configuration)

```bash
./deploy.sh
```

Deploys `pi5-support` branch to:
- Build Server: `pi@192.168.0.70`
- Target Pi: `pi@192.168.0.116`
- Version: Auto-parsed from `rpi_eyes/pubspec.yaml`

### Custom Branch

```bash
./deploy.sh -b main
```

Version is automatically parsed from pubspec.yaml.

### Override Version

```bash
./deploy.sh -v 2.0.0
```

Useful if you want to use a different version number than what's in pubspec.yaml.

### Custom Build Server

```bash
./deploy.sh -bs 192.168.1.10
```

### Custom Target Pi

```bash
./deploy.sh -tp 192.168.1.20
```

### Custom SSH User

```bash
./deploy.sh -u ubuntu
```

### Combined Options

```bash
./deploy.sh -b main -v 2.0.0 -bs 192.168.1.10 -tp 192.168.1.20 -u ubuntu
```

## What the Script Does

### Step 0: Parse Version (macOS)
- Reads `rpi_eyes/pubspec.yaml`
- Extracts version from `version:` field
- Uses parsed version for artifacts folder naming
- Can be overridden with `-v` flag if needed

### Step 1: Commit & Sync (macOS)
- Checks for uncommitted changes
- Stages all changes with `git add -A`
- Creates auto-commit with timestamp
- Pushes to remote GitHub repository

### Step 2: Fetch & Pull (Build Server)
- SSH to build server
- Fetches latest changes from GitHub
- Checks out specified branch
- Pulls latest commits

### Step 3: Build (Build Server)
- Cleans Flutter build cache
- Runs `flutter pub get`
- Triggers `flutter build linux --release -t lib/main_spi.dart`
- Waits for build completion

### Step 4: Copy to Workspace (macOS)
- Creates versioned artifacts folder: `artifacts/rpi_eyes_VERSION/` (VERSION from pubspec.yaml)
- SCPs built bundle from build server
- Reorganizes folder structure if needed
- Stores in workspace for local backup

### Step 5: Deploy to Pi (Target Pi)
- SCPs executable to `/opt/eyes/rpi_eyes`
- Sets executable permissions
- Verifies deployment

## Output Example

```
Parsing version from pubspec.yaml...
✓ Version parsed: 1.0.0

========================================
Robot Eyes Deployment Configuration
========================================
Branch:           pi5-support
Version:          1.0.0
Build Server:     pi@192.168.0.70
Target Pi:        pi@192.168.0.116
Workspace:        /Volumes/E4/DevTest/FlutterProjects/ilker/eyes
========================================

[1/5] Committing changes and syncing to GitHub...
✓ Changes committed and pushed

[2/5] Fetching and pulling on build server...
✓ Build server updated

[3/5] Building on build server...
✓ Build completed successfully

[4/5] Copying bundle to workspace artifacts...
✓ Artifacts copied to: /Volumes/E4/DevTest/FlutterProjects/ilker/eyes/artifacts/rpi_eyes_1.0.0

[5/5] Deploying to target Pi...
✓ Deployment to Pi completed

========================================
✓ Deployment Complete!
========================================
Version:          1.0.0 (from pubspec.yaml)
Branch:           pi5-support
Artifacts:        /Volumes/E4/DevTest/FlutterProjects/ilker/eyes/artifacts/rpi_eyes_1.0.0
Deployed to:      pi@192.168.0.116:/opt/eyes/rpi_eyes

To test the deployment, run:
  ssh pi@192.168.0.116 'cd /opt/eyes && ./rpi_eyes'
```

## Artifacts Structure

After deployment, artifacts are organized by version:

```
artifacts/
├── rpi_eyes_1.0.0/
│   ├── rpi_eyes (executable)
│   ├── lib/ (shared libraries)
│   └── data/ (Flutter assets)
├── rpi_eyes_1.0.1/
│   ├── rpi_eyes
│   ├── lib/
│   └── data/
└── rpi_eyes_2.0.0/
    ├── rpi_eyes
    ├── lib/
    └── data/
```

## Troubleshooting

### SSH Connection Errors
- Verify SSH keys are configured: `ssh-keygen -t ed25519`
- Copy keys to servers: `ssh-copy-id pi@BUILD_SERVER_IP`
- Test connection: `ssh pi@BUILD_SERVER_IP 'echo OK'`

### Build Failures
- Check Flutter SDK path on build server: `/opt/flutter/bin/flutter --version`
- Verify dependencies: `ssh pi@BUILD_SERVER_IP 'cd ~/Robot-Eyes-With-Flutter-and-Raspberry/rpi_eyes && /opt/flutter/bin/flutter pub get'`
- Check disk space on build server: `ssh pi@BUILD_SERVER_IP 'df -h'`

### Deployment Failures
- Verify `/opt/eyes/` exists on target Pi: `ssh pi@TARGET_PI_IP 'ls -ld /opt/eyes'`
- Check permissions: `ssh pi@TARGET_PI_IP 'ls -la /opt/eyes/'`
- Ensure pi user can write: `ssh pi@TARGET_PI_IP 'touch /opt/eyes/test && rm /opt/eyes/test'`

### Permission Denied Errors
- Build server: Ensure pi user has write access to home directory
- Target Pi: Ensure `/opt/eyes/` is owned by pi user: `sudo chown pi:pi /opt/eyes`

## Testing the Deployment

After successful deployment, test the app on the target Pi:

```bash
ssh pi@192.168.0.116 'cd /opt/eyes && ./rpi_eyes'
```

Expected output:
```
Detected: Raspberry Pi 5 (GPIO chip 0)
Initializing SPI displays...
Initializing display manager...
Initializing left display (CE0)...
Left display initialized
Initializing right display (CE1)...
Right display initialized
Display manager initialized successfully
```

## Advanced Usage

### Deploy Multiple Versions

```bash
# Deploy v1.0.0
./deploy.sh -v 1.0.0

# Deploy v1.0.1 (after making changes)
./deploy.sh -v 1.0.1

# Deploy v2.0.0 to different Pi
./deploy.sh -v 2.0.0 -tp 192.168.0.120
```

### Deploy to Multiple Targets

```bash
# Deploy to first Pi
./deploy.sh -tp 192.168.0.116

# Deploy same build to second Pi
./deploy.sh -tp 192.168.0.117
```

### Dry Run (Manual Steps)

If you want to run steps manually:

```bash
# Step 1: Commit locally
git add -A && git commit -m "My changes"
git push origin pi5-support

# Step 2: Build on server
ssh pi@192.168.0.70 'cd ~/Robot-Eyes-With-Flutter-and-Raspberry/rpi_eyes && /opt/flutter/bin/flutter build linux --release -t lib/main_spi.dart'

# Step 3: Copy to workspace
scp -r pi@192.168.0.70:~/Robot-Eyes-With-Flutter-and-Raspberry/rpi_eyes/build/linux/arm64/release/bundle/ ./artifacts/rpi_eyes_1.0.0/

# Step 4: Deploy to Pi
scp ./artifacts/rpi_eyes_1.0.0/rpi_eyes pi@192.168.0.116:/opt/eyes/
ssh pi@192.168.0.116 'chmod +x /opt/eyes/rpi_eyes'
```

## Notes

- The script uses `set -e` to exit on first error
- All SSH commands use key-based authentication (no password prompts)
- Artifacts are versioned for easy rollback
- Build server path is hardcoded to `~/Robot-Eyes-With-Flutter-and-Raspberry/`
- Target Pi path is hardcoded to `/opt/eyes/`
- Project name is hardcoded to `rpi_eyes`

## Customization

To modify defaults, edit the script variables at the top:

```bash
BRANCH="pi5-support"
BUILD_SERVER_IP="192.168.0.70"
TARGET_PI_IP="192.168.0.116"
SSH_USER="pi"
PROJECT_NAME="rpi_eyes"
```

Version is automatically parsed from `rpi_eyes/pubspec.yaml` and can be overridden with the `-v` flag.
