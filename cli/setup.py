"""Setuptools shim for editable installs on older toolchains.

Modern installs use pyproject.toml (PEP 621). This file exists so that
``pip install -e .`` works on hosts where setuptools cannot yet parse
pyproject's ``[project]`` table.
"""
from setuptools import setup

setup()
