# Google Play store assets

| File | What it is |
|---|---|
| `listing-en-US.md` | Source of truth for the listing copy |
| `metadata/android/en-US/title.txt` | App name (26 / 30) |
| `metadata/android/en-US/short_description.txt` | Short description (80 / 80) |
| `metadata/android/en-US/full_description.txt` | Full description (about 3,600 / 4,000) |
| `icon-512.png` | 512 x 512 app icon |
| `feature-graphic.svg` | Editable source for the feature graphic |
| `feature-graphic.png` | 1024 x 500 RGB feature graphic, no alpha |
| `screenshots/01-*.png` to `04-*.png` | Four 1080 x 2160 (2:1) RGB phone screenshots |

## How they were made (2026-10-21)

**Metadata.** Copied verbatim from the matching sections of
`listing-en-US.md`. No prices, no em dashes. Edit the `.md` first, then
recopy.

**Feature graphic.** `feature-graphic.svg` uses the app icon's art: the navy
background (`#111e33`), the cream book with the orange bolt, drawn as vectors
on a faint drawing-paper grid. Text is live, so edit it in the SVG. It was
rendered with headless Chrome at 1024 x 500, then flattened to RGB with
Pillow.

**Screenshots.** These are real screens from a debug build on the `agent-emu-1`
AVD (API 36) on jmbp. The build had no RevenueCat key, so no Test Store prices
appear. The app was launched with the debug extras in `DebugLaunchOptions.kt`:

```sh
adb shell am start -n com.jackwallner.electrician/.MainActivity \
  --ez resetAll true --ez onboarded true --ez forcePro true \
  --ez seedProgress true --ez uiTest true --es jurisdiction CA \
  --ei examInDays 21 --es appearance light
```

The device was set to `wm size 1080x2160` and `font_scale 0.9`, with SystemUI
demo mode on (clock 9:41, full Wi-Fi and battery, no notifications). Each
screen was reached by tapping through the app.
`wm size 1080x1920` renders black frames on this emulator's software GPU, so
the captures use 2:1, which is the widest ratio Play accepts.

1. Conductors & Ampacity > Ampacity Check, wrong answer picked, explanation shown
2. Worked Calculations > The Five Shapes, a missed derating problem with the numbered working
3. Code Basics > Which Article?, first question
4. Field Tools > Ampacity calculator (free), 10 AWG copper, 40 °C, six conductors
