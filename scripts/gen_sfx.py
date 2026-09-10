#!/usr/bin/env python3
import math
import os
import random
import struct
import sys
import wave

SR = 44100


def write_wav(path, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    norm = 0.82 / peak
    clipped = (int(max(-1.0, min(1.0, s * norm)) * 32767) for s in samples)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", v) for v in clipped))


def mix(buf, start_s, samples, gain=1.0):
    off = int(start_s * SR)
    need = off + len(samples)
    if len(buf) < need:
        buf.extend([0.0] * (need - len(buf)))
    for i, s in enumerate(samples):
        buf[off + i] += s * gain


def note(freq, dur, decay, harmonics=((1, 1.0), (2, 0.38), (3, 0.14), (4, 0.06))):
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1.0, t / 0.004) * math.exp(-t / decay)
        s = sum(a * math.sin(2 * math.pi * freq * h * t) for h, a in harmonics)
        out.append(s * env)
    return out


def sweep(f0, f1, dur, decay, vol=1.0):
    n = int(dur * SR)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (t / dur)
        phase += 2 * math.pi * f / SR
        env = min(1.0, t / 0.01) * math.exp(-t / decay)
        out.append(math.sin(phase) * env * vol)
    return out


def gen_press():
    n = int(0.07 * SR)
    out = []
    for i in range(n):
        t = i / SR
        f = 1500 - 6000 * t
        env = math.exp(-t / 0.016)
        s = math.sin(2 * math.pi * max(400, f) * t)
        out.append(0.5 * s * env)
    return out


def gen_reveal():
    n = int(0.06 * SR)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1.0, t / 0.003) * math.exp(-t / 0.018)
        s = math.sin(2 * math.pi * 520 * t) * 0.6 + math.sin(2 * math.pi * 780 * t) * 0.25
        out.append(s * env * 0.12)
    return out


def gen_unlock():
    rng = random.Random(2026)
    buf = []

    arp = [
        (523.25, 0.00),
        (659.25, 0.09),
        (783.99, 0.18),
        (1046.50, 0.27),
        (1318.51, 0.38),
    ]
    for freq, at in arp:
        mix(buf, at, note(freq, 1.3, 0.30), 0.9)

    mix(buf, 0.0, sweep(130.81, 261.63, 1.1, 0.55), 0.35)

    for _ in range(9):
        f = rng.uniform(2093, 4699)
        at = rng.uniform(0.55, 1.35)
        mix(buf, at, note(f, 0.5, 0.09, ((1, 1.0),)), 0.16)

    mix(buf, 0.85, note(1567.98, 1.4, 0.45), 0.5)

    n = int(2.4 * SR)
    if len(buf) < n:
        buf.extend([0.0] * (n - len(buf)))
    buf = buf[:n]
    fade = int(0.25 * SR)
    for i in range(fade):
        idx = n - fade + i
        buf[idx] *= 1 - i / fade
    return buf


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    write_wav(os.path.join(out_dir, "press.wav"), gen_press())
    write_wav(os.path.join(out_dir, "reveal.wav"), gen_reveal())
    write_wav(os.path.join(out_dir, "unlock.wav"), gen_unlock())


if __name__ == "__main__":
    main()
