#!/bin/bash
# Epub Renamer Installer - Run Go epub renamer via curl
# Usage: curl -L https://raw.githubusercontent.com/user/repo/main/install.sh | bash -s -- [args]

set -e

REPO_URL="https://github.com/user/go-epub-renamer"
BINARY_NAME="epub-renamer"
INSTALL_DIR="${HOME}/.local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}INFO:${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}WARN:${NC} $1"
}

log_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

# Detect platform
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case $OS in
        linux)
            OS="linux"
            ;;
        darwin)
            OS="darwin"
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac

    case $ARCH in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    BINARY_SUFFIX="${OS}-${ARCH}"
    if [ "$OS" = "windows" ]; then
        BINARY_SUFFIX="${BINARY_SUFFIX}.exe"
    fi
}

# Download and install binary
install_binary() {
    log_info "Installing epub-renamer..."

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Download binary
    BINARY_URL="${REPO_URL}/releases/latest/download/${BINARY_NAME}-${BINARY_SUFFIX}"
    BINARY_PATH="${INSTALL_DIR}/${BINARY_NAME}"

    log_info "Downloading from: $BINARY_URL"
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$BINARY_PATH" "$BINARY_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$BINARY_PATH" "$BINARY_URL"
    else
        log_error "Neither curl nor wget found"
        exit 1
    fi

    # Make executable
    chmod +x "$BINARY_PATH"

    log_info "Installed to: $BINARY_PATH"
}

# Check if binary is available
check_binary() {
    if [ -x "${INSTALL_DIR}/${BINARY_NAME}" ]; then
        return 0
    else
        return 1
    fi
}

# Main execution
main() {
    detect_platform

    if ! check_binary; then
        install_binary
    fi

    # Execute with all passed arguments
    exec "${INSTALL_DIR}/${BINARY_NAME}" "$@"
}

# Run main function with all arguments
main "$@"