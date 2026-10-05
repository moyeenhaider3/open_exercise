// SPDX-License-Identifier: AGPL-3.0-or-later

/**
 * Deterministic WAV audio tone generator ported from openGym sound.js beep() envelope.
 *
 * References:
 * - ../openGym/frontend/src/lib/sound.js (beep() oscillator + exponential gain envelope)
 * - ../openGym/frontend/src/store/useUI.js (rest/work countdown tones: 660Hz@0.1s, 880Hz@0.15s, 1320Hz@0.4s)
 * - ../openGym/frontend/src/features/workout/Workout.jsx (set checked: 1040Hz@0.12s)
 * - ../openGym/frontend/src/features/workout/sheets.jsx (workout finished: 880Hz@0.15s, 1100Hz@0.15s, 1320Hz@0.3s)
 *
 * Envelope specification:
 * - Mono 16-bit PCM @ 44100 Hz.
 * - Total duration = dur + 0.05s tail.
 * - Gain envelope (WebAudio schedule):
 *   t = 0: gain = 0.001
 *   0 <= t < 0.02: exponential ramp from 0.001 to 0.35
 *   0.02 <= t <= dur: exponential ramp from 0.35 to 0.001
 *   t > dur: held at 0.001
 * Formula for exponential ramp between (t0, v0) and (t1, v1):
 *   v(t) = v0 * Math.pow(v1 / v0, (t - t0) / (t1 - t0))
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '../..');
const outputDir = path.resolve(projectRoot, 'assets/audio');

if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

const SAMPLE_RATE = 44100;
const V_MIN = 0.001;
const V_PEAK = 0.35;
const ATTACK_DUR = 0.02;
const TAIL_DUR = 0.05;

// (freq Hz, dur seconds)
const TONES = [
  { freq: 660, dur: 0.1 },
  { freq: 880, dur: 0.15 },
  { freq: 1320, dur: 0.4 },
  { freq: 1040, dur: 0.12 },
  { freq: 1100, dur: 0.15 },
  { freq: 1320, dur: 0.3 },
];

function generateWav(freq, dur) {
  const totalDur = dur + TAIL_DUR;
  const numSamples = Math.round(totalDur * SAMPLE_RATE);
  const dataSize = numSamples * 2; // 16-bit mono = 2 bytes per sample
  const buffer = Buffer.alloc(44 + dataSize);

  // RIFF chunk descriptor
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4); // ChunkSize
  buffer.write('WAVE', 8);

  // "fmt " sub-chunk
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16); // Subchunk1Size (16 for PCM)
  buffer.writeUInt16LE(1, 20);  // AudioFormat (1 for PCM)
  buffer.writeUInt16LE(1, 22);  // NumChannels (1 mono)
  buffer.writeUInt32LE(SAMPLE_RATE, 24); // SampleRate
  buffer.writeUInt32LE(SAMPLE_RATE * 2, 28); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
  buffer.writeUInt16LE(2, 32);  // BlockAlign (NumChannels * BitsPerSample/8)
  buffer.writeUInt16LE(16, 34); // BitsPerSample

  // "data" sub-chunk
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40); // Subchunk2Size

  let offset = 44;
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    let gain = V_MIN;

    if (t < ATTACK_DUR) {
      // Exponential ramp from V_MIN to V_PEAK
      gain = V_MIN * Math.pow(V_PEAK / V_MIN, t / ATTACK_DUR);
    } else if (t <= dur) {
      // Exponential ramp from V_PEAK to V_MIN
      gain = V_PEAK * Math.pow(V_MIN / V_PEAK, (t - ATTACK_DUR) / (dur - ATTACK_DUR));
    } else {
      // Held at V_MIN until end of tail
      gain = V_MIN;
    }

    const sample = Math.sin(2 * Math.PI * freq * t) * gain;
    // Scale by 32767 and clamp/round to signed 16-bit int
    const intSample = Math.max(-32768, Math.min(32767, Math.round(sample * 32767)));
    buffer.writeInt16LE(intSample, offset);
    offset += 2;
  }

  return { buffer, numSamples, bytes: buffer.length };
}

for (const tone of TONES) {
  const ms = Math.round(tone.dur * 1000);
  const filename = `tone_${tone.freq}_${ms}.wav`;
  const filePath = path.join(outputDir, filename);
  const { buffer, numSamples, bytes } = generateWav(tone.freq, tone.dur);
  fs.writeFileSync(filePath, buffer);
  console.log(`${filename}: ${numSamples} samples, ${bytes} bytes`);
}
