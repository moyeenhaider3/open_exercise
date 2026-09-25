// SPDX-License-Identifier: AGPL-3.0-or-later

/// Schema v1 for the local sqflite persistence of the whole openGym profile
/// (`GymState`, `lib/core/models/gym_state.dart`).
///
/// Hybrid design: `user_state` holds every scalar/settings top-level key as one opaque
/// `doc_json` document (order-irrelevant, key-presence-preserving), while `workouts`,
/// `routines` and `bodyweight` -- the three top-level *array* keys -- get their own tables so
/// Phase 3 History/Stats can query them without deserializing the whole profile. Array order is
/// significant (workouts are chronological) and legacy/real-world data may repeat or omit `id`,
/// so these array tables key on `(uid, pos)`, never `(uid, id)`.
///
/// Every row also stores the exact original element as `raw_json` so index-column extraction
/// (wrong type, missing field) never loses data -- only ever adds a queryable NULL.
library;

/// Table and column name constants. [GymStateRepository]
/// (`lib/core/data/gym_state_repository.dart`) must use these instead of string literals so a
/// renamed column/table only has one point of change.
abstract final class Tables {
  static const String userState = 'user_state';
  static const String workouts = 'workouts';
  static const String routines = 'routines';
  static const String bodyweight = 'bodyweight';

  // Shared by every table.
  static const String colUid = 'uid';

  // user_state-only columns.
  static const String colDocJson = 'doc_json';
  static const String colTs = 'ts';
  static const String colRev = 'rev';
  static const String colWorkoutsPresent = 'workouts_present';
  static const String colRoutinesPresent = 'routines_present';
  static const String colBodyweightPresent = 'bodyweight_present';
  static const String colUpdatedAt = 'updated_at';

  // Shared by workouts/routines/bodyweight (the array tables).
  static const String colPos = 'pos';
  static const String colRawJson = 'raw_json';

  // Shared by workouts/routines (both have an `id`); bodyweight has no `id` in openGym.
  static const String colId = 'id';

  // workouts-only index columns.
  static const String colD = 'd';
  static const String colStart = 'start';
  static const String colEndMs = 'end_ms';
  static const String colRoutineId = 'routine_id';

  // routines-only index columns.
  static const String colName = 'name';

  // bodyweight-only index columns (bodyweight also has `d`, shared name above).
  static const String colW = 'w';
  static const String colT = 't';

  static const String idxWorkoutsUidD = 'idx_workouts_uid_d';
  static const String idxWorkoutsUidId = 'idx_workouts_uid_id';
  static const String idxBodyweightUidD = 'idx_bodyweight_uid_d';
}

/// Current schema version. Bump alongside a new entry appended to a version-specific create/
/// migration list; [AppDatabase.open]'s `onUpgrade` hook is where future migrations run.
const int kSchemaVersion = 1;

/// Every table/index creation statement for schema v1, run once (in a batch) by
/// [AppDatabase.open]'s `onCreate` callback.
const List<String> kCreateStatementsV1 = <String>[
  '''
CREATE TABLE user_state (
  uid TEXT PRIMARY KEY,
  doc_json TEXT NOT NULL,
  ts REAL,
  rev INTEGER,
  workouts_present INTEGER,
  routines_present INTEGER,
  bodyweight_present INTEGER,
  updated_at INTEGER NOT NULL
)
''',
  '''
CREATE TABLE workouts (
  uid TEXT NOT NULL,
  pos INTEGER NOT NULL,
  id TEXT,
  d TEXT,
  start REAL,
  end_ms REAL,
  routine_id TEXT,
  raw_json TEXT NOT NULL,
  PRIMARY KEY(uid, pos)
)
''',
  'CREATE INDEX idx_workouts_uid_d ON workouts(uid, d)',
  'CREATE INDEX idx_workouts_uid_id ON workouts(uid, id)',
  '''
CREATE TABLE routines (
  uid TEXT NOT NULL,
  pos INTEGER NOT NULL,
  id TEXT,
  name TEXT,
  raw_json TEXT NOT NULL,
  PRIMARY KEY(uid, pos)
)
''',
  '''
CREATE TABLE bodyweight (
  uid TEXT NOT NULL,
  pos INTEGER NOT NULL,
  d TEXT,
  w REAL,
  t REAL,
  raw_json TEXT NOT NULL,
  PRIMARY KEY(uid, pos)
)
''',
  'CREATE INDEX idx_bodyweight_uid_d ON bodyweight(uid, d)',
];
