# Nailbally

Land a slice. Nail it for the round.

Nailbally is a carnival midway wheel for hosts who spin names or dares for a room and are tired of the same person coming up twice. The home screen *is* the wheel. Flick it; it coasts clockwise and lands on an open slice. That name takes a nail and leaves the draw until every other live name has landed. When the last open is awarded, the nails lift together and the next round starts.

No account, no ads, no Game tab. The felt is the mechanic.

## Architecture

Bitmask pie: two unsigned masks over the same slice index space. `open` is who sits on the felt. `nailed` is who already landed this round. Eligible bits are `open AND NOT nailed`. The land solver never samples the full pie. It counts set bits in the eligible mask, draws an ordinal in that count, walks the mask to that bit, and returns the slice index.

That pattern fits this product because the wheel still shows every live name — only the draw set shrinks. A late joiner sets an open bit and stays eligible. Removing a name clears that bit in both masks so only that nail lifts.

SwiftUI owns chrome and sheets. The pie is a `UIView` with a `CAReplicatorLayer`: instance count is the live slice count, rotation is `CATransform3D` on the replicator, and nails are sibling `CALayers`, not replicas. Spin contract: pick first, then rotate clockwise 360/n plus 5–7 turns, stop on the slice centre, about 3.4s.

One Codable felt document (slices, packs, masks, nights) is encoded to JSON in UserDefaults and projected to an atomic file. Views never touch storage.

## Fair-share nail

This is why a host would pick the app. After a slice lands, that name is nailed for the rest of the round. The same person cannot land twice until every other live name has. History is the order of a night keyed as YYYYMMDD, shown as a sheet, not a bag of isolated winners. When one name remains open it is awarded without a spin, then the nails lift together.

## Design

Carnival tent: striped canvas, sawdust floor, ticket gold, night navy. Palette tokens live in `Assets.xcassets` and are reached only through `TentInk`: background `#0B1020`, surface `#1A2238`, ink `#F3E6C4`, accent `#E6B422`, muted `#A8946C`. Typography is **SF Pro** through `.system` only. Spacing unit 8 pt. Corner radius 4 pt. Tap targets 44 pt. Navigation is felt-locked: the wheel never leaves; Night and Booth arrive as sheets on iPhone and the detail column on iPad. No tab bar.

## AI art style

Vintage carnival sideshow banner (painted canvas, ornate lettering, sawdust apron).

Base prompt reused for every asset:

```
Vintage carnival sideshow banner, painted canvas, ornate lettering kept off the app icon, sawdust apron, red-and-cream striped tent, ticket gold and night navy, dark midway lighting, no readable words, no rounded mask, no drop shadow outside the canvas
```

| Image set | Prompt |
| --- | --- |
| `nbl_AppIcon` | Vintage carnival sideshow banner style, a single iron nail driven through the centre of a painted prize wheel, striped tent canvas and ticket gold on night navy, emblem filling the canvas, no text, no words, no alpha, no rounded corners, no drop shadow |
| `nbl_Splash` | Vertical carnival tent interior at night, striped canvas walls, sawdust floor, quiet uncluttered centre band, ticket gold trim, no readable words |
| `nbl_Onboarding1` | An empty painted prize wheel on a carnival felt, waiting for names, vintage sideshow banner style, sawdust apron, inviting not sad |
| `nbl_Onboarding2` | A hand flicking a carnival prize wheel mid-spin, clockwise motion, painted canvas, ticket gold nail hovering over a slice |
| `nbl_Onboarding3` | A carnival wheel with every slice nailed, a night sheet of land order beside the sawdust apron, sideshow banner lighting |
| `nbl_EmptyHome` | Empty carnival felt and a prize wheel with no slices yet, painted canvas, sawdust floor, calm and inviting, never sad |
| `nbl_EmptyList` | An empty night ledger on ticket stock, no lands written, carnival banner ornament, inviting not sad |
| `nbl_CardBackdrop` | Low-contrast striped carnival canvas and sawdust texture, dark navy and faded gold, quiet enough for text on top |
| `nbl_ControlFace` | The head of a carnival prize-wheel nail, iron and ticket gold, painted sideshow style, centred on a dark navy field |
| `nbl_TwistHero` | A fair-share nail seated in a landed slice while the rest of the painted wheel stays open, vintage sideshow banner, ticket gold on night navy |
| `nbl_SuccessMark` | A ticket punch and a seated nail on painted canvas, carnival gold confirmation mark, no text |
| `nbl_HeaderDecor` | Wide vintage sideshow banner ornament, ornate painted scrollwork, sawdust apron stripe, ticket gold on night navy, no readable words |

## How this differs

First party_spinner in the portfolio: a physical wheel for a room, not a typed random_picker reveal and not a habit week. Falspark parks a miss on a week wheel; this app nails a landed name so the same person cannot be drawn twice in one round. Occupath refuses a second train on a token; here every name stays on the pie and only leaves the draw set. No food, no slots, no catalog search, no Game tab.

## Build

```bash
cd Nailbally
xcodegen generate
xcodebuild -scheme Nailbally -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.nailbally.felt`. Contact: https://nailbally-felt.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `nbl.demo.v1` and never runs on a device.
