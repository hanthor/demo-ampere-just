#!/usr/bin/env python3

import subprocess
import os
import time
from datetime import datetime
from rich.console import Console
import urllib.request

console = Console()

ANDROID_REPO = "https://android.googlesource.com/platform/manifest"
ANDROID_VERSION = "android-15.0.0_r22"
ANDROID_BUILD_DIR = "android_source"
NUM_CORES = os.cpu_count() or 1  # Get CPU core count
REPO_BIN_DIR = os.path.expanduser("~/.local/bin")
REPO_PATH = os.path.join(REPO_BIN_DIR, "repo")

def timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def run_command(command, cwd=None, shell=False):
    console.print(f"[{timestamp()}] Running: {' '.join(command) if isinstance(command, list) else command}")
    try:
        process = subprocess.run(command, cwd=cwd, shell=shell, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        console.print(process.stdout)
        return process.stdout
    except subprocess.CalledProcessError as e:
        console.print(f"[ERROR] Command failed: {e}")
        console.print(e.output)
        exit(1)

def install_repo():
    if not os.path.exists(REPO_BIN_DIR):
        os.makedirs(REPO_BIN_DIR)

    if not os.path.exists(REPO_PATH):
        console.print(f"[{timestamp()}] Installing repo...")
        urllib.request.urlretrieve("https://storage.googleapis.com/git-repo-downloads/repo", REPO_PATH)
        os.chmod(REPO_PATH, 0o755) # make executable
        console.print(f"[{timestamp()}] Repo installed to {REPO_PATH}")

        # Add ~/.local/bin to PATH (if not already there)
        if REPO_BIN_DIR not in os.environ["PATH"]:
            os.environ["PATH"] = REPO_BIN_DIR + ":" + os.environ["PATH"]
            console.print(f"[{timestamp()}] Added {REPO_BIN_DIR} to PATH. You may need to source your shell config.")
    else:
        console.print(f"[{timestamp()}] Repo already installed at {REPO_PATH}")

def download_android():
    if not os.path.exists(ANDROID_BUILD_DIR):
        os.makedirs(ANDROID_BUILD_DIR)

    if not os.path.exists(os.path.join(ANDROID_BUILD_DIR, ".repo")):
        run_command([REPO_PATH, "init", "-u", ANDROID_REPO, "-b", ANDROID_VERSION], cwd=ANDROID_BUILD_DIR)
        run_command([REPO_PATH, "sync", "-j", str(NUM_CORES)], cwd=ANDROID_BUILD_DIR)
    else:
        console.print(f"[{timestamp()}] Repo already initialized. Syncing...")
        run_command([REPO_PATH, "sync", "-j", str(NUM_CORES)], cwd=ANDROID_BUILD_DIR)

def build_android():
    run_command(["source", "build/envsetup.sh"], cwd=ANDROID_BUILD_DIR, shell=True)
    run_command(["lunch", "aosp_cf_x86_64-userdebug"], cwd=ANDROID_BUILD_DIR, shell=True) # change lunch target as needed.
    run_command(["make", "-j", str(NUM_CORES)], cwd=ANDROID_BUILD_DIR)

if __name__ == "__main__":
    console.print(f"[{timestamp()}] Starting Android build process...")
    start_time = time.time()

    install_repo()
    download_android()
    build_android()

    end_time = time.time()
    elapsed_time = end_time - start_time
    console.print(f"[{timestamp()}] Android build completed in {elapsed_time:.2f} seconds.")