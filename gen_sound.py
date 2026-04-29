import os
import wave
import struct
import math

base_path = r"c:\Users\314ckle\Downloads\int\front-flutter-integration2.0.0"
os.makedirs(os.path.join(base_path, "assets", "sounds"), exist_ok=True)
file_path = os.path.join(base_path, "assets", "sounds", "shoot.wav")

sample_rate = 44100.0
duration = 0.08 # 80ms
frequency = 1800.0 # high pitch pop

with wave.open(file_path, "w") as wave_file:
    wave_file.setnchannels(1)
    wave_file.setsampwidth(2)
    wave_file.setframerate(sample_rate)

    for i in range(int(duration * sample_rate)):
        # short pitch sweep down and volume decay
        freq = frequency * math.exp(-i / (sample_rate * 0.02))
        envelope = math.exp(-i / (sample_rate * 0.015))
        value = int(envelope * 32767.0 * math.sin(2.0 * math.pi * freq * (i / sample_rate)))
        wave_file.writeframesraw(struct.pack("<h", value))

print(f"Created dummy sound at {file_path}")
