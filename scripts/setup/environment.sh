#!/usr/bin/env bash
# Intent: Shared environment setup for AI coding assistants (Codex, Claude Code, etc.)
#
# This script sets up the development environment for the offload iOS project:
# - Xcode command line tools and version validation
# - iOS simulator runtime and devices
# - SwiftLint and SwiftFormat for code quality
# - markdownlint for documentation linting
#
# Usage:
#   ./scripts/setup/environment.sh [--skip-simulators] [--skip-xcode-license]
#
# Options:
#   --skip-simulators     Skip simulator setup (useful for headless environments)
#   --skip-xcode-license  Skip Xcode license acceptance (requires sudo)
#   --quiet               Reduce output verbosity

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Pinned environment values
XCODE_VERSION="16.3"
SIM_DEVICE="iPhone 16"
SIM_OS="18.2"

# Parse arguments
SKIP_SIMULATORS=false
SKIP_XCODE_LICENSE=false
QUIET=false

for arg in "$@"; do
    case "${arg}" in
        --skip-simulators) SKIP_SIMULATORS=true ;;
        --skip-xcode-license) SKIP_XCODE_LICENSE=true ;;
        --quiet) QUIET=true ;;
    esac
done

info() {
    if [[ "${QUIET}" == "false" ]]; then
        echo "[INFO] $*"
    fi
}

warn() {
    echo "[WARN] $*" >&2
}

err() {
    echo "[ERROR] $*" >&2
}

section() {
    if [[ "${QUIET}" == "false" ]]; then
        echo ""
        echo "=========================================="
        echo " $*"
        echo "=========================================="
    fi
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        err "This project requires macOS for iOS development."
        exit 1
    fi
    info "Running on macOS $(sw_vers -productVersion) ($(uname -m))"
}

# Install Homebrew if not present
install_homebrew() {
    section "Checking Homebrew"
    if command -v brew >/dev/null 2>&1; then
        info "Homebrew is installed: $(brew --version | head -1)"
        if [[ "${QUIET}" == "false" ]]; then
            info "Updating Homebrew..."
            brew update --quiet || warn "Failed to update Homebrew"
        fi
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

# Install and validate Xcode
setup_xcode() {
    section "Setting up Xcode"

    # Check for Xcode installation
    if ! xcode-select -p >/dev/null 2>&1; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true
        warn "Please complete the Xcode Command Line Tools installation and re-run this script."
        exit 1
    fi

    info "Xcode developer path: $(xcode-select -p)"

    # Check xcodebuild availability
    if ! command -v xcodebuild >/dev/null 2>&1; then
        err "xcodebuild not found. Please install Xcode from the App Store."
        exit 1
    fi

    local current_version
    current_version="$(xcodebuild -version 2>&1 | head -1 || echo 'unknown')"
    info "Current Xcode: ${current_version}"

    # Verify Xcode version matches pinned version
    if [[ "${current_version}" != *"${XCODE_VERSION}"* ]]; then
        warn "Xcode version mismatch!"
        warn "Expected: ${XCODE_VERSION}, Current: ${current_version}"
        warn "Install Xcode ${XCODE_VERSION} from https://developer.apple.com/download/"
    else
        info "Xcode version matches expected version (${XCODE_VERSION})"
    fi

    # Accept Xcode license if needed
    if [[ "${SKIP_XCODE_LICENSE}" == "false" ]]; then
        info "Checking Xcode license..."
        sudo xcodebuild -license accept 2>/dev/null || warn "Could not accept Xcode license (may need sudo)"
    fi
}

# Set up iOS simulators
setup_simulators() {
    if [[ "${SKIP_SIMULATORS}" == "true" ]]; then
        info "Skipping simulator setup (--skip-simulators)"
        return
    fi

    section "Setting up iOS Simulators"

    if ! command -v xcrun >/dev/null 2>&1; then
        err "xcrun not available. Xcode may not be properly installed."
        exit 1
    fi

    # Check for simulator runtime
    local runtime_available=false
    if xcrun simctl list runtimes | grep -q "iOS ${SIM_OS}"; then
        runtime_available=true
        info "iOS ${SIM_OS} runtime is available"
    else
        warn "iOS ${SIM_OS} runtime not found"
        warn "Install via: Xcode > Settings > Platforms > iOS ${SIM_OS}"
    fi

    # Check for device
    if ${runtime_available}; then
        if xcrun simctl list devices "iOS ${SIM_OS}" 2>/dev/null | grep -q "${SIM_DEVICE}"; then
            info "${SIM_DEVICE} (iOS ${SIM_OS}) is available"
        else
            warn "${SIM_DEVICE} not found for iOS ${SIM_OS}"
        fi
    fi
}

# Install a tool via Homebrew if not present
install_brew_tool() {
    local tool_name=$1
    local formula=${2:-$1}

    if command -v "${tool_name}" >/dev/null 2>&1; then
        info "${tool_name} is installed: $(${tool_name} --version 2>&1 | head -1)"
    else
        info "Installing ${tool_name} via Homebrew..."
        brew install "${formula}" --quiet
        info "${tool_name} installed: $(${tool_name} --version 2>&1 | head -1)"
    fi
}

# Install SwiftLint
install_swiftlint() {
    section "Installing SwiftLint"
    if command -v swiftlint >/dev/null 2>&1; then
        info "SwiftLint is installed: $(swiftlint version)"
    else
        info "Installing SwiftLint via Homebrew..."
        brew install swiftlint --quiet
        info "SwiftLint installed: $(swiftlint version)"
    fi
}

# Install SwiftFormat
install_swiftformat() {
    section "Installing SwiftFormat"
    if command -v swiftformat >/dev/null 2>&1; then
        info "SwiftFormat is installed: $(swiftformat --version)"
    else
        info "Installing SwiftFormat via Homebrew..."
        brew install swiftformat --quiet
        info "SwiftFormat installed: $(swiftformat --version)"
    fi
}

# Install markdownlint
install_markdownlint() {
    section "Installing markdownlint"
    if command -v markdownlint >/dev/null 2>&1; then
        info "markdownlint is installed: $(markdownlint --version)"
    else
        # Check for Node.js
        if ! command -v npm >/dev/null 2>&1; then
            info "Installing Node.js via Homebrew..."
            brew install node --quiet
        fi
        info "Installing markdownlint-cli via npm..."
        npm install -g markdownlint-cli --silent
        info "markdownlint installed: $(markdownlint --version)"
    fi
}

# Print environment summary
print_summary() {
    section "Environment Summary"

    cat <<EOF

System:
  macOS: $(sw_vers -productVersion)
  Architecture: $(uname -m)

Development Tools:
  Xcode: $(xcodebuild -version 2>&1 | head -1 || echo 'not installed')
  Swift: $(swift --version 2>&1 | head -1 || echo 'not installed')
  SwiftLint: $(swiftlint version 2>/dev/null || echo 'not installed')
  SwiftFormat: $(swiftformat --version 2>/dev/null || echo 'not installed')
  markdownlint: $(markdownlint --version 2>/dev/null || echo 'not installed')

Expected Environment:
  Xcode: ${XCODE_VERSION}
  Simulator: ${SIM_DEVICE} (iOS ${SIM_OS})

Project Paths:
  Repository: ${REPO_ROOT}
  iOS Project: ${REPO_ROOT}/ios/Offload.xcodeproj

Quick Commands:
  Build:  ./scripts/ios/build.sh
  Test:   ./scripts/ios/test.sh
  Lint:   swiftlint lint --path ios/
  Format: swiftformat ios/
  Open:   open ios/Offload.xcodeproj

EOF
}

main() {
    info "Offload Development Environment Setup"
    info "======================================"

    check_macos
    install_homebrew
    setup_xcode
    setup_simulators
    install_swiftlint
    install_swiftformat
    install_markdownlint

    if [[ "${QUIET}" == "false" ]]; then
        print_summary
    fi

    info "Environment setup complete!"
}

main "$@"
