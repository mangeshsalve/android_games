"""Generates the game's sound effects as small 16-bit mono WAV files.

All sounds are synthesised from sine/triangle waves, so there are no
third-party or copyrighted assets. Run from the project root:

    python3 tool/generate_sounds.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT_DIR = os.path.join("assets", "audio")


def write(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767 * 0.9))
            for s in samples
        )
        f.writeframes(frames)
    print("wrote", path)


def envelope(i, n, attack=0.004, decay=8.0):
    t = i / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * math.exp(-decay * t / (n / RATE))


def place():
    # Soft wooden "tock": low sine with a quick pitch drop and a click.
    n = int(RATE * 0.12)
    rnd = random.Random(1)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        freq = 260 + 180 * math.exp(-t * 60)
        phase += 2 * math.pi * freq / RATE
        click = rnd.uniform(-1, 1) * math.exp(-t * 400) * 0.3
        out.append((math.sin(phase) * 0.8 + click) * envelope(i, n, 0.002, 5))
    return out


def chime(freq):
    # Bell-like tone: fundamental plus a quiet octave and fifth.
    n = int(RATE * 0.45)
    out = []
    for i in range(n):
        t = i / RATE
        s = (
            math.sin(2 * math.pi * freq * t)
            + 0.35 * math.sin(2 * math.pi * freq * 2 * t)
            + 0.15 * math.sin(2 * math.pi * freq * 3 * t)
        ) / 1.5
        out.append(s * envelope(i, n, 0.003, 6))
    return out


def fail():
    # Descending triangle sweep.
    n = int(RATE * 0.5)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        freq = 330 * math.exp(-t * 2.2)
        phase += freq / RATE
        tri = 4 * abs((phase % 1.0) - 0.5) - 1
        out.append(tri * 0.7 * envelope(i, n, 0.005, 3.5))
    return out


if __name__ == "__main__":
    write("place.wav", place())
    # Major pentatonic scale: C5 D5 E5 G5 A5 C6.
    for idx, f in enumerate([523.25, 587.33, 659.25, 783.99, 880.0, 1046.5], 1):
        write(f"perfect_{idx}.wav", chime(f))
    write("fail.wav", fail())
