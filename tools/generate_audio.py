import math
import os
import struct
import wave

SAMPLE_RATE = 44100
AUDIO_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def save_wav(filename: str, samples: list, num_channels: int = 1):
    os.makedirs(AUDIO_DIR, exist_ok=True)
    filepath = os.path.join(AUDIO_DIR, filename)

    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(num_channels)
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(SAMPLE_RATE)

        raw_data = bytearray()
        for sample in samples:
            clamped = max(-1.0, min(1.0, sample))
            int_val = int(clamped * 32767.0)
            raw_data.extend(struct.pack("<h", int_val))

        wav_file.writeframes(raw_data)
    print(f"Generated: {filename} ({len(samples) / SAMPLE_RATE * 1000:.1f}ms)")


def generate_tile_select_variants():
    """Generates instant-attack marimba notes for progressive tile swiping."""
    # Pentatonic scale frequencies (C5, D5, E5, G5, A5, C6)
    frequencies = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50]
    duration = 0.048  # 48ms snappy pop
    total_samples = int(SAMPLE_RATE * duration)

    for idx, freq in enumerate(frequencies, start=1):
        samples = []
        for i in range(total_samples):
            t = i / SAMPLE_RATE
            # Instant attack at sample 0, rapid exponential decay
            env = math.exp(-t * 90.0)
            val = math.sin(2.0 * math.pi * freq * t) * 0.75
            val += math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.20
            val += math.sin(2.0 * math.pi * freq * 3.0 * t) * 0.05
            samples.append(val * env * 0.90)

        save_wav(f"tile_select_{idx}.wav", samples)

    # Base default fallback
    save_wav("tile_select.wav", samples)


def generate_word_match():
    """Bright, instant major chord bell chime when solving a word."""
    duration = 0.48
    total_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * total_samples
    notes = [523.25, 659.25, 783.99, 1046.50]  # C5, E5, G5, C6 arpeggio

    for note_idx, freq in enumerate(notes):
        start_time = note_idx * 0.065
        start_sample = int(start_time * SAMPLE_RATE)
        for i in range(start_sample, total_samples):
            t = (i - start_sample) / SAMPLE_RATE
            env = math.exp(-t * 9.0)
            val = math.sin(2.0 * math.pi * freq * t) * 0.55
            val += math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.25
            samples[i] += val * env * 0.35

    save_wav("word_match.wav", samples)


def generate_extra_word():
    """Bright sparkling coin chime for extra words."""
    duration = 0.40
    total_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * total_samples
    notes = [987.77, 1318.51, 1567.98]  # B5, E6, G6

    for note_idx, freq in enumerate(notes):
        start_time = note_idx * 0.055
        start_sample = int(start_time * SAMPLE_RATE)
        for i in range(start_sample, total_samples):
            t = (i - start_sample) / SAMPLE_RATE
            env = math.exp(-t * 14.0)
            val = math.sin(2.0 * math.pi * freq * t) * 0.65
            val += math.sin(2.0 * math.pi * freq * 3.0 * t) * 0.18
            samples[i] += val * env * 0.40

    save_wav("extra_word.wav", samples)


def generate_victory():
    """Joyful victorious fanfare jingle when completing a level."""
    duration = 1.5
    total_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * total_samples

    melody = [
        (0.00, 0.15, 392.00),  # G4
        (0.12, 0.15, 523.25),  # C5
        (0.24, 0.15, 659.25),  # E5
        (0.38, 1.05, 783.99),  # G5
        (0.38, 1.05, 1046.50), # C6
        (0.38, 1.05, 1318.51), # E6
    ]

    for start_t, dur, freq in melody:
        start_sample = int(start_t * SAMPLE_RATE)
        end_sample = min(total_samples, start_sample + int(dur * SAMPLE_RATE))
        for i in range(start_sample, end_sample):
            t = (i - start_sample) / SAMPLE_RATE
            env = math.exp(-t * 3.0) if dur > 0.5 else math.exp(-t * 9.0)
            val = math.sin(2.0 * math.pi * freq * t) * 0.50
            val += math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.25
            samples[i] += val * env * 0.35

    save_wav("victory.wav", samples)


def generate_booster():
    """Rising rocket whoosh & power sound."""
    duration = 0.55
    total_samples = int(SAMPLE_RATE * duration)
    samples = []

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        freq = 250.0 + 1100.0 * (t / duration) ** 1.5
        env = math.sin(math.pi * (t / duration)) ** 0.5
        val = math.sin(2.0 * math.pi * freq * t) * 0.55
        val += math.sin(2.0 * math.pi * freq * 1.5 * t) * 0.30
        samples.append(val * env * 0.65)

    save_wav("booster.wav", samples)


def generate_invalid():
    """Gentle low-pitch wooden thud when word is invalid."""
    duration = 0.14
    total_samples = int(SAMPLE_RATE * duration)
    samples = []

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        freq = 190.0 - 60.0 * (t / duration)
        env = math.exp(-t * 30.0)
        val = math.sin(2.0 * math.pi * freq * t) * 0.70
        samples.append(val * env * 0.55)

    save_wav("invalid.wav", samples)


def generate_bgm():
    """Peaceful, relaxing, ambient acoustic background chords that loop seamlessly."""
    duration = 8.0  # 8 second loop
    total_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * total_samples

    # 4 chord progression: Cmaj7 -> Am7 -> Fmaj7 -> Gsus4 (2.0s each)
    chords = [
        (0.0, 2.0, [261.63, 329.63, 392.00, 493.88]), # Cmaj7
        (2.0, 2.0, [220.00, 261.63, 329.63, 392.00]), # Am7
        (4.0, 2.0, [174.61, 261.63, 329.63, 349.23]), # Fmaj7
        (6.0, 2.0, [196.00, 293.66, 392.00, 440.00]), # Gsus4
    ]

    for start_t, dur, chord_notes in chords:
        start_sample = int(start_t * SAMPLE_RATE)
        for note_idx, freq in enumerate(chord_notes):
            pluck_start = start_sample + int(note_idx * 0.35 * SAMPLE_RATE)
            for i in range(pluck_start, min(total_samples, pluck_start + int(1.8 * SAMPLE_RATE))):
                t = (i - pluck_start) / SAMPLE_RATE
                env = math.exp(-t * 1.8)
                val = math.sin(2.0 * math.pi * freq * t) * 0.4
                val += math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.15
                samples[i] += val * env * 0.18

    # Apply soft loop fade at edges
    fade_len = int(0.1 * SAMPLE_RATE)
    for i in range(fade_len):
        f = i / fade_len
        samples[i] *= f
        samples[total_samples - 1 - i] *= f

    save_wav("bgm.wav", samples)


def main():
    print("Generating ultra-fast, zero-latency procedural sound effects...")
    generate_tile_select_variants()
    generate_word_match()
    generate_extra_word()
    generate_victory()
    generate_booster()
    generate_invalid()
    generate_bgm()
    print("All audio files generated successfully!")


if __name__ == "__main__":
    main()
