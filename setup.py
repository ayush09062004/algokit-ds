import os
import shutil
import subprocess
import sys
from pathlib import Path

def build_native_extensions():
    print("=" * 60)
    print("Debug information")
    print("=" * 60)
    print("Python executable :", sys.executable)
    print("Python version    :", sys.version)
    print("PATH              :", os.environ.get("PATH"))
    print("which cmake       :", shutil.which("cmake"))
    print("which swig        :", shutil.which("swig"))

    # Verify CMake
    subprocess.run(["cmake", "--version"], check=True)

    build_dir = ROOT / "build"
    build_dir.mkdir(exist_ok=True)

    cmake_args = [
        "-DCMAKE_BUILD_TYPE=Release",
        f"-DPython3_EXECUTABLE={sys.executable}",
    ]

    print("=" * 60)
    print("Running CMake configure")
    print("=" * 60)

    subprocess.run(
        ["cmake", "-S", str(ROOT), "-B", str(build_dir), *cmake_args],
        check=True,
    )

    print("=" * 60)
    print("Building")
    print("=" * 60)

    subprocess.run(
        ["cmake", "--build", str(build_dir), "-j", str(os.cpu_count() or 2)],
        check=True,
    )