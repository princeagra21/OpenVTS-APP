# OpenVTS Mobile UI/UX Design Guidelines

> **Product:** OpenVTS Flutter Mobile Application  
> **Platforms:** Android, iOS, and Flutter Web preview where useful  
> **Source of truth:** The production-ready OpenVTS Next.js web frontend design language, translated for native mobile.  
> **Primary goal:** Build a premium, consistent, touch-first fleet command center that feels like the same brand as the OpenVTS web app, not a generic Flutter admin template.

---

## 0. How GitHub Copilot must use this document

Paste this file into the Flutter project documentation and treat it as the UI/UX contract for every mobile screen.

When Copilot creates or edits UI code, it must:

1. Follow the OpenVTS design language in this document.
2. Use existing theme tokens and shared widgets first.
3. Avoid raw Material widgets when an OpenVTS/FS component already exists.
4. Avoid hardcoded colors, one-off spacing, one-off text styles, and random shadows.
5. Keep map screens visually powerful but restrained.
6. Keep CRUD/data screens calm, readable, fast, and consistent.
7. Preserve dark mode, RTL, safe areas, accessibility, and performance.

Copilot must not invent a new visual system unless this document explicitly asks for a new component.

---

## 1. Codebase context from review

The uploaded Flutter app already has a strong UI foundation:

```text
lib/core/theme/
  open_vts_colors.dart
  open_vts_spacing.dart
  open_vts_radius.dart
  open_vts_typography.dart
  open_vts_motion.dart
  open_vts_shadows.dart
  open_vts_theme.dart

lib/shared/widgets/
  fs_button.dart
  fs_card.dart
  fs_text_field.dart
  fs_toast.dart
  fs_empty_state.dart
  fs_error_view.dart
  fs_loading.dart
  fs_search_bar.dart
  fs_status_indicator.dart
  fs_data_table.dart

lib/shared/widgets/open_vts/
  open_vts_button.dart
  open_vts_card.dart
  open_vts_text_field.dart
  open_vts_page_scaffold.dart
  open_vts_feedback.dart
  open_vts_search_field.dart
  open_vts_status_chip.dart
  open_vts_bottom_sheet.dart
```

The web frontend design uses:

```text
--background: white/black
--foreground: black/white
--card-bg: translucent card surface
--border: subtle 0.5px border
--accent: dynamic monochrome/accent variable
Inter typography
glass-effect / premium-card / macos-card surfaces
```

The mobile app must translate that into Flutter using `OpenVtsTheme`, `OpenVtsColors`, `OpenVtsSpacing`, `OpenVtsRadius`, `OpenVtsTypography`, `OpenVtsMotion`, and shared OpenVTS widgets.

### Current UI debt discovered in the mobile codebase

These counts are from the uploaded Flutter app and should guide migration priority:

| Finding | Current count | What it means |
|---|---:|---|
| Dart files in `lib/` | 1,234 | Large app; consistency must be enforced by rules, not memory. |
| Total Dart lines in `lib/` | ~201k | Component reuse matters. |
| `updateLocalUiState` refs | 973 | Local UI state is centralized, but must remain UI-only. |
| Direct `ScaffoldMessenger` / `showSnackBar` refs | 726 | Feedback UI needs consolidation. |
| Direct `Colors.*` refs | 1,469 | Many widgets still bypass design tokens. |
| Direct `TextStyle(...)` refs | 252 | Typography migration is still needed. |
| Direct `ElevatedButton` refs | 201 | Buttons must migrate to `OpenVtsButton` / `FSButton`. |
| Direct `TextFormField` refs | 34 | Forms must migrate to `OpenVtsTextField` / `FSTextField`. |
| Direct `ListTile` refs | 89 | List rows must migrate to OpenVTS list patterns. |
| Direct `CircularProgressIndicator` refs | 32 | Main loaders should use OpenVTS loading/skeleton states. |

This document is therefore both a design guide and a migration gate.

---

## 2. OpenVTS mobile design philosophy

### 2.1 The product feeling

OpenVTS Mobile should feel like:

> A premium command center for fleet operations: calm, precise, monochrome, data-dense, fast, and trustworthy.

It should not feel like:

- A generic Material admin app.
- A colorful SaaS dashboard template.
- A heavy glassmorphism demo.
- A toy map app.
- A copied web layout squeezed into mobile.

### 2.2 The five design principles

#### 1. Premium restraint

Use fewer visual tricks. Use better spacing, alignment, contrast, and typography.

#### 2. Operational clarity

A fleet operator checks location, status, speed, ignition, stoppage, alerts, commands, and history. Design must reduce thinking time.

#### 3. Touch-first density

Mobile screens can be data-dense, but every tap target must remain usable.

#### 4. Map as command surface

The map is the hero experience. It deserves glass overlays, animated markers, and fast interactions. Normal CRUD screens should be calmer.

#### 5. One source of truth

Theme tokens and shared components define the UI. Screens only compose them.

---

## 3. Brand translation from web to mobile

### 3.1 Web-to-mobile mapping

| Web frontend concept | Mobile Flutter equivalent |
|---|---|
| `--background` | `OpenVtsColors.background` / `OpenVtsColors.darkBackground` |
| `--foreground` | `OpenVtsColors.textPrimary` / `OpenVtsColors.darkTextPrimary` |
| `--card-bg` translucent cards | `OpenVtsCard`, `FSCard`, map-only glass card |
| `--border` 0.5px | `OpenVtsBorders`, tokenized `BorderSide` |
| `--accent` dynamic brand color | `Theme.of(context).colorScheme.primary` |
| `.glass-effect` | map overlays and floating panels only |
| `.premium-card` | elevated data card, not every container |
| Inter font | `OpenVtsTypography` / app-wide font family |
| CSS dark class | `OpenVtsTheme.dark()` |

### 3.2 Mobile must not copy the web blindly

The web can use hover, dense tables, wide sidebars, and small controls. Mobile must use:

- bottom sheets instead of large modals,
- segmented controls instead of dense tabs where needed,
- full-width primary actions,
- larger touch targets,
- progressive disclosure,
- sticky map panels,
- swipe/pull gestures,
- one-column screen flow.

---

## 4. Theme tokens: mandatory usage

### 4.1 Color source of truth

Use these existing files:

```text
lib/core/theme/open_vts_colors.dart
lib/core/theme/app_colors.dart
lib/core/theme/open_vts_theme.dart
```

`OpenVtsColors` is the primary mobile design token source.

### 4.2 Core color direction

OpenVTS mobile should remain mostly monochrome:

| Token | Current value | Usage |
|---|---:|---|
| `OpenVtsColors.brandInk` | `#141118` | Primary brand ink, light-mode primary actions. |
| `OpenVtsColors.white` | `#FFFFFF` | Dark-mode primary accent and light card surface. |
| `OpenVtsColors.background` | `#FAFAFB` | Light screen background. |
| `OpenVtsColors.surface` | `#F4F3F6` | Light soft panels. |
| `OpenVtsColors.border` | `#E7E3EA` | Light borders. |
| `OpenVtsColors.darkBackground` | `#121015` | Dark screen background. |
| `OpenVtsColors.darkSurface` | `#1A1620` | Dark panels/cards. |
| `OpenVtsColors.darkBorder` | `#342D3D` | Dark borders. |
| `OpenVtsColors.textSecondary` | `#6B6570` | Secondary copy. |
| `OpenVtsColors.success` | `#2D6A4F` | Success and moving status. |
| `OpenVtsColors.warning` | `#8A5C1D` | Warning and idle status. |
| `OpenVtsColors.danger` | `#8A2E43` | Error and stopped status. |

### 4.3 Color rules

**Rule C1 — No raw colors in feature screens.**

Do not write:

```dart
Color(0xFF141118)
Colors.black
Colors.white
Colors.red
Colors.green
```

Use:

```dart
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.onSurface
OpenVtsColors.danger
OpenVtsColors.success
```

**Rule C2 — Status colors are data colors, not decoration.**

Green/red/orange should indicate vehicle movement, alerts, payment state, ticket state, or health. They should not decorate cards randomly.

**Rule C3 — Brand accent is scarce.**

Use primary accent for:

- primary CTA,
- active navigation item,
- focused input,
- selected chip,
- selected map marker,
- important link.

Do not use primary accent for every icon.

**Rule C4 — Backgrounds stay quiet.**

Most screens use `scaffoldBackgroundColor`, `OpenVtsCard`, and subtle borders. Avoid gradients unless the screen is onboarding, splash, or an intentionally branded empty state.

**Rule C5 — Dark mode is not inverted light mode.**

Dark mode must use `OpenVtsColors.darkBackground`, `darkSurface`, `darkBorder`, and dark text tokens. Do not manually invert colors.

---

## 5. Typography system

### 5.1 Font

The web app uses Inter. Mobile should also use Inter.

Recommended action:

- Bundle Inter locally in `assets/fonts/Inter/` for production reliability, or
- use a package only if the team accepts the dependency.

Current `OpenVtsTypography.fontFamily` is `null`; the future target should be Inter as the explicit app font.

### 5.2 Type scale

Use existing text theme and OpenVTS typography tokens.

| Purpose | Recommended style |
|---|---|
| Dashboard KPI number | `headlineLarge` / explicit tabular numeric style |
| Page title | `titleLarge` or `headlineSmall` |
| Card title | `titleMedium` |
| List title | `titleSmall` / `titleMedium` |
| Body copy | `bodyMedium` |
| Metadata/timestamp | `bodySmall` |
| Button label | `labelLarge` |
| Chip/status label | `labelMedium` / `labelSmall` |

### 5.3 Typography rules

**Rule T1 — No raw `TextStyle` in screens.**

Allowed:

```dart
Theme.of(context).textTheme.bodyMedium?.copyWith(
  color: Theme.of(context).colorScheme.onSurfaceVariant,
)
```

Avoid:

```dart
TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)
```

**Rule T2 — Use tabular figures for fleet numbers.**

Use tabular figures for speed, odometer, distance, coordinates, timestamps, and counts.

**Rule T3 — Do not use tiny text.**

Minimum body label: 12sp. Minimum micro badge: 11sp.

**Rule T4 — Headings must be short.**

Mobile headings should be operational, not marketing-heavy.

Good:

```text
Vehicles
Live Map
Driver Details
Notification Rules
```

Bad:

```text
Manage All Your Vehicle Tracking Preferences
```

---

## 6. Spacing and layout grid

### 6.1 Use the existing OpenVTS spacing scale

```dart
OpenVtsSpacing.xs   // 4
OpenVtsSpacing.sm   // 8
OpenVtsSpacing.md   // 12
OpenVtsSpacing.lg   // 16
OpenVtsSpacing.xl   // 20
OpenVtsSpacing.xxl  // 24
OpenVtsSpacing.xxxl // 32
```

### 6.2 Spacing rules

**Rule S1 — Every spacing must be tokenized.**

Do not write arbitrary values like `17`, `23`, `31`, or `7.5`.

**Rule S2 — Default screen padding is 16dp.**

Use `OpenVtsSpacing.pagePadding` or `EdgeInsets.all(OpenVtsSpacing.lg)`.

**Rule S3 — Full-bleed is only for maps and media.**

Map screens can go edge-to-edge. Most CRUD screens need 16dp horizontal padding.

**Rule S4 — Bottom navigation clearance is mandatory.**

Scrollable content must include bottom padding so the final card is not hidden behind nav or safe area.

**Rule S5 — Use vertical rhythm.**

Standard layout:

```text
Page header
16-24 gap
Search/filter row
12-16 gap
Cards/list
80 bottom clearance
```

---

## 7. Radius, border, shadow, and glass

### 7.1 Radius tokens

Use:

```dart
OpenVtsRadius.radiusSm // 8
OpenVtsRadius.radiusMd // 12
OpenVtsRadius.radiusLg // 16
OpenVtsRadius.radiusXl // 20
OpenVtsRadius.pill     // 999
```

### 7.2 Borders

OpenVTS should use precise, subtle borders.

Rules:

- Most cards: subtle border + no heavy elevation.
- Input focus: primary border.
- Selected chips: primary border/background.
- Danger actions: danger border/background.

### 7.3 Shadows

Use shadows sparingly. Most mobile enterprise UI should rely on layers, borders, spacing, and contrast.

Allowed:

- cards with very subtle shadow,
- bottom sheets,
- floating map controls,
- FABs,
- selected marker panels.

Avoid:

- heavy shadows on every list item,
- multiple shadows stacked with blur,
- colorful glows,
- neumorphism.

### 7.4 Glassmorphism rule

The web uses glass; mobile must use it with restraint.

Use glass on:

- map overlay panels,
- live vehicle info dock,
- floating map controls,
- route/replay metrics overlay,
- selected marker detail panel.

Do not use glass on:

- every data card,
- forms,
- long lists,
- settings rows,
- tables.

Glass must have:

- blur,
- semi-transparent surface,
- 0.5px border,
- readable text,
- no heavy shadow.

---

## 8. Component rules

### 8.1 Component priority

When building UI, use this priority order:

1. `shared/widgets/open_vts/*` component if available.
2. `shared/widgets/fs_*` facade if that is the feature convention.
3. A new shared component if pattern repeats at least twice.
4. Raw Flutter widget only for low-level composition.

### 8.2 Buttons

Use:

```dart
OpenVtsButton(...)
FSButton(...)
```

Do not use directly in feature screens:

```dart
ElevatedButton
TextButton
OutlinedButton
```

Button rules:

- One primary action per screen.
- Destructive action uses danger variant.
- Loading action disables itself.
- Primary action is full-width on mobile forms.
- Icon-only buttons must have minimum 44dp tap target.
- Button text uses label style and SemiBold.

### 8.3 Text fields

Use:

```dart
OpenVtsTextField(...)
FSTextField(...)
```

Do not use raw `TextFormField` directly in screens.

Field rules:

- Labels above fields for complex forms.
- Prefix icon only when it improves recognition.
- Error text below the input.
- Helper text disappears when error exists.
- Use `TextInputAction.next` and `TextInputAction.done` correctly.
- Use keyboard type for email, phone, number, URL.
- Use autofill hints for login/profile forms.

### 8.4 Cards

Use:

```dart
OpenVtsCard(...)
FSCard(...)
```

Card rules:

- Use cards for meaningful groups, not every row.
- Use consistent padding.
- Keep card title, metadata, and action order consistent.
- Use border and subtle surface difference.
- Use tap feedback if card is interactive.

### 8.5 Feedback and toast

Preferred:

```dart
OpenVtsFeedback.success(context, 'Saved successfully');
OpenVtsFeedback.error(context, 'Failed to save. Please try again.');
```

Do not call `ScaffoldMessenger.of(context).showSnackBar(...)` directly from feature screens.

Current codebase has many direct snackbars. New work must stop adding more.

Feedback rules:

- Success: short confirmation.
- Error: explain recoverable action.
- Warning: use only when decision matters.
- Info: use sparingly.
- Do not show raw API error maps.
- Do not show stack traces.

### 8.6 Lists

Avoid raw `ListTile` in feature screens. Use OpenVTS list pattern or create `OpenVtsListTile`/`FSListTile` consistently.

List rules:

- Minimum row height: 56dp.
- Leading icon/avatar: 32-40dp.
- Title one line.
- Metadata one or two lines.
- Important status as chip/pill.
- Swipe actions only when safe and confirm destructive actions.
- Use `ListView.builder` for dynamic lists.

### 8.7 Loading states

Use:

- skeleton for full-screen data loading,
- small spinner only inside buttons or small inline areas,
- shimmer for card/list placeholders,
- pull-to-refresh for reloadable lists.

Avoid:

- blank screens,
- full-screen `CircularProgressIndicator` as the main UX,
- loading dialogs for normal fetches,
- changing layout height during loading.

### 8.8 Empty states

Use `FSEmptyState` / OpenVTS empty pattern.

Empty states must include:

- clear title,
- short explanation,
- optional primary action,
- relevant icon or visual,
- no blame language.

Examples:

```text
No vehicles found
Try changing the filter or add a new vehicle.
```

```text
No route history
This vehicle has no route data for the selected date.
```

### 8.9 Error states

Use `FSErrorView` / OpenVTS error pattern.

Error states must include:

- human message,
- retry action where possible,
- no raw backend exception,
- support/diagnostics path for repeated failure.

---

## 9. Screen patterns

### 9.1 App shell

The shell should feel stable and predictable.

Rules:

- Bottom navigation for primary mobile sections.
- No more than 5 primary bottom nav items.
- Secondary sections go under More/Settings.
- Role-specific navigation must be consistent.
- Active nav uses primary/accent token.
- Do not mix drawer and bottom nav unless a tablet layout explicitly needs it.

### 9.2 Dashboard screen

Dashboard should answer: “What needs attention right now?”

Structure:

```text
Greeting / role context
Critical KPI strip
Live status summary
Alert/recent activity card
Quick actions
```

Dashboard cards:

- use big numbers,
- show trend/status only when useful,
- avoid chart overload,
- keep each KPI readable in 3 seconds.

### 9.3 Vehicle list screen

Structure:

```text
Page header
Search bar
Status filter chips
Vehicle cards/list
```

Each vehicle row/card should show:

- plate/name,
- status,
- speed or last location summary,
- last update time,
- assigned driver/user where relevant,
- quick action only when frequently used.

### 9.4 Vehicle detail screen

Use progressive disclosure.

Recommended sections:

```text
Header with vehicle identity + status
Live metrics grid
Current location/address
Tabs/segments:
  Overview
  History
  Commands
  Documents
  Settings/Config
```

Do not put every property on the first screen.

### 9.5 Form screens

Structure:

```text
Header
Short helper description if needed
Grouped fields
Sticky/full-width primary action
```

Rules:

- Group related fields.
- Use required indicators.
- Validate inline.
- Prevent double submit.
- Keep destructive actions at bottom and separated.
- Show confirmation for irreversible changes.

### 9.6 Settings screens

Settings should use grouped rows.

Rules:

- Use section headers.
- Use switches/chips for simple toggles.
- Use bottom sheets for selection.
- Explain enterprise-impact settings.
- Keep dangerous settings in a separate danger zone.

### 9.7 Support/ticket screens

Support must feel trustworthy.

Rules:

- Show ticket status clearly.
- Keep conversation messages readable.
- Use attachment cards.
- Show timestamps per user locale.
- Do not overload with admin metadata unless role needs it.

### 9.8 Admin and superadmin screens

Mobile admin is not desktop admin. Prioritize operational tasks.

Rules:

- Use search first.
- Use filters via bottom sheet.
- Use detail screens over wide tables.
- Use bulk actions carefully.
- Use confirmation sheets for credit/payment/security changes.

---

## 10. Map and real-time UI rules

The map is OpenVTS’s most important mobile surface.

### 10.1 Map layer structure

Keep layers separated conceptually:

```text
Tile layer
Visual effect layer
Route/polyline layer
Geofence/POI layer
Live vehicle marker layer
Selected vehicle overlay
Map controls
Bottom sheet/dock
```

### 10.2 Map visual effect rule

Visual effects must apply only to the tile/map layer, not the entire screen UI.

Never blur, grayscale, dim, or invert the whole page including controls.

### 10.3 Live marker rules

Markers should:

- use vehicle type icon where available,
- show selected state clearly,
- animate movement smoothly,
- avoid janky rotation,
- show status color intentionally,
- keep labels optional,
- avoid rebuilding tile layer.

### 10.4 Selected vehicle bottom panel

Selected vehicle panel should show:

- plate/name,
- status,
- speed,
- ignition,
- last update,
- address/location,
- quick actions: details, replay/history, command where permitted.

Use glass only if overlaying map. Use normal card if on a detail screen.

### 10.5 Route/history replay

Replay UI should show:

- start/end points,
- route line,
- directional arrows at reasonable intervals,
- stoppage points,
- top/right or bottom metrics panel,
- speed/distance/engine hours/odometer metrics,
- play/pause/speed controls.

Route line style:

- subtle, high contrast enough against map,
- not neon,
- not thick enough to hide roads,
- directional arrows visible but not noisy.

### 10.6 Map controls

Controls should be:

- floating,
- glass or solid depending on readability,
- 44dp minimum tap target,
- grouped by task,
- not scattered everywhere.

---

## 11. Data display rules

### 11.1 Unknown values

Use:

```text
—
```

Do not show:

```text
null
undefined
N/A
0
```

Zero has meaning in fleet data. Unknown is not zero.

### 11.2 Dates and times

Use user settings for:

- date format,
- time format,
- timezone,
- locale.

Never show raw UTC unless a technical diagnostic screen explicitly needs it.

### 11.3 Units

Use configured units:

- KM / miles,
- km/h / mph,
- liters/gallons if later added.

Do not hardcode `km` in reusable components.

### 11.4 Coordinates

Coordinates should be shown only when useful.

List view:

```text
Address or area name preferred
```

Detail/diagnostics:

```text
lat/lng with controlled precision
```

### 11.5 IDs and IMEI

- IMEI/device ID can be shortened in list view.
- Show full IMEI in detail view with copy action.
- Never truncate plate numbers.

---

## 12. Role-based UI rules

Roles in the product include:

```text
SUPERADMIN
ADMIN
USER
SUBUSER
TEAM
DRIVER
```

UI must adapt by role and permission.

Rules:

- Hide actions the user cannot perform.
- Disable only when the action exists but is temporarily unavailable.
- Never show a CTA that will certainly fail due to permission.
- Backend remains the authority; UI permission is UX only.
- Dangerous actions require confirmation.
- Superadmin screens can expose technical controls; user screens should be simpler.

---

## 13. Motion and interaction

### 13.1 Motion timing

Use `OpenVtsMotion`:

```dart
OpenVtsMotion.instant // 100ms
OpenVtsMotion.fast    // 180ms
OpenVtsMotion.medium  // 260ms
OpenVtsMotion.slow    // 360ms
```

### 13.2 Motion rules

- Button/card press feedback should be immediate.
- Bottom sheets should slide naturally.
- Screen transitions should be calm.
- Map marker motion can be longer but must remain smooth.
- Loading skeleton can loop.
- Avoid bouncy effects in enterprise data screens.
- Respect `MediaQuery.disableAnimations`.

### 13.3 Gesture rules

Use:

- tap for primary action,
- long press for contextual action,
- pull to refresh on lists,
- swipe carefully for secondary/destructive actions,
- pinch/double tap only on map,
- drag to dismiss bottom sheets.

---

## 14. Accessibility rules

Every screen must pass these checks:

- Minimum touch target: 44dp.
- Text contrast meets WCAG AA.
- Color is never the only state indicator.
- Icon-only buttons have `tooltip` or `Semantics` label.
- Images/icons that convey meaning have `semanticsLabel`.
- Dynamic font scaling should not break layout.
- Forms have autofill hints where applicable.
- Map overlays remain readable in dark and light mode.

---

## 15. RTL and localization rules

Use:

```dart
EdgeInsetsDirectional
AlignmentDirectional
TextAlign.start
CrossAxisAlignment.start
BorderRadiusDirectional when asymmetric
```

Avoid:

```dart
EdgeInsets.only(left: ...)
Alignment.centerLeft
TextAlign.left
```

All user-visible strings should become localizable. Avoid hardcoded English in reusable widgets.

---

## 16. Performance rules for UI

### 16.1 Lists

- Use `ListView.builder` for dynamic lists.
- Use pagination for long lists.
- Use pull-to-refresh.
- Avoid nested scroll views unless necessary.
- Use `AutomaticKeepAliveClientMixin` for expensive tab screens.

### 16.2 Images

Use `CachedNetworkImage` for remote images. Avoid raw `Image.network`.

### 16.3 Maps

- Wrap map and heavy layers in `RepaintBoundary`.
- Do not rebuild the whole map for marker updates.
- Keep marker data UI-ready before it reaches the widget.
- Avoid processing route history inside `build()`.

### 16.4 Build method

Do not perform:

- API calls,
- parsing,
- sorting large lists,
- route simplification,
- raw JSON mapping,
- permission calculations that can be provider-driven.

Inside `build()`, compose widgets from state.

---

## 17. Migration rules for existing UI

### 17.1 Replace direct widgets gradually

| Current pattern | Target pattern |
|---|---|
| `ElevatedButton`, `TextButton`, `OutlinedButton` | `OpenVtsButton` / `FSButton` |
| `TextFormField` | `OpenVtsTextField` / `FSTextField` |
| `Container` used as card | `OpenVtsCard` / `FSCard` |
| `ScaffoldMessenger.showSnackBar` | `OpenVtsFeedback` / fixed `FSToast` |
| `CircularProgressIndicator` full screen | `FSLoading` / skeleton screen |
| `ListTile` | OpenVTS list row component |
| raw `Colors.*` | `Theme.of(context).colorScheme` / `OpenVtsColors` |
| raw `TextStyle` | `Theme.of(context).textTheme` / `OpenVtsTypography` |

### 17.2 Do not rewrite everything at once

When modifying a screen:

1. Fix the touched area fully.
2. Do not add new violations.
3. Extract repeated UI patterns.
4. Keep behavior unchanged unless the task asks for behavior changes.
5. Ensure dark mode still works.

---

## 18. Screen acceptance checklist

Before a screen is considered production-grade:

### Visual

- [ ] Uses OpenVTS tokens for colors.
- [ ] Uses OpenVTS typography.
- [ ] Uses 4pt spacing/token scale.
- [ ] Uses consistent border radius.
- [ ] Looks correct in light mode.
- [ ] Looks correct in dark mode.
- [ ] No random gradients or flashy colors.

### Component

- [ ] Uses OpenVTS/FS buttons.
- [ ] Uses OpenVTS/FS fields.
- [ ] Uses OpenVTS/FS cards.
- [ ] Uses OpenVTS feedback.
- [ ] Uses reusable empty/error/loading states.
- [ ] Avoids duplicate component implementations.

### Mobile usability

- [ ] Touch targets are at least 44dp.
- [ ] Safe areas are respected.
- [ ] Keyboard does not cover main action.
- [ ] Pull-to-refresh exists on data lists.
- [ ] Destructive actions confirm.
- [ ] Loading state prevents double submit.

### Data clarity

- [ ] Unknown values use `—`.
- [ ] Dates/times follow settings.
- [ ] Units follow settings.
- [ ] IDs/IMEI display safely.
- [ ] Status is shown with text/icon, not color alone.

### Performance

- [ ] Lists use builder/sliver APIs.
- [ ] Static widgets are `const` where possible.
- [ ] Heavy widgets use `RepaintBoundary`.
- [ ] Provider watches are scoped.
- [ ] No heavy work inside `build()`.

---

## 19. The absolute UI/UX don'ts

Do not:

- create a new color system inside a feature,
- use raw `Colors.*` in screens,
- create a new button style inside a screen,
- create a new text field style inside a screen,
- use full-screen loaders for normal list fetches,
- show raw API errors,
- use glass cards everywhere,
- use neon status colors,
- hide important actions behind tiny icons,
- use left/right constants instead of directional layout,
- make map controls too small,
- rebuild the whole map for live telemetry,
- show stale GPS data as live,
- use decorative animation that slows operations,
- copy desktop web tables directly into mobile.

---

## 20. Copilot instruction block for UI work

Use this block when asking Copilot to create or refactor screens:

```text
You are working on the OpenVTS Flutter mobile app.
Follow docs/OpenVTS_Mobile_UI_UX_Design_Guidelines.md exactly.

Design target:
- Premium OpenVTS command-center UI.
- Monochrome, precise, restrained, enterprise-grade.
- Match the Next.js web app design DNA, but use native mobile patterns.

Rules:
- Use OpenVTS theme tokens from lib/core/theme.
- Use shared OpenVTS/FS widgets before raw Flutter widgets.
- No hardcoded colors, no raw TextStyle, no random spacing.
- No direct ScaffoldMessenger in feature screens; use OpenVtsFeedback/FSToast pattern.
- No raw ElevatedButton/TextButton/OutlinedButton when OpenVtsButton/FSButton fits.
- No raw TextFormField when OpenVtsTextField/FSTextField fits.
- Keep dark mode, RTL, accessibility, and safe areas intact.
- For maps, keep tile layer independent from marker/overlay rebuilds.
- Use skeleton/empty/error states consistently.

Before finishing, review the changed file against the checklist in the guideline document.
```
