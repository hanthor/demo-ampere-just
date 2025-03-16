#!/bin/bash

# Constants
ANDROID_REPO="https://android.googlesource.com/platform/manifest"
ANDROID_VERSION="android-15.0.0_r22"
ANDROID_BUILD_DIR="android_source"
NUM_CORES=$(nproc || echo 1)  # Get CPU core count or default to 1
REPO_BIN_DIR="$HOME/.local/bin"
REPO_PATH="$REPO_BIN_DIR/repo"
LAST_SYNC_FILE="../.$(basename "$ANDROID_BUILD_DIR")_last_sync"  # File to store the last sync timestamp

# ANSI escape codes for colors
COLOR_HEADER='\033[95m'
COLOR_OKBLUE='\033[94m'
COLOR_OKCYAN='\033[96m'
COLOR_OKGREEN='\033[92m'
COLOR_WARNING='\033[93m'
COLOR_FAIL='\033[91m'
COLOR_ENDC='\033[0m'
COLOR_BOLD='\033[1m'
COLOR_UNDERLINE='\033[4m'

# Function to get a timestamp
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

# Function to run a command and handle errors
run_command() {
  local command="$1"
  local cwd="$2"
  local shell_opt="$3" # optional shell argument

  echo -e "${COLOR_OKBLUE}[$(timestamp)] Running: $command${COLOR_ENDC}"

  if [[ -n "$cwd" ]]; then
    if [[ "$shell_opt" == "true" ]]; then
      (cd "$cwd" && { . ./build/envsetup.sh; $command; }) 2>&1 | tee >(while read line; do echo "$line"; done) || {
          echo -e "${COLOR_FAIL}[ERROR] Command failed${COLOR_ENDC}"
          exit 1
      }
    else
      (cd "$cwd" && $command) 2>&1 | tee >(while read line; do echo "$line"; done) || {
            echo -e "${COLOR_FAIL}[ERROR] Command failed${COLOR_ENDC}"
            exit 1
      }
    fi
  else
    if [[ "$shell_opt" == "true" ]]; then
       bash -c "$command" 2>&1 | tee >(while read line; do echo "$line"; done) || {
            echo -e "${COLOR_FAIL}[ERROR] Command failed${COLOR_ENDC}"
             exit 1
       }
    else
      $command 2>&1 | tee >(while read line; do echo "$line"; done) || {
          echo -e "${COLOR_FAIL}[ERROR] Command failed${COLOR_ENDC}"
          exit 1
      }
    fi
  fi
}

# Function to install the 'repo' tool
install_repo() {
  if [[ ! -d "$REPO_BIN_DIR" ]]; then
    mkdir -p "$REPO_BIN_DIR"
  fi

  if [[ ! -f "$REPO_PATH" ]]; then
    echo -e "${COLOR_OKGREEN}[$(timestamp)] Installing repo...${COLOR_ENDC}"
    curl -o "$REPO_PATH" "https://storage.googleapis.com/git-repo-downloads/repo"
    chmod +x "$REPO_PATH"
    echo -e "${COLOR_OKGREEN}[$(timestamp)] Repo installed to $REPO_PATH${COLOR_ENDC}"

    # Add ~/.local/bin to PATH (if not already there) and persist
    if [[ ":$PATH:" != *":$REPO_BIN_DIR:"* ]]; then
      #Correctly add to PATH in various shell config files
      echo "export PATH=\"$REPO_BIN_DIR:\$PATH\"" >> "$HOME/.bashrc"
      echo "export PATH=\"$REPO_BIN_DIR:\$PATH\"" >> "$HOME/.profile"
      if [[ -f "$HOME/.zshrc" ]]; then
        echo "export PATH=\"$REPO_BIN_DIR:\$PATH\"" >> "$HOME/.zshrc"
      fi
      export PATH="$REPO_BIN_DIR:$PATH"
      echo -e "${COLOR_WARNING}[$(timestamp)] Added $REPO_BIN_DIR to PATH.  You may need to source your shell config or open a new terminal.${COLOR_ENDC}"
    fi
  else
    echo -e "${COLOR_OKGREEN}[$(timestamp)] Repo already installed at $REPO_PATH${COLOR_ENDC}"
  fi
}

# Function to download the Android source code
download_android() {
  if [[ ! -d "$ANDROID_BUILD_DIR" ]]; then
    mkdir -p "$ANDROID_BUILD_DIR"
  fi

  if [[ ! -d "$ANDROID_BUILD_DIR/.repo" ]]; then
    run_command "$REPO_PATH init -u $ANDROID_REPO -b $ANDROID_VERSION" "$ANDROID_BUILD_DIR"
    run_command "$REPO_PATH sync -j $NUM_CORES --no-tags --no-clone-bundle" "$ANDROID_BUILD_DIR"
    date +"%Y-%m-%d" > "$LAST_SYNC_FILE"  # Record the sync date
  else
    # Check if a sync was done today
    if [[ -f "$LAST_SYNC_FILE" ]] && [[ $(date +"%Y-%m-%d") == $(cat "$LAST_SYNC_FILE") ]]; then
      echo -e "${COLOR_OKGREEN}[$(timestamp)] Repo already synced today. Skipping sync...${COLOR_ENDC}"
    else
      echo -e "${COLOR_OKGREEN}[$(timestamp)] Syncing repo...${COLOR_ENDC}"
      run_command "$REPO_PATH sync -j $NUM_CORES --no-tags --no-clone-bundle" "$ANDROID_BUILD_DIR"
      date +"%Y-%m-%d" > "$LAST_SYNC_FILE"  # Update the sync date
    fi
  fi
}

# Function to build Android
build_android() {
    # First, run 'lunch' without arguments to see available options
    run_command "lunch" "$ANDROID_BUILD_DIR" "true"
    echo -e "${COLOR_WARNING}[$(timestamp)] Please select a valid lunch combo from the list above.{COLOR_ENDC}"
    echo -e "${COLOR_WARNING}[$(timestamp)] Example:  lunch aosp_arm-eng{COLOR_ENDC}"
    read -r -p "Enter lunch combo: " LUNCH_COMBO

    run_command "lunch $LUNCH_COMBO" "$ANDROID_BUILD_DIR" "true" # Use the user's choice.
    run_command "make -j $NUM_CORES" "$ANDROID_BUILD_DIR"
}

# Main script execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo -e "${COLOR_HEADER}[$(timestamp)] Starting Android build process...${COLOR_ENDC}"
  start_time=$(date +%s)

  install_repo
  download_android
  build_android

  end_time=$(date +%s)
  elapsed_time=$((end_time - start_time))
  echo -e "${COLOR_HEADER}[$(timestamp)] Android build completed in $elapsed_time seconds.${COLOR_ENDC}"
fi