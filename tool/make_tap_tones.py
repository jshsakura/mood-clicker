#!/usr/bin/env python3
"""Makes the sounds of the pentatonic pack: one kalimba note, C5, as assets/sounds/pentatonic/kalimba.wav, and the cleansing
sound of the release flow, a singing bowl, as assets/sounds/pentatonic/cleanse.wav.

The app plays it at a speed per tap (1.0, 1.122, 1.26, 1.498, 1.682, 2.0 is do re mi sol la do), so one clean
note is all it needs. The note is built from a sine with two soft overtones and a short, bright pluck, with a fast attack
and an exponential decay. Everything is made here, so there is nothing to license. Run it again for the same file.

Usage: python3 tool/make_tap_tones.py [out_dir]
Needs numpy.
"""
import sys
import wave
from pathlib import Path

import numpy as np

RATE = 44100
FUNDAMENTAL = 523.25  # C5
LENGTH = 0.32  # seconds
FADE = 0.03  # the last seconds fade out, so the cut never clicks
ATTACK = 0.002


def kalimba():
    t = np.arange(int(RATE * LENGTH)) / RATE
    # The partials of a tine are not whole multiples: the second is a little sharp, and a short
    # bright ping rides on top for the pluck.
    body = np.sin(2 * np.pi * FUNDAMENTAL * t) * np.exp(-t / 0.11)
    octave = 0.30 * np.sin(2 * np.pi * FUNDAMENTAL * 2.01 * t) * np.exp(-t / 0.07)
    ping = 0.12 * np.sin(2 * np.pi * FUNDAMENTAL * 5.4 * t) * np.exp(-t / 0.02)
    wave_ = body + octave + ping
    attack = np.minimum(t / ATTACK, 1.0)
    fade = np.minimum((LENGTH - t) / FADE, 1.0)
    wave_ = wave_ * attack * fade
    return wave_ / np.max(np.abs(wave_)) * 0.9


def bowl():
    """A singing bowl struck once: a slow swell, partials that are not whole multiples, a pair of
    close tones that beat slowly, and a long soft decay."""
    length = 2.6
    t = np.arange(int(RATE * length)) / RATE
    base = 196.0  # G3
    wave_ = (
        np.sin(2 * np.pi * base * t) * np.exp(-t / 1.1)
        + 0.8 * np.sin(2 * np.pi * base * 1.006 * t) * np.exp(-t / 1.0)
        + 0.35 * np.sin(2 * np.pi * base * 2.71 * t) * np.exp(-t / 0.7)
        + 0.15 * np.sin(2 * np.pi * base * 5.15 * t) * np.exp(-t / 0.4)
    )
    swell = np.minimum(t / 0.04, 1.0)
    fade = np.minimum((length - t) / 0.4, 1.0)
    wave_ = wave_ * swell * fade
    return wave_ / np.max(np.abs(wave_)) * 0.7


def write(path, samples):
    pcm = (samples * 32767).astype("<i2")
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(pcm.tobytes())


if __name__ == "__main__":
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "assets/sounds/pentatonic"
    folder.mkdir(parents=True, exist_ok=True)
    write(folder / "kalimba.wav", kalimba())
    write(folder / "cleanse.wav", bowl())
    print(f"wrote {folder / 'kalimba.wav'} and {folder / 'cleanse.wav'}")
