// SPDX-License-Identifier: AGPL-3.0-or-later

/// Positional string template formatter matching openGym i18n-core.js t().
///
/// Looks up [template] with {0}, {1}, ... positional substitutions.
/// Locales are Phase 8 (I18N-01/02); here English template strings are used as keys.
String t(String template, [List<Object?> args = const <Object?>[]]) {
  String v = template;
  for (int i = 0; i < args.length; i++) {
    v = v.replaceAll('{$i}', args[i]?.toString() ?? '');
  }
  return v;
}
