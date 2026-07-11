"""
Builds the SWIG/CMake C++ extensions as part of `pip install`.

IMPORTANT: this runs the CMake build *before* calling setup(), not inside
a build_ext override. setuptools' default `build` command runs build_py
(which collects package .py files into the wheel) before build_ext (which
would normally drive this kind of native build) -- so a build_ext-based
approach silently ships a wheel missing the entire generated
algokit_ds._swig subpackage, since those files don't exist yet when
build_py scans the source tree. Building eagerly here guarantees the
generated .py wrappers and compiled .so files already exist on disk by
the time setuptools looks for them.
"""

import os
import subprocess
import sys
from pathlib import Path

from setuptools import setup
from setuptools.dist import Distribution

ROOT = Path(__file__).parent.resolve()


class BinaryDistribution(Distribution):
    """Tells setuptools/wheel this package contains compiled, platform-
    specific binaries (the SWIG .so files), so the resulting wheel is
    tagged e.g. cp312-cp312-linux_x86_64 instead of the incorrect
    py3-none-any it would otherwise pick since there's no ext_modules
    list driving the native build."""

    def has_ext_modules(self):
        return True


def build_native_extensions():
    try:
        subprocess.run(["cmake", "--version"], check=True, capture_output=True)
    except (OSError, subprocess.CalledProcessError) as exc:
        raise RuntimeError(
            "CMake must be installed to build algokit-ds "
            "(the SWIG/C++ layer is compiled at install time). "
            "Install CMake >= 3.16 and SWIG >= 4.0 and try again."
        ) from exc

    build_dir = ROOT / "build"
    build_dir.mkdir(exist_ok=True)

    cmake_args = [
        "-DCMAKE_BUILD_TYPE=Release",
        f"-DPython3_EXECUTABLE={sys.executable}",
    ]
    subprocess.run(
        ["cmake", "-S", str(ROOT), "-B", str(build_dir), *cmake_args],
        check=True,
    )
    subprocess.run(
        ["cmake", "--build", str(build_dir), "-j", str(os.cpu_count() or 2)],
        check=True,
    )


# Skip the native build for commands that don't need it (e.g. `--help`,
# `egg_info` alone) but run it for anything that actually produces a
# package (build, bdist_wheel, install, develop, ...).
_SKIP_FOR = {"--help", "--help-commands", "egg_info", "dist_info"}
if not _SKIP_FOR.intersection(sys.argv):
    build_native_extensions()

setup(distclass=BinaryDistribution)
