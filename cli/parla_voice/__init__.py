"""parla-voice — voice dictation CLI: hotkey → record → transcribe → type.

Local-first speech-to-text built on faster-whisper. A persistent daemon keeps
the Whisper model loaded so dictations after the first one are immediate.

Public entry point: the ``parla`` console script (see ``parla_voice.cli``).
"""

__version__ = "0.1.0"
__all__ = ["__version__"]
