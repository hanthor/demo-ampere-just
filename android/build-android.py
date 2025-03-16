#!/usr/bin/env python3

import subprocess
import os
import time
from datetime import datetime
import urllib.request

ANDROID_REPO = "https://android.googlesource.com/platform/manifest"
ANDROID_VERSION = "android-15.0.0_r22"
ANDROID_BUILD_DIR = "android_source"
NUM_CORES = os.cpu_count() or 1  # Get CPU core count
REPO_BIN_DIR = os.path.expanduser("~/.local/bin")
REPO_PATH = os.path.join(REPO_BIN_DIR, "repo")

# ANSI escape codes for colors
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def run_command(command, cwd=None, shell=False):
    print(f"{Colors.OKBLUE}[{timestamp()}] Running: {' '.join(command) if isinstance(command, list) else command}{Colors.ENDC}")
    try:
        process = subprocess.run(command, cwd=cwd, shell=shell, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        print(process.stdout)
        return process.stdout
    except subprocess.CalledProcessError as e:
        print(f"{Colors.FAIL}[ERROR] Command failed: {e}{Colors.ENDC}")
        print(e.output)
        exit(1)

def install_repo():
    if not os.path.exists(REPO_BIN_DIR):
        os.makedirs(REPO_BIN_DIR)

    if not os.path.exists(REPO_PATH):
        print(f"{Colors.OKGREEN}[{timestamp()}] Installing repo...{Colors.ENDC}")
        urllib.request.urlretrieve("https://storage.googleapis.com/git-repo-downloads/repo", REPO_PATH)
        os.chmod(REPO_PATH, 0o755) # make executable
        print(f"{Colors.OKGREEN}[{timestamp()}] Repo installed to {REPO_PATH}{Colors.ENDC}")

        # Add ~/.local/bin to PATH (if not already there)
        if REPO_BIN_DIR not in os.environ["PATH"]:
            os.environ["PATH"] = REPO_BIN_DIR + ":" + os.environ["PATH"]
            print(f"{Colors.WARNING}[{timestamp()}] Added {REPO_BIN_DIR} to PATH. You may need to source your shell config.{Colors.ENDC}")
    else:
        print(f"{Colors.OKGREEN}[{timestamp()}] Repo already installed at {REPO_PATH}{Colors.ENDC}")

def download_android():
    if not os.path.exists(ANDROID_BUILD_DIR):
        os.makedirs(ANDROID_BUILD_DIR)

    if not os.path.exists(os.path.join(ANDROID_BUILD_DIR, ".repo")):
        run_command([REPO_PATH, "init", "-u", ANDROID_REPO, "-b", ANDROID_VERSION], cwd=ANDROID_BUILD_DIR)
        run_command([REPO_PATH, "sync", "-j", str(NUM_CORES)], cwd=ANDROID_BUILD_DIR)
    else:
        print(f"{Colors.OKGREEN}[{timestamp()}] Repo already initialized. Syncing...{Colors.ENDC}")
        run_command([REPO_PATH, "sync", "-j", str(NUM_CORES)], cwd=ANDROID_BUILD_DIR)

def build_android():
    run_command("source build/envsetup.sh", cwd=ANDROID_BUILD_DIR, shell=True)
    run_command(["lunch", "aosp_arm64-userdebug"], cwd=ANDROID_BUILD_DIR, shell=True) # change lunch target as needed.
    run_command(["make", "-j", str(NUM_CORES)], cwd=ANDROID_BUILD_DIR)

if __name__ == "__main__":
    print(f"{Colors.HEADER}[{timestamp()}] Starting Android build process...{Colors.ENDC}")
    start_time = time.time()

    install_repo()
    download_android()
    build_android()

    end_time = time.time()
    elapsed_time = end_time - start_time
    print(f"{Colors.HEADER}[{timestamp()}] Android build completed in {elapsed_time:.2f} seconds.{Colors.ENDC}")
