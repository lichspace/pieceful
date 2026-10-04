"""Generate the game's warm tonal accents alongside the licensed UI foley."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "ShiguangPuzzle" / "Resources" / "Audio"
RATE = 44_100


def write_wav(name: str, samples: list[float]) -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    destination = ROOT / name
    with wave.open(str(destination), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, sample)) * 32767))
            for sample in samples
        )
        stream.writeframes(frames)


def bell_tone(frequency: float, duration: float, volume: float = 0.2) -> list[float]:
    count = int(RATE * duration)
    result: list[float] = []
    for index in range(count):
        elapsed = index / RATE
        attack = min(1.0, elapsed / 0.004)
        decay = math.exp(-4.8 * elapsed / duration)
        release = min(1.0, (count - index) / (RATE * 0.012))
        phase = 2 * math.pi * frequency * elapsed
        # A few quiet partials give the notes a soft bell quality instead of
        # the sharp electronic beep of a single sine wave.
        harmonics = (
            0.78 * math.sin(phase)
            + 0.16 * math.sin(phase * 2.01)
            + 0.06 * math.sin(phase * 3.97)
        )
        result.append(volume * attack * decay * release * harmonics)
    return result


def silence(duration: float) -> list[float]:
    return [0.0] * int(RATE * duration)


def concat(*parts: list[float]) -> list[float]:
    result: list[float] = []
    for part in parts:
        result.extend(part)
    return result


write_wav(
    "snap.wav",
    concat(
        bell_tone(659.25, 0.09, 0.10),
        silence(0.018),
        bell_tone(783.99, 0.13, 0.085),
    ),
)
write_wav(
    "complete.wav",
    concat(
        bell_tone(523.25, 0.12, 0.105),
        silence(0.025),
        bell_tone(659.25, 0.12, 0.10),
        silence(0.025),
        bell_tone(783.99, 0.14, 0.095),
        silence(0.035),
        bell_tone(1046.5, 0.30, 0.085),
    ),
)
