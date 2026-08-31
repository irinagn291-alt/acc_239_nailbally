# Nailbally — Build Specification

> Portfolio app 57, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Land a slice. Nail it for the round.

| Field | Value |
| --- | --- |
| Product name | Nailbally |
| Bundle identifier | `com.nailbally.felt` |
| Domain | https://nailbally-felt.pro |
| Contact URL | https://nailbally-felt.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `nbl_` |
| User-Agent | `Nailbally/1.0 (iOS; +https://nailbally-felt.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Nailbally -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A land nails the slice.

### 2.1 User flow

1. Open the arena and load a pack or type the room onto the wheel
2. Flick the wheel; it coasts clockwise and lands on an open slice
3. That slice takes a nail and drops out of the next draw
4. Keep spinning until every live name is nailed; the nails then lift and the next round starts
5. Open the night sheet to read the order of lands
6. Adjust packs and haptics from Settings as a sheet

### 2.2 Essential behaviour

- Full-screen physical wheel: 360/n slices, clockwise, plus 5–7 turns, about 3.4s, land on slice centre
- Fair-share nails: the land solver samples only open names; a nailed centre is never a valid land
- When one name remains open it is awarded without a spin, then the nails lift together
- Named slices and dare packs stored locally
- Haptics ease into a landing climax, with a second tick when a nail seats
- Night history keyed as YYYYMMDD, shown as a sheet, not a pushed Detail
- Empty felt: add names or a pack. No Circuit, Neon, or Game tab

---

## 3. Uniqueness assignment for Nailbally

| Axis | Assigned value |
| --- | --- |
| Architecture | **Bitmask pie (open AND NOT nailed; land is an index through the mask)** |
| UI approach | **SwiftUI hosting a UIView with a CAReplicatorLayer pie (CATransform3D rotation on the replicator; nails are sibling CALayers)** |
| Naming convention | **Carnival midway lexicon** |
| File organization | **By round role (Felt, Slice, Nail, Night)** |
| Dependency strategy | **None** |
| Design direction | **Carnival tent (striped canvas, sawdust floor, ticket gold, night navy)** |
| Typography | **SF Pro** |
| Navigation pattern | **Felt-locked chrome (the wheel never leaves; nights and settings arrive as sheets)** |
| AI art style | **Vintage carnival sideshow banner (painted canvas, ornate lettering, sawdust apron)** |
| Functional twist | **Fair-share nail (a landed slice cannot land again until every other live name has)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — party_spinner

**Core** — A land nails the slice.

**Audience** — Hosts who spin names or dares for a room and are tired of the same person coming up twice.

**User flow**

1. Open the arena and load a pack or type the room onto the wheel
2. Flick the wheel; it coasts clockwise and lands on an open slice
3. That slice takes a nail and drops out of the next draw
4. Keep spinning until every live name is nailed; the nails then lift and the next round starts
5. Open the night sheet to read the order of lands
6. Adjust packs and haptics from Settings as a sheet

**Essential features**

- Full-screen physical wheel: 360/n slices, clockwise, plus 5–7 turns, about 3.4s, land on slice centre
- Fair-share nails: the land solver samples only open names; a nailed centre is never a valid land
- When one name remains open it is awarded without a spin, then the nails lift together
- Named slices and dare packs stored locally
- Haptics ease into a landing climax, with a second tick when a nail seats
- Night history keyed as YYYYMMDD, shown as a sheet, not a pushed Detail
- Empty felt: add names or a pack. No Circuit, Neon, or Game tab

**Twist** — Fair-share nail. After a slice lands, that name is nailed for the rest of the round — the land solver draws only from open names, never the full pie. Keep spinning until every live name is nailed; then the nails lift together and the next round starts. History is the order of a night, not a bag of isolated winners. A late joiner sits open. Removing a name mid-round lifts only that nail.

**Why this is not a repeat** — First party_spinner in the portfolio: a physical wheel for a room, not a typed random_picker reveal and not a habit week. Falspark parks a miss on a week wheel; this app nails a landed name so the same person cannot be drawn twice in one round — the home act is nail-the-slice, not park-a-grace. Occupath refuses a second train on a token; here every name stays on the pie and only leaves the draw set. No food, no slots, no catalog search. Unique axes are new carnival values; screens take the free No Detail screen so the land reads on the hub.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Full-screen wheel. Spin is physical.
- Invariant: Pick first, then rotate: 360/n slices, clockwise, +5–7 turns, land on slice centre. ~3.4s. Haptics ease into a landing climax.
- Never: No Circuit / Neon mini-game tab.
- Desk `pack_balance`: fill=Σvol/cap; balanceXY=weight-avg of zones; readiness mixes clip(weight), clip(fill), balance.

### 3.1 Architecture contract

The pie is two unsigned masks over the same slice index space: open for live names on the felt, nailed for names already landed this round. Eligible bits are open AND NOT nailed; the land solver never samples the full pie. It counts set bits in the eligible mask, draws an ordinal in that count, walks the mask to that bit, and returns the slice index. A land writes that bit into nailed; the replicator still shows every open slice, only the draw set shrinks. When the eligible count is one, that index is awarded without a rotation; when it is zero, every nail lifts together and nailed clears. A late joiner sets their open bit and stays eligible; removing a name clears that bit in both masks so only that nail lifts.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

SwiftUI owns chrome and sheets. The felt is a UIViewRepresentable hosting a CAReplicatorLayer whose instance count is the live slice count; each replica is one wedge, and the pie rotates with CATransform3D on the replicator, never by swapping SwiftUI Shape angles. Nails are sibling CALayers seated on landed centres, not replicas. Spin contract: pick the land index first from the eligible mask, then animate clockwise 360/n per slice plus 5 to 7 full turns, stop on the slice centre, duration about 3.4s. Haptics ease into a landing climax; a second tick fires when the nail layer seats. Empty felt is a full page (frame(maxHeight: .infinity)) with art, headline, one line, and a bottom full-width CTA.

### 3.3 Naming contract

Convention: Carnival midway lexicon.

Examples to follow: `Felt`, `Slice`, `Nail`, `Night`

### 3.4 Dependency contract

None. Zero SPM packages; project.yml has no packages key. No URLSession catalog and no AVFoundation. The pie, nails, packs, and night order stay on device.

### 3.5 Navigation contract

Felt-locked chrome: the wheel never leaves the window. iPad is a full-screen NavigationSplitView (not a form-sheet iPhone frame): Arena stays in the master column, History and Settings occupy the detail column. On iPhone those destinations arrive as sheets over the felt, never a pushed Detail that replaces the wheel. No tab bar. Onboarding Next is bottom and full width. Read ProcessInfo.processInfo.arguments once after onboarding is done.

### 3.6 Screen composition contract

Master detail split. Physical screens: Arena, History, Settings. Arena is the felt (root): full-screen CAReplicatorLayer pie; empty felt is a full page to add names or a pack. History is the night order as a sheet on iPhone and the detail column on iPad, keyed as Int YYYYMMDD, not a bag of isolated winners and not a pushed Detail. Settings is a sheet: packs, haptics, contact URL to https://nailbally-felt.pro, resetAllData, re-run onboarding. ReviewScreen is read once after onboarding: today=Arena, log=History, goals=Settings. No Today, Scan, Search, Goals, Circuit, or Neon screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By round role (Felt, Slice, Nail, Night)**

```
Nailbally/
  Felt/
Slice/
Nail/
Night/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Arena
A first-class screen for **Arena**. Must render empty, populated and error states.

### 5.3 History
A first-class screen for **History**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **SpinSet** — named per this app's convention.
- **SpinResult** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Carnival tent (striped canvas, sawdust floor, ticket gold, night navy)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#0B1020` | Screen background |
| `surface` | `#1A2238` | Cards, rows, sheets |
| `ink` | `#F3E6C4` | Primary text and icons |
| `accent` | `#E6B422` | Primary action, key figure, progress fill |
| `muted` | `#A8946C` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro via .system only. At most six steps behind one accessor; weights carry hierarchy. No Font.custom fixedSize. Text stays at least 12pt and tracks Dynamic Type. Night keys and slice counts go through NumberFormatter; day edges use Calendar.current.startOfDay then fold to YYYYMMDD.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

One Codable felt document (slices, packs, open and nailed masks, nights) encoded to JSON in UserDefaults under a single key. UI never touches UserDefaults. Debounced saves after every land, join, remove, and lift so a force-quit cannot lose the round. Nights are keyed by Int in YYYYMMDD form. resetAllData() is reachable from Settings and tests. Simulator seed only, once, behind nbl.demo.v1: write a demo pack onto the felt and mark onboarding complete in the same seed. Never seed on a device.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Nailbally/1.0 (iOS; +https://nailbally-felt.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.lifestyle`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.lifestyle
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Fair-share nail (a landed slice cannot land again until every other live name has)

Fair-share nail is the home verb: after a slice lands, that name is nailed for the rest of the round and the land solver draws only from open-and-not-nailed bits. The same person cannot land twice until every other live name has; every name stays on the pie and only leaves the draw set. When one name remains open it is awarded without a spin, then the nails lift together and the next round starts. History is the order of a night keyed as an Int in YYYYMMDD form, shown as a sheet, not a bag of isolated winners. A late joiner sits open; removing a name mid-round lifts only that nail. Cover the mask walk, the last-open award, and the lift-all reset with a unit test; a coin flip or a text reveal without rotation math fails the family.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Vintage carnival sideshow banner (painted canvas, ornate lettering, sawdust apron)**

Base prompt, reused and extended for every asset:

```
Vintage carnival sideshow banner, painted canvas, ornate lettering kept off the app icon, sawdust apron, red-and-cream striped tent, ticket gold and night navy, dark midway lighting, no readable words, no rounded mask, no drop shadow outside the canvas
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `nbl_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `nbl_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `nbl_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `nbl_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `nbl_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `nbl_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `nbl_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `nbl_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `nbl_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `nbl_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `nbl_TwistHero` | 1024x1024 | allowed | Hero art for the 'Fair-share nail (a landed slice cannot land again until every other live name has)' feature screen. |
| 11 | `nbl_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `nbl_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`nbl_AppIcon`** — 1024x1024

```
Vintage carnival sideshow banner style, a single iron nail driven through the centre of a painted prize wheel, striped tent canvas and ticket gold on night navy, emblem filling the canvas, no text, no words, no alpha, no rounded corners, no drop shadow
```

**`nbl_Splash`** — 1290x2796

```
Vertical carnival tent interior at night, striped canvas walls, sawdust floor, quiet uncluttered centre band, ticket gold trim, no readable words
```

**`nbl_Onboarding1`** — 1024x1536

```
An empty painted prize wheel on a carnival felt, waiting for names, vintage sideshow banner style, sawdust apron, inviting not sad
```

**`nbl_Onboarding2`** — 1024x1536

```
A hand flicking a carnival prize wheel mid-spin, clockwise motion, painted canvas, ticket gold nail hovering over a slice
```

**`nbl_Onboarding3`** — 1024x1536

```
A carnival wheel with every slice nailed, a night sheet of land order beside the sawdust apron, sideshow banner lighting
```

**`nbl_EmptyHome`** — 1024x1024

```
Empty carnival felt and a prize wheel with no slices yet, painted canvas, sawdust floor, calm and inviting, never sad
```

**`nbl_EmptyList`** — 1024x1024

```
An empty night ledger on ticket stock, no lands written, carnival banner ornament, inviting not sad
```

**`nbl_CardBackdrop`** — 1200x800

```
Low-contrast striped carnival canvas and sawdust texture, dark navy and faded gold, quiet enough for text on top
```

**`nbl_ControlFace`** — 512x512

```
The head of a carnival prize-wheel nail, iron and ticket gold, painted sideshow style, centred on a dark navy field
```

**`nbl_TwistHero`** — 1024x1024

```
A fair-share nail seated in a landed slice while the rest of the painted wheel stays open, vintage sideshow banner, ticket gold on night navy
```

**`nbl_SuccessMark`** — 512x512

```
A ticket punch and a seated nail on painted canvas, carnival gold confirmation mark, no text
```

**`nbl_HeaderDecor`** — 1200x600

```
Wide vintage sideshow banner ornament, ornate painted scrollwork, sawdust apron stripe, ticket gold on night navy, no readable words
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. Never seed on a physical device. Guard with
`#if targetEnvironment(simulator)` and `nbl.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `NailballyTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Snapshot unit tests for every main screen named in section 3.6.
   Each of those screens must be a `*View` or `*Screen` type that constructs
   with no arguments (demo fixtures inside the view). The factory runs these
   tests on iPhone and iPad and keeps the PNGs.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Nailbally -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **Bitmask pie (open AND NOT nailed; land is an index through the mask)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI hosting a UIView with a CAReplicatorLayer pie (CATransform3D rotation on the replicator; nails are sibling CALayers)**.
- [ ] Navigation matches **Felt-locked chrome (the wheel never leaves; nights and settings arrive as sheets)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Nailbally
xcodegen generate
xcodebuild -scheme Nailbally -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Nailbally -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
