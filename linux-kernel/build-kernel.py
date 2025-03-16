#!/usr/bin/env python3

import subprocess
import os
from datetime import datetime

KERNEL_SOURCE_DIR = "linux-kernel/linux-kernel"

def timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def log(message, level="INFO"):
    print(f"[{timestamp()}][{level}] {message}")

def configure_kernel():
    log("Configuring kernel...", "SECTION")
    try:
        log(f"Current working directory: {os.getcwd()}", "INFO")
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Configuring Kernel..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        process = subprocess.Popen(["make", "clean", "&&", "make", "defconfig", "FORCE_UNSAFE_CONFIGURE=1"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, cwd=KERNEL_SOURCE_DIR, shell=True)
        stdout, stderr = process.communicate()
        spinner_process.terminate()

        if stdout:
            print(stdout)
        if stderr:
            log(stderr, "WARNING")

        if process.returncode != 0:
            log(f"Error configuring kernel:\n{stderr if stderr else 'Make defconfig failed'}", "ERROR")
            exit(1)

    except Exception as e:
        log(f"Unexpected error configuring kernel:\n{e}", "ERROR")
        exit(1)

def build_kernel():
    log("Building kernel and modules...", "SECTION")
    try:
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Building Kernel..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        process = subprocess.Popen(["make", "-j", str(os.cpu_count())], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, cwd=KERNEL_SOURCE_DIR)
        process.wait()
        spinner_process.terminate()

        if process.returncode != 0:
            log("Error building kernel.", "ERROR")
            exit(1)
    except subprocess.CalledProcessError as e:
        log(f"Error building kernel:\n{e}", "ERROR")
        exit(1)

def install_modules():
    log("Installing modules...", "SECTION")
    try:
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Installing Modules..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        result = subprocess.run(["sudo", "make", "modules_install", "INSTALL_MOD_STRIP=1"], capture_output=True, text=True, check=True, cwd=KERNEL_SOURCE_DIR)
        spinner_process.terminate()

        print(result.stdout)
        if result.stderr:
            log(result.stderr, "WARNING")
    except subprocess.CalledProcessError as e:
        log(f"Error installing modules:\n{e}", "ERROR")
        exit(1)

if __name__ == "__main__":
    log("Starting Linux Kernel Build Process", "SECTION")

    configure_kernel()
    build_kernel()
    install_modules()

    log("Kernel build and module installation complete! ✨", "SUCCESS")
