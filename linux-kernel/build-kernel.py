#!/usr/bin/env python3

import subprocess
import shutil
import os
from datetime import datetime
from rich.console import Console
from rich.theme import Theme

# Define a custom theme
custom_theme = Theme({
    "info": "dim cyan",
    "warning": "yellow",
    "error": "bold red",
    "success": "green",
    "timestamp": "bold white",
    "section": "bold magenta",
    "step": "blue",
    "git_status": "cyan",
    "git_update": "green",
    "git_error": "red",
})

console = Console(theme=custom_theme)

KERNEL_SOURCE_DIR = "linux-kernel"
KERNEL_REPO = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"

def timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def check_command(command):
    return shutil.which(command) is not None

def install_package(package):
    console.print(f"[{timestamp()}][warning]Attempting to install {package}...", style="warning")
    try:
        if check_command("pipx"):
            subprocess.run(["pipx", "install", package], check=True)
            return True
        elif check_command("brew"):
            subprocess.run(["brew", "install", package], check=True)
            return True
        else:
            console.print(f"[{timestamp()}][error]pipx or brew not found. Please install {package} manually.", style="error")
            return False
    except subprocess.CalledProcessError as e:
        console.print(f"[{timestamp()}][error]Error installing {package}: {e}", style="error")
        return False

def run_gum(command, input_text=None):
    process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if input_text:
        stdout, stderr = process.communicate(input=input_text)
    else:
        stdout, stderr = process.communicate()
    return stdout, stderr, process.returncode

def check_and_update_kernel():
    if os.path.isdir(KERNEL_SOURCE_DIR):
        console.print(f"[{timestamp()}][section]Checking for kernel updates...", style="section")
        os.chdir(KERNEL_SOURCE_DIR)
        try:
            # Check if there are any updates
            status_process = subprocess.run(["git", "status"], capture_output=True, text=True)
            if "Your branch is up to date" in status_process.stdout:
                console.print(f"[{timestamp()}][git_status]Kernel source is up to date.[/git_status]", style="git_status")
            else:
                console.print(f"[{timestamp()}][git_status]Kernel source has updates. Fetching and pulling...", style="git_status")
                # Fetch and pull updates
                fetch_process = subprocess.run(["git", "fetch", "--all"], capture_output=True, text=True)
                pull_process = subprocess.run(["git", "pull"], capture_output=True, text=True)

                if pull_process.returncode == 0:
                    console.print(f"[{timestamp()}][git_update]Kernel source updated successfully.[/git_update]", style="git_update")
                else:
                    console.print(f"[{timestamp()}][git_error]Error updating kernel source:\n{pull_process.stderr}[/git_error]", style="git_error")
        except subprocess.CalledProcessError as e:
            console.print(f"[{timestamp()}][git_error]Error checking/updating kernel source:\n{e.stderr}[/git_error]", style="git_error")
        finally:
            os.chdir("..")

def clone_kernel():
    if not os.path.isdir(KERNEL_SOURCE_DIR):
        console.print(f"[{timestamp()}][success]Cloning kernel source (depth 1)...", style="success")
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Cloning Kernel..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        process = subprocess.Popen(
            ["git", "clone", "--depth", "1", KERNEL_REPO, KERNEL_SOURCE_DIR],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        process.wait()
        spinner_process.terminate()

        if process.returncode != 0:
            error_output = process.stderr.read()
            console.print(f"[{timestamp()}][error]Error cloning kernel:\n{error_output}", style="error")
            exit(1)
    else:
        check_and_update_kernel()

def configure_kernel():
    console.print(f"[{timestamp()}][section]Configuring kernel...", style="section")
    os.chdir(KERNEL_SOURCE_DIR)
    try:
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Configuring Kernel..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        process = subprocess.Popen(["make", "defconfig"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) # change to popen to read stderr.
        stdout, stderr = process.communicate()
        spinner_process.terminate()

        console.print(stdout.replace("[", r"\[").replace("]", r"\]"))
        if stderr:
            console.print(f"[warning]{stderr.replace('[', r'\[').replace(']', r'\]')}[/warning]")

        if process.returncode != 0:
            escaped_stderr = stderr.replace("[", r"\[").replace("]", r"\]")
            console.print(f"[{timestamp()}][error]Error configuring kernel:\n{escaped_stderr}", style="error")
            exit(1)

    except Exception as e:
        console.print(f"[{timestamp()}][error]Unexpected error configuring kernel:\n{e}", style="error")
        exit(1)

    finally:
        os.chdir("..")

def build_kernel():
    console.print(f"[{timestamp()}][section]Building kernel and modules...", style="section")
    os.chdir(KERNEL_SOURCE_DIR)
    try:
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Building Kernel..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        process = subprocess.Popen(["make", "-j", str(os.cpu_count())], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        process.wait()
        spinner_process.terminate()

        if process.returncode != 0:
            console.print(f"[{timestamp()}][error]Error building kernel.", style="error")
            exit(1)
    except subprocess.CalledProcessError as e:
        console.print(f"[{timestamp()}][error]Error building kernel:\n{e}", style="error")
        exit(1)
    finally:
        os.chdir("..")

def install_modules():
    console.print(f"[{timestamp()}][section]Installing modules...", style="section")
    os.chdir(KERNEL_SOURCE_DIR)
    try:
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Installing Modules..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        result = subprocess.run(["sudo", "make", "modules_install", "INSTALL_MOD_STRIP=1"], capture_output=True, text=True, check=True)
        spinner_process.terminate()

        console.print(result.stdout)
        if result.stderr:
            console.print(f"[warning]{result.stderr}[/warning]")
    except subprocess.CalledProcessError as e:
        console.print(f"[{timestamp()}][error]Error installing modules:\n{e}", style="error")
        exit(1)
    finally:
        os.chdir("..")

if __name__ == "__main__":
    console.print(f"[{timestamp()}][section]Starting Linux Kernel Build Process[/section]", style="section")
    if not check_command("gum"):
        if not install_package("gum"):
            exit(1)

    clone_kernel()
    configure_kernel()
    build_kernel()
    install_modules()

    console.print(f"[{timestamp()}][success]Kernel build and module installation complete! ✨[/success]", style="success")