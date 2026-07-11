"""
Build the SWIG/CMake native extensions before setuptools scans packages.

Why?

setuptools runs build_py before build_ext. Since SWIG generates Python files
inside python/algokit_ds/_swig/, those files must already exist before
build_py starts collecting packages for the wheel.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from setuptools import setup
from setuptools.dist import Distribution

ROOT = Path(__file__).resolve().parent


class BinaryDistribution(Distribution):
    """Mark wheel as platform specific."""

    def has_ext_modules(self):
        return True


def run_checked(cmd, description):
    print(f"\n=== {description} ===")
    print("Command:", " ".join(map(str, cmd)))

    result = subprocess.run(
        cmd,
        cwd=ROOT,
        capture_output=True,
        text=True,
    )

    print("Return code:", result.returncode)

    if result.stdout:
        print("----- stdout -----")
        print(result.stdout)

    if result.stderr:
        print("----- stderr -----")
        print(result.stderr)

    if result.returncode != 0:
        raise RuntimeError(
            f"{description} failed.\n"
            f"Command: {' '.join(map(str, cmd))}"
        )


def check_required_tools():
    cmake = shutil.which("cmake")
    swig = shutil.which("swig")

    if cmake is None:
        raise RuntimeError(
            "CMake executable not found in PATH.\n"
            "Install CMake >= 3.16."
        )

    if swig is None:
        raise RuntimeError(
            "SWIG executable not found in PATH.\n"
            "Install SWIG >= 4.0."
        )

    run_checked([cmake, "--version"], "Checking CMake")
    run_checked([swig, "-version"], "Checking SWIG")


def build_native_extensions():
    check_required_tools()

    build_dir = ROOT / "build"
    build_dir.mkdir(exist_ok=True)

    cmake_args = [
        "-DCMAKE_BUILD_TYPE=Release",
        f"-DPython3_EXECUTABLE={sys.executable}",
    ]

    run_checked(
        [
            "cmake",
            "-S",
            str(ROOT),
            "-B",
            str(build_dir),
            *cmake_args,
        ],
        "Configuring CMake",
    )

    run_checked(
        [
            "cmake",
            "--build",
            str(build_dir),
            "-j",
            str(os.cpu_count() or 2),
        ],
        "Building extensions",
    )


_SKIP_COMMANDS = {
    "--help",
    "--help-commands",
    "egg_info",
    "dist_info",
    "clean",
}


if not any(arg in _SKIP_COMMANDS for arg in sys.argv):
    build_native_extensions()


setup(distclass=BinaryDistribution)