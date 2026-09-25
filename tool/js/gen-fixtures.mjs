// SPDX-License-Identifier: AGPL-3.0-or-later

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';

import { INVENTORY } from './bridge-inventory.mjs';
import { UNDEF } from './fixture-cases/helpers.mjs';

import * as onerm from '../../third_party/opengym/lib/onerm.js';
import * as bar from '../../third_party/opengym/lib/bar.js';
import * as workoutModel from '../../third_party/opengym/lib/workout-model.js';
import * as progression from '../../third_party/opengym/lib/progression.js';
import * as recovery from '../../third_party/opengym/lib/recovery.js';
import * as history from '../../third_party/opengym/lib/history.js';
import * as sessionStart from '../../third_party/opengym/lib/session-start.js';
import * as sessionMerge from '../../third_party/opengym/lib/session-merge.js';

const MODULES = {
  onerm,
  bar,
  workoutModel,
  progression,
  recovery,
  history,
  sessionStart,
  sessionMerge,
};

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '../..');

// Step 1: Validate INVENTORY against live modules
const ALL_FUNCTIONS = new Set();
for (const [ns, def] of Object.entries(INVENTORY)) {
  const mod = MODULES[ns];
  if (!mod) {
    throw new Error(`Inventory namespace "${ns}" not found in modules`);
  }
  for (const fn of def.functions) {
    if (typeof mod[fn] !== 'function') {
      throw new Error(`Inventory function "${ns}.${fn}" is not a function in live module`);
    }
    ALL_FUNCTIONS.add(`${ns}.${fn}`);
  }
  for (const c of def.constants) {
    if (mod[c] === undefined) {
      throw new Error(`Inventory constant "${ns}.${c}" is undefined`);
    }
  }
  for (const k of def.keys) {
    if (typeof mod[k] !== 'object' || mod[k] === null) {
      throw new Error(`Inventory key target "${ns}.${k}" is not an object`);
    }
  }
}

// Read openGym version & manifest SHA
const VERSION_PATH = path.join(REPO_ROOT, 'third_party/opengym/lib/VERSION');
const MANIFEST_PATH = path.join(REPO_ROOT, 'third_party/opengym/lib/MANIFEST.sha256');

const openGymVersion = fs.readFileSync(VERSION_PATH, 'utf8').trim();
const manifestBytes = fs.readFileSync(MANIFEST_PATH);
const sourceSha256 = crypto.createHash('sha256').update(manifestBytes).digest('hex');

// Load case files
const MODULE_FILES = [
  { name: 'onerm', file: './fixture-cases/onerm.mjs' },
  { name: 'bar', file: './fixture-cases/bar.mjs' },
  { name: 'workout-model', file: './fixture-cases/workout-model.mjs' },
  { name: 'progression', file: './fixture-cases/progression.mjs' },
  { name: 'recovery', file: './fixture-cases/recovery.mjs' },
  { name: 'history', file: './fixture-cases/history.mjs' },
  { name: 'session', file: './fixture-cases/session.mjs' },
];

function serializeArgs(args) {
  return JSON.parse(
    JSON.stringify(args, (_k, v) => (v === UNDEF ? { $undefined: true } : v))
  );
}

function decodeArgs(serializedArgs) {
  return JSON.parse(
    JSON.stringify(serializedArgs),
    (_k, v) => (v && typeof v === 'object' && v.$undefined === true ? undefined : v)
  );
}

const seenIds = new Set();
const resultsByModule = {};
const stats = { totalCases: 0, totalVitest: 0, byModule: {} };

for (const { name, file } of MODULE_FILES) {
  const modPath = path.resolve(__dirname, file);
  const modCases = (await import(modPath)).cases;

  const processedCases = [];
  let vitestCount = 0;

  for (const c of modCases) {
    if (seenIds.has(c.id)) {
      throw new Error(`Duplicate case id: "${c.id}" in module "${name}"`);
    }
    seenIds.add(c.id);

    if (c.fn === 'history.streakWeeks') {
      throw new Error(`history.streakWeeks is banned from fixtures (wall-clock dependency)`);
    }

    if (!ALL_FUNCTIONS.has(c.fn)) {
      throw new Error(`Function "${c.fn}" in case "${c.id}" is not in bridge inventory`);
    }

    const [ns, fnName] = c.fn.split('.');
    const fn = MODULES[ns][fnName];

    const serializedArgs = serializeArgs(c.args || []);
    const runtimeArgs = decodeArgs(serializedArgs);

    let expected;
    if (c.throws === true) {
      assert.throws(
        () => fn.apply(null, runtimeArgs),
        `Case "${c.id}" was marked throws: true but did not throw`
      );
      expected = { $throws: true };
    } else {
      let r;
      try {
        r = fn.apply(null, runtimeArgs);
      } catch (err) {
        throw new Error(`Case "${c.id}" (${c.fn}) threw unexpectedly: ${err}`);
      }
      expected = JSON.parse(JSON.stringify({ ok: r === undefined ? null : r })).ok;
    }

    if (c.vitest !== undefined) {
      const expectedNormalized = JSON.parse(JSON.stringify(expected));
      const vitestNormalized = JSON.parse(JSON.stringify(c.vitest));
      try {
        assert.deepStrictEqual(expectedNormalized, vitestNormalized);
      } catch (err) {
        console.error(`Vitest cross-check failed for case "${c.id}" (${c.fn}):`);
        console.error('Expected:', expectedNormalized);
        console.error('Vitest:  ', vitestNormalized);
        throw err;
      }
      vitestCount++;
    }

    const outCase = {
      id: c.id,
      fn: c.fn,
      args: serializedArgs,
      expected: expected,
      from: c.from,
    };
    if (c.vitest !== undefined) {
      outCase.vitest = c.vitest;
    }
    processedCases.push(outCase);
  }

  resultsByModule[name] = {
    schema: 1,
    module: name,
    openGymVersion,
    sourceSha256,
    generatedBy: 'tool/gen_js_fixtures.sh',
    cases: processedCases,
  };

  stats.byModule[name] = { total: processedCases.length, vitest: vitestCount };
  stats.totalCases += processedCases.length;
  stats.totalVitest += vitestCount;
}

// Parse CLI flags
const args = process.argv.slice(2);
let outDir = null;
let dartFile = null;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--out' && i + 1 < args.length) {
    outDir = path.resolve(process.cwd(), args[++i]);
  } else if (args[i] === '--dart' && i + 1 < args.length) {
    dartFile = path.resolve(process.cwd(), args[++i]);
  }
}

if (outDir) {
  fs.mkdirSync(outDir, { recursive: true });
  for (const [name, data] of Object.entries(resultsByModule)) {
    const filePath = path.join(outDir, `${name}.json`);
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
  }
}

if (dartFile) {
  fs.mkdirSync(path.dirname(dartFile), { recursive: true });
  const sortedInventory = Array.from(ALL_FUNCTIONS).sort();

  const dartBuf = [];
  dartBuf.push('// SPDX-License-Identifier: AGPL-3.0-or-later\n');
  dartBuf.push('// GENERATED by tool/gen_js_fixtures.sh from tool/js/gen-fixtures.mjs. Do not edit.\n\n');
  dartBuf.push(`const String kParityFixturesSourceSha256 = '${sourceSha256}';\n\n`);
  dartBuf.push(`const String kParityOpenGymVersion = '${openGymVersion}';\n\n`);

  dartBuf.push('const List<String> kBridgeInventory = <String>[\n');
  for (const item of sortedInventory) {
    dartBuf.push(`  '${item}',\n`);
  }
  dartBuf.push('];\n\n');

  dartBuf.push('const Map<String, String> kParityFixturesBase64 = <String, String>{\n');
  for (const [name, data] of Object.entries(resultsByModule)) {
    const jsonStr = JSON.stringify(data, null, 2) + '\n';
    const b64 = Buffer.from(jsonStr, 'utf8').toString('base64');
    dartBuf.push(`  '${name}.json':\n`);
    // Split into chunks of at most 1000 characters
    for (let pos = 0; pos < b64.length; pos += 1000) {
      const chunk = b64.slice(pos, pos + 1000);
      dartBuf.push(`      '${chunk}'\n`);
    }
    dartBuf.push('  ,\n');
  }
  dartBuf.push('};\n');

  fs.writeFileSync(dartFile, dartBuf.join(''), 'utf8');
}

// Print summary
console.log('=== Parity Fixtures Summary ===');
console.log(`Source SHA-256: ${sourceSha256}`);
console.log(`openGym Version: ${openGymVersion}`);
console.log('-------------------------------');
for (const [mod, s] of Object.entries(stats.byModule)) {
  console.log(`${mod.padEnd(16)}: ${String(s.total).padStart(3)} cases (${s.vitest} vitest cross-checked)`);
}
console.log('-------------------------------');
console.log(`Total           : ${stats.totalCases} cases (${stats.totalVitest} vitest cross-checked)`);
