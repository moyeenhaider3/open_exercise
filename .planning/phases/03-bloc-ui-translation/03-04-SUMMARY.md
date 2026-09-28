# Phase 3 Plan 04: UI Kit Primitives, Modals (D-05), and AppPalette Summary

Ported openGym's `components/ui.jsx` control set and `useUI` modal/toast actions into Material 3 Flutter widgets and native Navigator APIs (D-05), backed by an `AppPalette` theme extension matching openGym's CSS color variables.

## Delivered Artifacts

### 1. Palette & Theme Extension
- Created [lib/core/theme/app_palette.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/theme/app_palette.dart):
  - `AppPalette extends ThemeExtension<AppPalette>` supporting dark and light palettes for all openGym color variables: `acc`, `acc2`, `onAcc`, `red`, `orange`, `yellow`, `green`, `purple`, `blue`, `surface`, `surface2`, `surface3`, `sep`, `muted`, `dim`.
  - Contrast-aware `onAcc` resolution according to openGym `index.css:98-109`.
  - `cssVar(String token)` method resolving tokens like `var(--red)` or `--surface-2` (used by bridged facade outputs such as `effortColor`).
- Registered `AppPalette` in [lib/core/theme/app_theme.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/theme/app_theme.dart).

### 2. Layout, Button, Row, and Chip Primitives
- Created [lib/core/ui_kit/buttons.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/buttons.dart):
  - `AppButton` matching openGym `.btn` (variants: `plain`, `primary`, `tinted`, `ghost`, `danger`; block width by default, `small` option).
  - `AppIconButton` matching openGym `.iconbtn`.
- Created [lib/core/ui_kit/rows.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/rows.dart):
  - `ListItem` matching openGym `.item` (leading, title, subtitle, trailing, onTap, disabled).
  - `AppRow` matching `ui.jsx` `Row` (icon, iconTint, title, subtitle, value, accessory, danger, child).
  - `SectionHeader` matching `h4.sec` (uppercase, tracked, muted).
  - `ScreenHeader` matching `.hdr` (title, subtitle, trailing actions).
  - `AppCard` matching `.card` with optional accent border.
  - `AppTag` matching `.tag` and `.tag.acc`.
  - `EmptyState` matching `.empty` with icon circle and prompt.
- Created [lib/core/ui_kit/chips.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/chips.dart):
  - `ChipStrip<T>` with horizontal `ListView.builder` of selectable chips (`.chip`, `.chip.on`).
  - Auto-scrolls selected chip into view on selection change, mirroring openGym's `useRevealActiveChip`.

### 3. Form Controls & Sanitization
- Created [lib/core/ui_kit/number_field.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/number_field.dart):
  - `NumberField` implementing openGym's `commit()` logic: accepts `,` as `.`, strips non-digits, single decimal point enforcement, negative values converted to 0 unless nullable, empty converted to null/0.
  - Uses `num.tryParse` exclusively (zero crashes on malformed inputs).
  - `numWidthCh` width calculation for `fit` mode.
- Created [lib/core/ui_kit/controls.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/controls.dart):
  - `AppSwitch` (adaptive switch styled with `AppPalette`).
  - `AppSegmented<T>` (Material 3 `SegmentedButton<T>`).
  - `AppStepper` (−/+ buttons around a `NumberField`, step arithmetic matching `ui.jsx` Stepper).
  - `AppCheck` (circular openGym checkbox).
  - `AppSlider` (Material 3 `Slider` with custom accent/track theme).
  - `SearchField` (magnifier lead icon + clear button).
  - `SelectRow<T>` and `MultiSelectRow<T>` with bottom sheet pickers (`showSelectSheet`, `showMultiSelectSheet`).

### 4. Native Modal & Toast Infrastructure (D-05)
- Created [lib/core/ui_kit/modals.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/modals.dart):
  - `showAppSheet<T>` wrapping `showModalBottomSheet<T>` (rounded top corners, keyboard insets).
  - `showCenterDialog<T>` wrapping `showDialog<T>`.
  - Locked modal enforcement: `PopScope(canPop: !locked)`, `isDismissible: !locked`, `enableDrag: !locked` preventing accidental swipe/back dismissal for weigh-in and workout finish.
  - `showConfirmSheet` matching `ConfirmDialog`.
  - `showMenuSheet` matching `MenuSheet` (closes before running action callback).
  - `closeAllSheets` popping all popup routes via native Navigator.
  - Zero sheet-stack BLoCs/Cubits created (full adherence to D-05).
- Created [lib/core/ui_kit/toast.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/toast.dart):
  - `showToast(BuildContext, String)` presenting a floating snackbar for exactly 2200 ms (matching `useUI.js`).
- Created barrel [lib/core/ui_kit/ui_kit.dart](file:///Users/apple/projects/learning-project/open_exercise/lib/core/ui_kit/ui_kit.dart).

## Verification

1. **JS-04 Audit:** `bash tool/js04_audit.sh` -> PASS
2. **Static Analysis:** `flutter analyze` -> No issues found!
3. **Architecture Rules (D-05):** `grep -rnE "class \w*Sheet(Bloc|Cubit)" lib` -> 0 matches.
