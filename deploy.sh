#!/bin/bash

# Robot Eyes Deployment Script
# Automates: commit-sync -> build server fetch/pull -> build -> copy to workspace -> deploy to Pi
# Usage: ./deploy.sh [OPTIONS]
# Options:
#   -b, --branch BRANCH           Git branch to deploy (default: pi5-support)
#   -bs, --build-server IP        Build server IP (default: 192.168.0.70)
#   -tp, --target-pi IP           Target Pi IP (default: 192.168.0.116)
#   -u, --user USER               SSH user (default: pi)
#   -v, --version VERSION         Version for artifacts folder (default: auto-parsed from pubspec.yaml)
#   -h, --help                    Show this help message

set -e

# Default values
BRANCH="pi5-support"
BUILD_SERVER_IP="192.168.0.70"
TARGET_PI_IP="192.168.0.116"
SSH_USER="pi"
VERSION=""  # Will be parsed from pubspec.yaml if not provided
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="rpi_eyes"
REPO_URL="https://github.com/ilkerokutman/Robot-Eyes-With-Flutter-and-Raspberry.git"

# Function to parse version from pubspec.yaml
parse_version_from_pubspec() {
  local pubspec_file="$SCRIPT_DIR/${PROJECT_NAME}/pubspec.yaml"
  if [[ ! -f "$pubspec_file" ]]; then
    echo -e "${RED}✗ Error: pubspec.yaml not found at $pubspec_file${NC}"
    exit 1
  fi
  grep "^version:" "$pubspec_file" | awk '{print $2}' | tr -d '\r'
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--branch)
      BRANCH="$2"
      shift 2
      ;;
    -bs|--build-server)
      BUILD_SERVER_IP="$2"
      shift 2
      ;;
    -tp|--target-pi)
      TARGET_PI_IP="$2"
      shift 2
      ;;
    -u|--user)
      SSH_USER="$2"
      shift 2
      ;;
    -v|--version)
      VERSION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Robot Eyes Deployment Script"
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -b, --branch BRANCH           Git branch to deploy (default: pi5-support)"
      echo "  -bs, --build-server IP        Build server IP (default: 192.168.0.70)"
      echo "  -tp, --target-pi IP           Target Pi IP (default: 192.168.0.116)"
      echo "  -u, --user USER               SSH user (default: pi)"
      echo "  -v, --version VERSION         Override version (default: auto-parsed from pubspec.yaml)"
      echo "  -h, --help                    Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                                    # Deploy pi5-support with auto-parsed version"
      echo "  $0 -b main                           # Deploy main branch with auto-parsed version"
      echo "  $0 -v 2.0.0                          # Override version to 2.0.0"
      echo "  $0 -bs 192.168.1.10 -tp 192.168.1.20 # Deploy to custom IPs"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Parse version from pubspec.yaml if not provided via argument
if [[ -z "$VERSION" ]]; then
  echo -e "${YELLOW}Parsing version from pubspec.yaml...${NC}"
  VERSION=$(parse_version_from_pubspec)
  echo -e "${GREEN}✓ Version parsed: $VERSION${NC}"
fi

# Configuration summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Robot Eyes Deployment Configuration${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Branch:           ${GREEN}$BRANCH${NC}"
echo -e "Version:          ${GREEN}$VERSION${NC}"
echo -e "Build Server:     ${GREEN}${SSH_USER}@${BUILD_SERVER_IP}${NC}"
echo -e "Target Pi:        ${GREEN}${SSH_USER}@${TARGET_PI_IP}${NC}"
echo -e "Workspace:        ${GREEN}$SCRIPT_DIR${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Commit and sync from macOS
echo -e "${YELLOW}[1/5] Committing changes and syncing to GitHub...${NC}"
cd "$SCRIPT_DIR"
if [[ -n $(git status -s) ]]; then
  echo "Staging all changes..."
  git add -A
  echo "Committing changes..."
  git commit -m "Auto-deployment commit - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Pushing to remote..."
  git push origin "$BRANCH"
  echo -e "${GREEN}✓ Changes committed and pushed${NC}"
else
  echo -e "${GREEN}✓ No changes to commit${NC}"
fi
echo ""

# Step 2: Fetch and pull on build server
echo -e "${YELLOW}[2/5] Fetching and pulling on build server...${NC}"
ssh "${SSH_USER}@${BUILD_SERVER_IP}" "cd ~/Robot-Eyes-With-Flutter-and-Raspberry && git fetch origin && git checkout ${BRANCH} && git pull origin ${BRANCH}" || {
  echo -e "${RED}✗ Failed to fetch/pull on build server${NC}"
  exit 1
}
echo -e "${GREEN}✓ Build server updated${NC}"
echo ""

# Step 3: Trigger build on build server
echo -e "${YELLOW}[3/5] Building on build server...${NC}"
ssh "${SSH_USER}@${BUILD_SERVER_IP}" "cd ~/Robot-Eyes-With-Flutter-and-Raspberry/${PROJECT_NAME} && rm -rf build .dart_tool && /opt/flutter/bin/flutter clean && /opt/flutter/bin/flutter pub get && /opt/flutter/bin/flutter build linux --release -t lib/main_spi.dart" || {
  echo -e "${RED}✗ Build failed on build server${NC}"
  exit 1
}
echo -e "${GREEN}✓ Build completed successfully${NC}"
echo ""

# Step 4: Copy bundle to workspace artifacts
echo -e "${YELLOW}[4/5] Copying bundle to workspace artifacts...${NC}"
ARTIFACTS_DIR="$SCRIPT_DIR/artifacts/${PROJECT_NAME}_${VERSION}"

# Remove existing artifacts directory if it exists
if [[ -d "$ARTIFACTS_DIR" ]]; then
  echo "Removing existing artifacts directory..."
  rm -rf "$ARTIFACTS_DIR"
fi

mkdir -p "$ARTIFACTS_DIR"

# Copy from build server
echo "Downloading build artifacts from build server..."
scp -r "${SSH_USER}@${BUILD_SERVER_IP}:~/Robot-Eyes-With-Flutter-and-Raspberry/${PROJECT_NAME}/build/linux/arm64/release/bundle/" "$ARTIFACTS_DIR/" || {
  echo -e "${RED}✗ Failed to copy artifacts from build server${NC}"
  exit 1
}

# Reorganize if needed
if [[ -d "$ARTIFACTS_DIR/bundle" ]]; then
  mv "$ARTIFACTS_DIR/bundle"/* "$ARTIFACTS_DIR/"
  rmdir "$ARTIFACTS_DIR/bundle"
fi

echo -e "${GREEN}✓ Artifacts copied to: $ARTIFACTS_DIR${NC}"
echo ""

# Step 5: Deploy to target Pi
echo -e "${YELLOW}[5/5] Deploying to target Pi...${NC}"
echo "Copying executable to Pi..."
scp "$ARTIFACTS_DIR/${PROJECT_NAME}" "${SSH_USER}@${TARGET_PI_IP}:/opt/eyes/${PROJECT_NAME}" || {
  echo -e "${RED}✗ Failed to copy executable to Pi${NC}"
  exit 1
}

echo "Setting executable permissions..."
ssh "${SSH_USER}@${TARGET_PI_IP}" "chmod +x /opt/eyes/${PROJECT_NAME}" || {
  echo -e "${RED}✗ Failed to set permissions on Pi${NC}"
  exit 1
}

echo -e "${GREEN}✓ Deployment to Pi completed${NC}"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Version:          ${YELLOW}$VERSION${NC}"
echo -e "Branch:           ${YELLOW}$BRANCH${NC}"
echo -e "Artifacts:        ${YELLOW}$ARTIFACTS_DIR${NC}"
echo -e "Deployed to:      ${YELLOW}${SSH_USER}@${TARGET_PI_IP}:/opt/eyes/${PROJECT_NAME}${NC}"
echo ""
echo "To test the deployment, run:"
echo -e "  ${BLUE}ssh ${SSH_USER}@${TARGET_PI_IP} 'cd /opt/eyes && ./${PROJECT_NAME}'${NC}"
echo ""
