// SPDX-License-Identifier: AGPL-3.0-or-later

import 'exercise_def.dart';

/// Precomposed Latin diacritic decomposition table covering U+00C0–U+024F and U+1E00–U+1EFF.
/// Generated with Node.js:
/// ```js
/// for (let c = 0x00C0; c <= 0x024F; c++) {
///   const ch = String.fromCharCode(c);
///   const s = ch.normalize("NFD").replace(/[\\u0300-\\u036f]/g, "");
///   if (s !== ch) map[ch] = s;
/// }
/// // and similarly for 0x1E00 to 0x1EFF
/// ```
const Map<String, String> _kDiacriticDecompositions = <String, String>{
  "À": "A",
  "Á": "A",
  "Â": "A",
  "Ã": "A",
  "Ä": "A",
  "Å": "A",
  "Ç": "C",
  "È": "E",
  "É": "E",
  "Ê": "E",
  "Ë": "E",
  "Ì": "I",
  "Í": "I",
  "Î": "I",
  "Ï": "I",
  "Ñ": "N",
  "Ò": "O",
  "Ó": "O",
  "Ô": "O",
  "Õ": "O",
  "Ö": "O",
  "Ù": "U",
  "Ú": "U",
  "Û": "U",
  "Ü": "U",
  "Ý": "Y",
  "à": "a",
  "á": "a",
  "â": "a",
  "ã": "a",
  "ä": "a",
  "å": "a",
  "ç": "c",
  "è": "e",
  "é": "e",
  "ê": "e",
  "ë": "e",
  "ì": "i",
  "í": "i",
  "î": "i",
  "ï": "i",
  "ñ": "n",
  "ò": "o",
  "ó": "o",
  "ô": "o",
  "õ": "o",
  "ö": "o",
  "ù": "u",
  "ú": "u",
  "û": "u",
  "ü": "u",
  "ý": "y",
  "ÿ": "y",
  "Ā": "A",
  "ā": "a",
  "Ă": "A",
  "ă": "a",
  "Ą": "A",
  "ą": "a",
  "Ć": "C",
  "ć": "c",
  "Ĉ": "C",
  "ĉ": "c",
  "Ċ": "C",
  "ċ": "c",
  "Č": "C",
  "č": "c",
  "Ď": "D",
  "ď": "d",
  "Ē": "E",
  "ē": "e",
  "Ĕ": "E",
  "ĕ": "e",
  "Ė": "E",
  "ė": "e",
  "Ę": "E",
  "ę": "e",
  "Ě": "E",
  "ě": "e",
  "Ĝ": "G",
  "ĝ": "g",
  "Ğ": "G",
  "ğ": "g",
  "Ġ": "G",
  "ġ": "g",
  "Ģ": "G",
  "ģ": "g",
  "Ĥ": "H",
  "ĥ": "h",
  "Ĩ": "I",
  "ĩ": "i",
  "Ī": "I",
  "ī": "i",
  "Ĭ": "I",
  "ĭ": "i",
  "Į": "I",
  "į": "i",
  "İ": "I",
  "Ĵ": "J",
  "ĵ": "j",
  "Ķ": "K",
  "ķ": "k",
  "Ĺ": "L",
  "ĺ": "l",
  "Ļ": "L",
  "ļ": "l",
  "Ľ": "L",
  "ľ": "l",
  "Ń": "N",
  "ń": "n",
  "Ņ": "N",
  "ņ": "n",
  "Ň": "N",
  "ň": "n",
  "Ō": "O",
  "ō": "o",
  "Ŏ": "O",
  "ŏ": "o",
  "Ő": "O",
  "ő": "o",
  "Ŕ": "R",
  "ŕ": "r",
  "Ŗ": "R",
  "ŗ": "r",
  "Ř": "R",
  "ř": "r",
  "Ś": "S",
  "ś": "s",
  "Ŝ": "S",
  "ŝ": "s",
  "Ş": "S",
  "ş": "s",
  "Š": "S",
  "š": "s",
  "Ţ": "T",
  "ţ": "t",
  "Ť": "T",
  "ť": "t",
  "Ũ": "U",
  "ũ": "u",
  "Ū": "U",
  "ū": "u",
  "Ŭ": "U",
  "ŭ": "u",
  "Ů": "U",
  "ů": "u",
  "Ű": "U",
  "ű": "u",
  "Ų": "U",
  "ų": "u",
  "Ŵ": "W",
  "ŵ": "w",
  "Ŷ": "Y",
  "ŷ": "y",
  "Ÿ": "Y",
  "Ź": "Z",
  "ź": "z",
  "Ż": "Z",
  "ż": "z",
  "Ž": "Z",
  "ž": "z",
  "Ơ": "O",
  "ơ": "o",
  "Ư": "U",
  "ư": "u",
  "Ǎ": "A",
  "ǎ": "a",
  "Ǐ": "I",
  "ǐ": "i",
  "Ǒ": "O",
  "ǒ": "o",
  "Ǔ": "U",
  "ǔ": "u",
  "Ǖ": "U",
  "ǖ": "u",
  "Ǘ": "U",
  "ǘ": "u",
  "Ǚ": "U",
  "ǚ": "u",
  "Ǜ": "U",
  "ǜ": "u",
  "Ǟ": "A",
  "ǟ": "a",
  "Ǡ": "A",
  "ǡ": "a",
  "Ǣ": "Æ",
  "ǣ": "æ",
  "Ǧ": "G",
  "ǧ": "g",
  "Ǩ": "K",
  "ǩ": "k",
  "Ǫ": "O",
  "ǫ": "o",
  "Ǭ": "O",
  "ǭ": "o",
  "Ǯ": "Ʒ",
  "ǯ": "ʒ",
  "ǰ": "j",
  "Ǵ": "G",
  "ǵ": "g",
  "Ǹ": "N",
  "ǹ": "n",
  "Ǻ": "A",
  "ǻ": "a",
  "Ǽ": "Æ",
  "ǽ": "æ",
  "Ǿ": "Ø",
  "ǿ": "ø",
  "Ȁ": "A",
  "ȁ": "a",
  "Ȃ": "A",
  "ȃ": "a",
  "Ȅ": "E",
  "ȅ": "e",
  "Ȇ": "E",
  "ȇ": "e",
  "Ȉ": "I",
  "ȉ": "i",
  "Ȋ": "I",
  "ȋ": "i",
  "Ȍ": "O",
  "ȍ": "o",
  "Ȏ": "O",
  "ȏ": "o",
  "Ȑ": "R",
  "ȑ": "r",
  "Ȓ": "R",
  "ȓ": "r",
  "Ȕ": "U",
  "ȕ": "u",
  "Ȗ": "U",
  "ȗ": "u",
  "Ș": "S",
  "ș": "s",
  "Ț": "T",
  "ț": "t",
  "Ȟ": "H",
  "ȟ": "h",
  "Ȧ": "A",
  "ȧ": "a",
  "Ȩ": "E",
  "ȩ": "e",
  "Ȫ": "O",
  "ȫ": "o",
  "Ȭ": "O",
  "ȭ": "o",
  "Ȯ": "O",
  "ȯ": "o",
  "Ȱ": "O",
  "ȱ": "o",
  "Ȳ": "Y",
  "ȳ": "y",
  "Ḁ": "A",
  "ḁ": "a",
  "Ḃ": "B",
  "ḃ": "b",
  "Ḅ": "B",
  "ḅ": "b",
  "Ḇ": "B",
  "ḇ": "b",
  "Ḉ": "C",
  "ḉ": "c",
  "Ḋ": "D",
  "ḋ": "d",
  "Ḍ": "D",
  "ḍ": "d",
  "Ḏ": "D",
  "ḏ": "d",
  "Ḑ": "D",
  "ḑ": "d",
  "Ḓ": "D",
  "ḓ": "d",
  "Ḕ": "E",
  "ḕ": "e",
  "Ḗ": "E",
  "ḗ": "e",
  "Ḙ": "E",
  "ḙ": "e",
  "Ḛ": "E",
  "ḛ": "e",
  "Ḝ": "E",
  "ḝ": "e",
  "Ḟ": "F",
  "ḟ": "f",
  "Ḡ": "G",
  "ḡ": "g",
  "Ḣ": "H",
  "ḣ": "h",
  "Ḥ": "H",
  "ḥ": "h",
  "Ḧ": "H",
  "ḧ": "h",
  "Ḩ": "H",
  "ḩ": "h",
  "Ḫ": "H",
  "ḫ": "h",
  "Ḭ": "I",
  "ḭ": "i",
  "Ḯ": "I",
  "ḯ": "i",
  "Ḱ": "K",
  "ḱ": "k",
  "Ḳ": "K",
  "ḳ": "k",
  "Ḵ": "K",
  "ḵ": "k",
  "Ḷ": "L",
  "ḷ": "l",
  "Ḹ": "L",
  "ḹ": "l",
  "Ḻ": "L",
  "ḻ": "l",
  "Ḽ": "L",
  "ḽ": "l",
  "Ḿ": "M",
  "ḿ": "m",
  "Ṁ": "M",
  "ṁ": "m",
  "Ṃ": "M",
  "ṃ": "m",
  "Ṅ": "N",
  "ṅ": "n",
  "Ṇ": "N",
  "ṇ": "n",
  "Ṉ": "N",
  "ṉ": "n",
  "Ṋ": "N",
  "ṋ": "n",
  "Ṍ": "O",
  "ṍ": "o",
  "Ṏ": "O",
  "ṏ": "o",
  "Ṑ": "O",
  "ṑ": "o",
  "Ṓ": "O",
  "ṓ": "o",
  "Ṕ": "P",
  "ṕ": "p",
  "Ṗ": "P",
  "ṗ": "p",
  "Ṙ": "R",
  "ṙ": "r",
  "Ṛ": "R",
  "ṛ": "r",
  "Ṝ": "R",
  "ṝ": "r",
  "Ṟ": "R",
  "ṟ": "r",
  "Ṡ": "S",
  "ṡ": "s",
  "Ṣ": "S",
  "ṣ": "s",
  "Ṥ": "S",
  "ṥ": "s",
  "Ṧ": "S",
  "ṧ": "s",
  "Ṩ": "S",
  "ṩ": "s",
  "Ṫ": "T",
  "ṫ": "t",
  "Ṭ": "T",
  "ṭ": "t",
  "Ṯ": "T",
  "ṯ": "t",
  "Ṱ": "T",
  "ṱ": "t",
  "Ṳ": "U",
  "ṳ": "u",
  "Ṵ": "U",
  "ṵ": "u",
  "Ṷ": "U",
  "ṷ": "u",
  "Ṹ": "U",
  "ṹ": "u",
  "Ṻ": "U",
  "ṻ": "u",
  "Ṽ": "V",
  "ṽ": "v",
  "Ṿ": "V",
  "ṿ": "v",
  "Ẁ": "W",
  "ẁ": "w",
  "Ẃ": "W",
  "ẃ": "w",
  "Ẅ": "W",
  "ẅ": "w",
  "Ẇ": "W",
  "ẇ": "w",
  "Ẉ": "W",
  "ẉ": "w",
  "Ẋ": "X",
  "ẋ": "x",
  "Ẍ": "X",
  "ẍ": "x",
  "Ẏ": "Y",
  "ẏ": "y",
  "Ẑ": "Z",
  "ẑ": "z",
  "Ẓ": "Z",
  "ẓ": "z",
  "Ẕ": "Z",
  "ẕ": "z",
  "ẖ": "h",
  "ẗ": "t",
  "ẘ": "w",
  "ẙ": "y",
  "ẛ": "ſ",
  "Ạ": "A",
  "ạ": "a",
  "Ả": "A",
  "ả": "a",
  "Ấ": "A",
  "ấ": "a",
  "Ầ": "A",
  "ầ": "a",
  "Ẩ": "A",
  "ẩ": "a",
  "Ẫ": "A",
  "ẫ": "a",
  "Ậ": "A",
  "ậ": "a",
  "Ắ": "A",
  "ắ": "a",
  "Ằ": "A",
  "ằ": "a",
  "Ẳ": "A",
  "ẳ": "a",
  "Ẵ": "A",
  "ẵ": "a",
  "Ặ": "A",
  "ặ": "a",
  "Ẹ": "E",
  "ẹ": "e",
  "Ẻ": "E",
  "ẻ": "e",
  "Ẽ": "E",
  "ẽ": "e",
  "Ế": "E",
  "ế": "e",
  "Ề": "E",
  "ề": "e",
  "Ể": "E",
  "ể": "e",
  "Ễ": "E",
  "ễ": "e",
  "Ệ": "E",
  "ệ": "e",
  "Ỉ": "I",
  "ỉ": "i",
  "Ị": "I",
  "ị": "i",
  "Ọ": "O",
  "ọ": "o",
  "Ỏ": "O",
  "ỏ": "o",
  "Ố": "O",
  "ố": "o",
  "Ồ": "O",
  "ồ": "o",
  "Ổ": "O",
  "ổ": "o",
  "Ỗ": "O",
  "ỗ": "o",
  "Ộ": "O",
  "ộ": "o",
  "Ớ": "O",
  "ớ": "o",
  "Ờ": "O",
  "ờ": "o",
  "Ở": "O",
  "ở": "o",
  "Ỡ": "O",
  "ỡ": "o",
  "Ợ": "O",
  "ợ": "o",
  "Ụ": "U",
  "ụ": "u",
  "Ủ": "U",
  "ủ": "u",
  "Ứ": "U",
  "ứ": "u",
  "Ừ": "U",
  "ừ": "u",
  "Ử": "U",
  "ử": "u",
  "Ữ": "U",
  "ữ": "u",
  "Ự": "U",
  "ự": "u",
  "Ỳ": "Y",
  "ỳ": "y",
  "Ỵ": "Y",
  "ỵ": "y",
  "Ỷ": "Y",
  "ỷ": "y",
  "Ỹ": "Y",
  "ỹ": "y",
};

/// Normalizes text by lowercasing and stripping diacritics/accents (e.g. "Elevação" -> "elevacao").
/// Ported from ../openGym/frontend/src/lib/exercises.js:normalizeStr
String normalizeStr(String? s) {
  if (s == null || s.isEmpty) return '';
  final StringBuffer buffer = StringBuffer();
  for (final int rune in s.runes) {
    final String ch = String.fromCharCode(rune);
    final String? replacement = _kDiacriticDecompositions[ch];
    buffer.write(replacement ?? ch);
  }
  return buffer.toString().toLowerCase();
}

/// Case-insensitive search over built-in and legacy custom exercise metadata.
/// Ported from ../openGym/frontend/src/lib/exercises.js:isSubsequence
bool isSubsequence(String needle, String hay) {
  int i = 0;
  for (int j = 0; j < hay.length; j++) {
    if (hay[j] == needle[i]) {
      i++;
      if (i == needle.length) return true;
    }
  }
  return false;
}

String _searchableText(Object? value) {
  if (value is List) return value.map(_searchableText).join(' ');
  if (value == null) return '';
  return value.toString();
}

/// Fuzzy match score for one exercise against a query.
/// Ported from ../openGym/frontend/src/lib/exercises.js:searchScore
double searchScore(ExerciseDef? exercise, String? query) {
  final String needle = normalizeStr(query).trim();
  if (needle.isEmpty) return 1.0;
  if (exercise == null) return 0.0;

  const List<(String, double)> fields = <(String, double)>[
    ('n', 100.0),
    ('tg', 40.0),
    ('eq', 40.0),
    ('sm', 30.0),
    ('muscleGroups', 30.0),
    ('primaries', 30.0),
    ('secondaries', 30.0),
    ('desc', 10.0),
    ('cues', 10.0),
  ];

  final List<String> tokens = needle
      .split(RegExp(r'[^a-z0-9]+'))
      .where((String t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return 0.0;

  final Map<String, Object?> json = exercise.toJson();
  double total = 0.0;

  for (final String token in tokens) {
    double best = 0.0;
    for (final (String field, double weight) in fields) {
      final String hay = _searchableText(json[field]).toLowerCase();
      if (hay.isEmpty) continue;

      if (hay == token) {
        if (weight * 4 > best) best = weight * 4;
      } else if (hay.startsWith(token)) {
        if (weight * 3 > best) best = weight * 3;
      }

      final int idx = hay.indexOf(token);
      if (idx > 0) {
        final double score = weight * 2 - (idx < 20 ? idx : 20) * 0.5;
        if (score > best) best = score;
      }

      final bool wordPrefix = hay
          .split(RegExp(r'[^a-z0-9]+'))
          .any((String w) => w.startsWith(token));
      if (wordPrefix) {
        if (weight * 2.5 > best) best = weight * 2.5;
      }

      if (isSubsequence(token, hay)) {
        final double diff = (hay.length - token.length).toDouble();
        final double bonus = 10.0 - diff > 0 ? 10.0 - diff : 0.0;
        final double score = weight + bonus;
        if (score > best) best = score;
      }
    }

    if (best == 0.0) return 0.0;
    total += best;
  }

  return total;
}

/// Ported from ../openGym/frontend/src/lib/exercises.js:matchesExerciseSearch
bool matchesExerciseSearch(ExerciseDef? exercise, String? query) {
  return searchScore(exercise, query) > 0;
}

/// Cached searchable text and name words for one exercise.
final class ExerciseCorpus {
  const ExerciseCorpus({
    required this.s,
    required this.nameWords,
  });

  final String s;
  final List<String> nameWords;
}

final Expando<ExerciseCorpus> _corpusCache = Expando<ExerciseCorpus>('exerciseCorpusCache');

/// Multi-token haystack representation for one exercise.
/// Ported from ../openGym/frontend/src/lib/exercises.js:corpusOf
ExerciseCorpus corpusOf(ExerciseDef e, {String Function(String)? t}) {
  final ExerciseCorpus? hit = _corpusCache[e];
  if (hit != null) return hit;

  final String Function(String) tr = t ?? (String s) => s;
  final String name = normalizeStr(e.n);
  final List<String> smList = e.sm ?? const <String>[];
  final String target = e.tg ?? '';
  final String desc = e.desc ?? '';
  final List<String> parts = <String>[
    name,
    target,
    tr(target),
    e.eq,
    tr(e.eq),
    e.bp,
    tr(e.bp),
    ...smList,
    ...smList.map(tr),
    desc,
  ];
  final String s = normalizeStr(parts.join(' '));
  final List<String> nameWords = name
      .split(RegExp(r'\s+'))
      .where((String w) => w.isNotEmpty)
      .toList(growable: false);

  final ExerciseCorpus entry = ExerciseCorpus(s: s, nameWords: nameWords);
  _corpusCache[e] = entry;
  return entry;
}

/// Allow one missing, extra or substituted character, or an adjacent transposition, in long query tokens.
/// Ported from ../openGym/frontend/src/lib/exercises.js:nearWord
bool nearWord(String a, String b) {
  if (a.length < 5 || (a.length - b.length).abs() > 1) return false;
  int i = 0;
  while (i < a.length && i < b.length && a[i] == b[i]) {
    i++;
  }
  if (i == a.length) return b.length - i <= 1;
  if (a.length == b.length) {
    if (a.substring(i + 1) == b.substring(i + 1)) return true;
    if (i + 1 < a.length && a[i] == b[i + 1] && a[i + 1] == b[i]) {
      return (i + 2 >= a.length) || (a.substring(i + 2) == b.substring(i + 2));
    }
    return false;
  }
  return a.length > b.length
      ? a.substring(i + 1) == b.substring(i)
      : a.substring(i) == b.substring(i + 1);
}

/// Ported from ../openGym/frontend/src/lib/exercises.js:queryTokens
List<String> queryTokens(String? query) {
  return normalizeStr(query)
      .split(RegExp(r'\s+'))
      .where((String t) => t.isNotEmpty)
      .toList();
}

/// Ported from ../openGym/frontend/src/lib/exercises.js:matchTokens
bool matchTokens(ExerciseDef e, List<String> tokens, Set<String> fuzzy, {String Function(String)? t}) {
  final ExerciseCorpus corpus = corpusOf(e, t: t);
  final String s = corpus.s;
  final List<String> nameWords = corpus.nameWords;
  return tokens.every((String tok) =>
      s.contains(tok) ||
      (fuzzy.contains(tok) && nameWords.any((String word) => nearWord(tok, word))));
}

/// Single-exercise check with typo tolerance on every token.
/// Ported from ../openGym/frontend/src/lib/exercises.js:matchExercise
bool matchExercise(ExerciseDef? e, String? query, {String Function(String)? t}) {
  final List<String> tokens = queryTokens(query);
  if (tokens.isEmpty) return true;
  if (e == null) return false;
  return matchTokens(e, tokens, tokens.toSet(), t: t);
}

/// Search a list, exact hits first: a token that appears literally in at least one exercise
/// is taken at its word for the whole list, and only a token with no exact hit anywhere
/// is allowed the typo tolerance.
/// Ported from ../openGym/frontend/src/lib/exercises.js:searchExercises
List<ExerciseDef> searchExercises(List<ExerciseDef> list, String? query, {String Function(String)? t}) {
  final List<String> tokens = queryTokens(query);
  if (tokens.isEmpty) return list;
  final Set<String> fuzzy = tokens
      .where((String tok) => !list.any((ExerciseDef e) => corpusOf(e, t: t).s.contains(tok)))
      .toSet();
  return list.where((ExerciseDef e) => matchTokens(e, tokens, fuzzy, t: t)).toList();
}

