#!/usr/bin/env python3

import subprocess
import os
from datetime import datetime
from rich.console import Console
from rich.theme import Theme

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

KERNEL_SOURCE_DIR = "/linux-kernel"

def timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def configure_kernel():
    console.print(f"[{timestamp()}][section]Configuring kernel...", style="section")
    try:
        console.print(f"[{timestamp()}][info]Current working directory: {os.getcwd()}", style="info")
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Configuring Kernel..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        process = subprocess.Popen(["make", "clean", "&&", "make", "defconfig", "FORCE_UNSAFE_CONFIGURE=1"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, cwd=KERNEL_SOURCE_DIR, shell=True)
        stdout, stderr = process.communicate()
        spinner_process.terminate()

        if stdout:
            console.print(stdout.replace("[", r"\[").replace("]", r"\]"))
        if stderr:
            console.print(f"[warning]{stderr.replace('[', r'\[').replace(']', r'\]')}[/warning]")

        if process.returncode != 0:
            escaped_stderr = stderr.replace("[", r"\[").replace("]", r"\]") if stderr else "Make defconfig failed"
            console.print(f"[{timestamp()}][error]Error configuring kernel:\n{escaped_stderr}", style="error")
            exit(1)

    except Exception as e:
        console.print(f"[{timestamp()}][error]Unexpected error configuring kernel:\n{e}", style="error")
        exit(1)

def build_kernel():
    console.print(f"[{timestamp()}][section]Building kernel and modules...", style="section")
    try:
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Building Kernel..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        process = subprocess.Popen(["make", "-j", str(os.cpu_count())], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, cwd=KERNEL_SOURCE_DIR)
        process.wait()
        spinner_process.terminate()

        if process.returncode != 0:
            console.print(f"[{timestamp()}][error]Error building kernel.", style="error")
            exit(1)
    except subprocess.CalledProcessError as e:
        console.print(f"[{timestamp()}][error]Error building kernel:\n{e}", style="error")
        exit(1)

def install_modules():
    console.print(f"[{timestamp()}][section]Installing modules...", style="section")
    try:
        spinner_process = subprocess.Popen(["gum", "spin", "--spinner", "dots", "--title", "Installing Modules..."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        result = subprocess.run(["sudo", "make", "modules_install", "INSTALL_MOD_STRIP=1"], capture_output=True, text=True, check=True, cwd=KERNEL_SOURCE_DIR)
        spinner_process.terminate()

        console.print(result.stdout)
        if result.stderr:
            console.print(f"[warning]{result.stderr}[/warning]")
    except subprocess.CalledProcessError as e:
        console.print(f"[{timestamp()}][error]Error installing modules:\n{e}", style="error")
        exit(1)

if __name__ == "__main__":
    console.print(f"[{timestamp()}][section]Starting Linux Kernel Build Process[/section]", style="section")

    configure_kernel()
    build_kernel()
    install_modules()

    console.print(f"[{timestamp()}][success]Kernel build and module installation complete! ✨[/success]", style="success")