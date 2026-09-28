// SPDX-License-Identifier: AGPL-3.0-or-later

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { CATALOGUE, BODYPARTS } from '../../third_party/opengym/lib/exercises.js';
import { EXDB } from '../../third_party/opengym/lib/exercises-data.js';
import { MUSCLE_NAME } from '../../third_party/opengym/lib/muscles.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const projectRoot = path.resolve(__dirname, '../..');
const exercisesDataPath = path.resolve(projectRoot, 'third_party/opengym/lib/exercises-data.js');
const outputPath = path.resolve(projectRoot, 'assets/data/exercise_catalogue.json');

const dataJs = fs.readFileSync(exercisesDataPath, 'utf8');
const dataSha256 = crypto.createHash('sha256').update(dataJs).digest('hex');

// Calculate all equipment list in openGym frequency order
const c = {};
EXDB.forEach(e => {
  if (e.eq) c[e.eq] = (c[e.eq] || 0) + 1;
});
const allEquipment = Object.keys(c).sort((a, b) => c[b] - c[a] || (a < b ? -1 : 1));

// Conservative secondary additions from exercises.js:30
const secondaryAdditions = {
  '0027': ['rear deltoids'],
  '0293': ['rear deltoids'],
  '0499': ['rear deltoids'],
  '0861': ['rear deltoids'],
};

const payload = {
  source: {
    openGymVersion: '1.3.8',
    exercisesDataSha256: dataSha256,
  },
  catalogue: CATALOGUE,
  bodyParts: BODYPARTS,
  muscleName: MUSCLE_NAME,
  allEquipment: allEquipment,
  secondaryAdditions: secondaryAdditions,
};

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(payload, null, 2), 'utf8');

console.log(
  `Generated ${outputPath} with ${CATALOGUE.length} exercises (source SHA: ${dataSha256.substring(0, 12)}).`,
);
