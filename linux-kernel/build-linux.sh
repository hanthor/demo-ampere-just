#!/bin/bash

# ANSI Color Codes - More vibrant palette
RED='\033[1;31m'       # Bold Red
GREEN='\033[1;32m'     # Bold Green
YELLOW='\033[1;33m'    # Bold Yellow
BLUE='\033[1;34m'      # Bold Blue
MAGENTA='\033[1;35m'   # Bold Magenta
CYAN='\033[1;36m'      # Bold Cyan
WHITE='\033[1;37m'     # Bold White
NC='\033[0m'          # No Color

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

KERNEL_SOURCE_DIR="linux-kernel"
KERNEL_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"

# Function to check if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# Install a package using a suitable package manager
install_package () {
  local package="$1"
  echo "$(timestamp) ${YELLOW}Attempting to install ${package}...${NC}"
  if command_exists apt-get; then
    sudo apt-get update && sudo apt-get install -y "$package"
  elif command_exists yum; then
    sudo yum install -y "$package"
  elif command_exists dnf; then
    sudo dnf install -y "$package"
  elif command_exists brew; then
    brew install "$package"
  elif command_exists go; then # gum is often installed via Go
    go install github.com/charmbracelet/gum@latest
  else
    echo "$(timestamp) ${RED}No suitable package manager or Go installation found to install ${package}. Please install it manually.${NC}"
    exit 1
  fi
}

# Check and install gum
if ! command_exists gum; then
  echo "$(timestamp) ${YELLOW}gum not found. Installing for beautiful output...${NC}"
  install_package gum
fi

# Clone or pull the kernel source
if [ ! -d "$KERNEL_SOURCE_DIR" ]; then
    echo "$(timestamp) ${GREEN}Cloning kernel source (depth 1)...${NC}"
    git clone --depth 1 "$KERNEL_REPO" "$KERNEL_SOURCE_DIR" | gum progress --title "${BLUE}Cloning Kernel${NC}"
else
    echo "$(timestamp) ${GREEN}Kernel source already exists. Pulling latest changes...${NC}"
    pushd "$KERNEL_SOURCE_DIR"
    git pull 2>&1 | gum spin --spinner "dots" --title "${CYAN}Pulling Changes${NC}"
    popd
fi

pushd "$KERNEL_SOURCE_DIR"

echo "$(timestamp) ${YELLOW}Configuring kernel...${NC}"
make defconfig

echo "$(timestamp) ${RED}Building kernel and modules...${NC}"
echo "$(timestamp) ${MAGENTA}This might take a while. Throbber active...${NC}"
make -j$(nproc) 2>&1 | gum spin --spinner "moon" --title "${YELLOW}Building Kernel${NC}"

echo "$(timestamp) ${GREEN}Installing modules...${NC}"
echo "$(timestamp) ${BLUE}Installing modules. Throbber active...${NC}"
sudo make modules_install INSTALL_MOD_STRIP=1 | gum spin --spinner "pulse" --title "${GREEN}Installing Modules${NC}"

echo "$(timestamp) ${GREEN}Kernel build and module installation complete. It's glowing with gum! ✨${NC}"

popd