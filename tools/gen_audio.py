#!/usr/bin/env python3
"""Процедурная музыка и звуки Symphony (v35): спокойный эмбиент и мягкие UI-звуки.

  python3 tools/gen_audio.py      -> audio/music/*.ogg, audio/sfx/*.ogg  (нужны numpy и ffmpeg с libvorbis)

Свою музыку можно просто положить в audio/music/ (*.ogg): игра проигрывает все файлы папки по кругу.
"""
import os, subprocess, tempfile, wave
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SR = 32000
rng = np.random.default_rng(35)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def env_adsr(n, a, r):
    e = np.ones(n)
    na, nr = int(a * SR), int(r * SR)
    if na > 0:
        e[:na] = np.linspace(0, 1, na) ** 2
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr) ** 2
    return e


def pad_note(f, dur, amp=0.08):
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for det in (-0.12, 0.0, 0.11):            # лёгкая расстройка — «тёплый» тон
        ff = f * 2 ** (det / 12)
        for h, w in ((1, 1.0), (2, 0.28), (3, 0.10), (4, 0.04)):
            out += w * np.sin(2 * np.pi * ff * h * t + rng.uniform(0, 6.28))
    lfo = 0.85 + 0.15 * np.sin(2 * np.pi * 0.11 * t + rng.uniform(0, 6.28))
    return out * lfo * env_adsr(n, dur * 0.35, dur * 0.4) * amp / 3.0


def bell(f, dur=3.5, amp=0.06):
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for h, w, d in ((1, 1.0, 1.6), (2.0, 0.35, 0.9), (3.01, 0.15, 0.5), (4.2, 0.06, 0.3)):
        out += w * np.sin(2 * np.pi * f * h * t) * np.exp(-t / d)
    att = np.minimum(1.0, t / 0.012)
    return out * att * amp


def reverb(x, secs=2.8, mix=0.32):
    n = int(secs * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-t / (secs / 5.0))
    ir[0] = 0
    ir /= np.sqrt(np.sum(ir ** 2))
    L = len(x) + n
    m = 1 << int(np.ceil(np.log2(L)))
    wet = np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(ir, m), m)[:len(x)]
    return x * (1 - mix) + wet * mix * 0.9


def lowpass(x, fc):
    a = np.exp(-2 * np.pi * fc / SR)
    # одно-полюсный ФНЧ через свёртку с экспонентой (быстро для numpy)
    k = int(SR * 5 / fc) + 1
    ir = (1 - a) * a ** np.arange(k)
    m = 1 << int(np.ceil(np.log2(len(x) + k)))
    return np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(ir, m), m)[:len(x)]


def track(chords, scale, bar=8.0, cycles=3, bass=True, bell_rate=0.35):
    total = bar * len(chords) * cycles
    n = int((total + 4.0) * SR)
    L = np.zeros(n)
    R = np.zeros(n)
    for c in range(cycles):
        for i, ch in enumerate(chords):
            t0 = (c * len(chords) + i) * bar
            s = int(t0 * SR)
            for k, note in enumerate(ch):
                p = pad_note(midi(note), bar + 2.5, 0.07 if k else 0.05)
                pan = 0.35 + 0.3 * (k / max(1, len(ch) - 1))
                e = min(n, s + len(p))
                L[s:e] += p[:e - s] * (1 - pan)
                R[s:e] += p[:e - s] * pan
            if bass:
                b = pad_note(midi(ch[0] - 12), bar + 1.5, 0.06)
                e = min(n, s + len(b))
                L[s:e] += b[:e - s] * 0.5
                R[s:e] += b[:e - s] * 0.5
    # редкие колокольчики по гамме
    t = 2.0
    while t < total - 2.0:
        f = midi(rng.choice(scale) + 12 * int(rng.integers(0, 2)))
        b = bell(f, 4.0, 0.05 * rng.uniform(0.6, 1.0))
        s = int(t * SR)
        e = min(n, s + len(b))
        pan = rng.uniform(0.2, 0.8)
        L[s:e] += b[:e - s] * (1 - pan)
        R[s:e] += b[:e - s] * pan
        t += rng.exponential(1.0 / bell_rate) + 0.8
    L = reverb(lowpass(L, 3200))
    R = reverb(lowpass(R, 3200))
    st = np.stack([L, R], 1)
    fade = env_adsr(n, 3.0, 4.0)
    st *= fade[:, None]
    st /= max(1e-6, np.max(np.abs(st))) / 0.6
    return st


def sfx_tone(notes, dur=0.5, amp=0.35, gap=0.09, kind="bell"):
    n = int((dur + gap * len(notes) + 0.3) * SR)
    out = np.zeros(n)
    for i, f in enumerate(notes):
        b = bell(f, dur, amp) if kind == "bell" else pad_note(f, dur, amp * 2.5)
        s = int(i * gap * SR)
        out[s:s + len(b)] += b[:n - s]
    out = reverb(out, 1.2, 0.22)
    out /= max(1e-6, np.max(np.abs(out))) / 0.5
    return np.stack([out, out], 1)


def click():
    n = int(0.06 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * 1800 * t) * np.exp(-t / 0.008) + 0.3 * rng.standard_normal(n) * np.exp(-t / 0.003)
    x = lowpass(x, 5000)
    x /= np.max(np.abs(x)) / 0.25
    return np.stack([x, x], 1)


def arp_track(chords, bar=6.0, cycles=3, step=0.5, amp=0.045):
    """v50: «Минимализм» — арпеджио колокольчиками поверх тихой подложки."""
    total = bar * len(chords) * cycles
    n = int((total + 4.0) * SR)
    L = np.zeros(n)
    R = np.zeros(n)
    for c in range(cycles):
        for i, ch in enumerate(chords):
            t0 = (c * len(chords) + i) * bar
            s = int(t0 * SR)
            p = pad_note(midi(ch[0] - 12), bar + 1.5, 0.05)
            e = min(n, s + len(p))
            L[s:e] += p[:e - s] * 0.5
            R[s:e] += p[:e - s] * 0.5
            k = 0
            t = 0.0
            while t < bar - 0.1:
                note = ch[(k * 2 + c) % len(ch)] + (12 if k % 5 == 3 else 0)
                b = bell(midi(note), 2.2, amp * (0.8 + 0.2 * rng.uniform()))
                s2 = int((t0 + t) * SR)
                e2 = min(n, s2 + len(b))
                pan = 0.3 + 0.4 * ((k % 4) / 3.0)
                L[s2:e2] += b[:e2 - s2] * (1 - pan)
                R[s2:e2] += b[:e2 - s2] * pan
                k += 1
                t += step
    L = reverb(lowpass(L, 4200), 2.2, 0.28)
    R = reverb(lowpass(R, 4200), 2.2, 0.28)
    st = np.stack([L, R], 1)
    st *= env_adsr(n, 2.0, 4.0)[:, None]
    st /= max(1e-6, np.max(np.abs(st))) / 0.55
    return st


def click_soft():
    """v50: мягкий «деревянный» щелчок."""
    n = int(0.07 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * 620 * t) * np.exp(-t / 0.012) + 0.5 * np.sin(2 * np.pi * 1240 * t) * np.exp(-t / 0.006)
    x = lowpass(x, 2600)
    x /= np.max(np.abs(x)) / 0.22
    return np.stack([x, x], 1)


def click_key():
    """v50: короткий «клавишный» щелчок."""
    n = int(0.05 * SR)
    t = np.arange(n) / SR
    x = rng.standard_normal(n) * np.exp(-t / 0.0045) + 0.4 * np.sin(2 * np.pi * 3100 * t) * np.exp(-t / 0.004)
    x = lowpass(x, 7000)
    x /= np.max(np.abs(x)) / 0.2
    return np.stack([x, x], 1)


def write_ogg(st, path, q=3):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    pcm = (np.clip(st, -1, 1) * 32767).astype(np.int16)
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", str(q), path], check=True)
    os.unlink(tmp)
    print("  %s  %.0f КБ" % (os.path.relpath(path, ROOT), os.path.getsize(path) / 1024))


def main():
    md = os.path.join(ROOT, "audio/music")
    sd = os.path.join(ROOT, "audio/sfx")
    os.makedirs(md, exist_ok=True)
    os.makedirs(sd, exist_ok=True)
    print("Музыка:")
    # «Кабинет»: C — Am — F — G, мягко и нейтрально
    write_ogg(track([[48, 55, 64, 71], [45, 52, 60, 67], [41, 48, 57, 64], [43, 50, 59, 64]], [60, 62, 64, 67, 69], 8.0, 3), os.path.join(md, "01_kabinet.ogg"))
    # «Совет»: D-дорийский, медленнее
    write_ogg(track([[50, 57, 64, 65], [43, 55, 62, 65], [46, 53, 62, 69], [45, 52, 60, 64]], [62, 64, 65, 69, 71], 9.0, 3, bell_rate=0.25), os.path.join(md, "02_sovet.ogg"))
    # «Вечер»: Am — Fmaj7 — C — Em7
    write_ogg(track([[45, 52, 60, 71], [41, 48, 57, 64], [48, 55, 64, 67], [40, 47, 55, 62]], [57, 60, 62, 64, 67], 8.0, 3, bell_rate=0.3), os.path.join(md, "03_vecher.ogg"))
    print("Звуки:")
    write_ogg(click(), os.path.join(sd, "click.ogg"), 4)
    write_ogg(sfx_tone([midi(76), midi(83)], 0.9, 0.3, 0.12), os.path.join(sd, "event.ogg"), 4)
    write_ogg(sfx_tone([midi(72), midi(76), midi(79), midi(84)], 1.4, 0.3, 0.16), os.path.join(sd, "election.ogg"), 4)
    write_ogg(sfx_tone([midi(72), midi(79)], 0.8, 0.28, 0.1), os.path.join(sd, "good.ogg"), 4)
    write_ogg(sfx_tone([midi(57), midi(56)], 0.9, 0.25, 0.14, "pad"), os.path.join(sd, "bad.ogg"), 4)
    write_ogg(sfx_tone([midi(81)], 0.35, 0.18, 0.0), os.path.join(sd, "tick.ogg"), 4)


def main_v50():
    """v50: второй набор музыки («Минимализм», audio/music_b) и варианты щелчка кнопок."""
    mb = os.path.join(ROOT, "audio/music_b")
    sd = os.path.join(ROOT, "audio/sfx")
    os.makedirs(mb, exist_ok=True)
    print("Музыка (минимализм):")
    write_ogg(arp_track([[57, 60, 64, 67], [53, 57, 60, 64], [48, 52, 55, 59], [55, 59, 62, 65]], 6.0, 3, 0.5), os.path.join(mb, "01_utro.ogg"))
    write_ogg(arp_track([[50, 53, 57, 60], [46, 50, 53, 57], [43, 47, 50, 55], [45, 49, 52, 57]], 7.0, 3, 0.58), os.path.join(mb, "02_doklad.ogg"))
    print("Звуки кнопок:")
    write_ogg(click_soft(), os.path.join(sd, "click_soft.ogg"), 4)
    write_ogg(click_key(), os.path.join(sd, "click_key.ogg"), 4)


if __name__ == "__main__":
    import sys
    if "--v50" in sys.argv:
        main_v50()
    else:
        main()
