# Reply to App Review — Guideline 2.1, Information Needed

Apple's standard information request for a developer account with no review
history. It is not a finding against the app; nothing was reported as broken.
Answer all six points in the Resolution Center reply AND paste the same text into
the Notes field so future submissions carry it.

---

## 1. Screen recording — YOURS TO DO

Requirements Apple states: captured on a **physical device**, running the
**latest OS**, beginning with **launching the app**, showing the **typical user
flow**.

Not applicable here: account registration, login, account deletion, and
user-generated content. The app has none of them — say so in the reply.

Suggested run, about 90 seconds. Record with iOS Screen Recording (Control
Centre), on the iPhone, in one take:

1. Launch from the Home Screen — start recording before you tap the icon.
2. Press and hold the flush handle; release inside the window. Let the flush run.
3. Pull two or three squares down the wall roll; swipe across to tear.
4. Pull the handle again so the paper goes down. Show TANK counting down and
   RUN SCORE rising.
5. Pull paper and flush WITHOUT tearing, so the bowl blocks. Show the red bar.
6. Swipe the trailing paper to cut it free, drag the plunger onto the bowl, pump
   until it clears, then tap the wand.
7. Open the Daily Flush (calendar icon) and show the day's setup.
8. Open the leaderboard (list icon) and show both tabs.

---

## 2. Purpose and target audience

Flush Simulator is a single-player timing-and-risk arcade game for casual mobile
players — anyone who plays a short, score-chasing game in a spare minute. There
is no age-restricted content; it is rated 4+.

The problem it solves is the same one any pick-up arcade game solves: a
self-contained challenge that can be played in ninety seconds, scored, and
compared. The subject matter is deliberately mundane and comic, but the mechanic
is a genuine skill test — a held gesture with a narrow release window — wrapped
in a resource-management loop where the player chooses how much risk to take for
how many points.

## 3. Setup and access

No setup is required. There is no account, no sign-in, no credentials, no
onboarding, no server, and no configuration. The app is fully functional from
first launch with no network connection.

Everything is reachable from the single main screen:

- **Flush handle** — press and hold, release between 0.55s and 0.88s for a
  "perfect" pull. Earlier or later scores worse and breaks the streak.
- **Toilet paper roll** (wall, upper left) — drag down to draw squares, swipe
  across to tear one off. More paper scores more but raises the blockage chance.
  An untorn sheet is dragged in whole and always blocks.
- **Plunger** (floor, right) — when the bowl blocks, drag it onto the bowl and
  push down repeatedly to clear it.
- **Wand** (right of the fixture bar) — scrubs the bowl. Costs one flush from the
  tank, which is what makes grime a real cost.
- **Fixture bar** — five toilets with different drain tolerance (0.55 to 1.9) and
  score payout (0.7x to 1.6x). Unlocked by lifetime flushes.
- **Calendar icon** (top right) — the Daily Flush.
- **List icon** (top right) — leaderboards, local and Game Center.

A run is a tank of twenty flushes, ending in a score.

## 4. External services, tools and platforms

**Apple Game Center only.** It backs two leaderboards
(`com.tomchapman.flushsimulator.lifetime` and `.bestday`) and is contacted only
when the player opens the Global tab.

There is nothing else. Specifically: no third-party SDKs of any kind, no
analytics, no advertising network, no crash reporter, no backend or API of our
own, no authentication provider, no payment processor, no AI or machine-learning
service, and no data provider. The app has no in-app purchases.

The app makes no network request on its own initiative. All game state is stored
on the device with UserDefaults, which is declared in the bundled privacy
manifest under required-reason code CA92.1.

All assets are original and generated rather than licensed: the toilet, room and
water are drawn procedurally in SwiftUI at runtime, the flush audio is
synthesised from oscillators and filtered noise in AVAudioEngine rather than
being a recorded sample, and the app icon is produced by a program in the
repository.

## 5. Regional differences

None. The app functions identically in every region. There is no
geo-restricted content, no regional pricing beyond the single free tier, and no
region-dependent behaviour.

The Daily Flush is worth explaining because it may look server-driven: the day's
fixture, starting grime and paper target are derived deterministically from the
calendar date using a seeded generator inside the app. Every player worldwide
receives the same setup for a given date with no network call and no server.

## 6. Regulated industry or protected third-party material

Neither applies. The app is a game with no regulated function — no health,
finance, gambling, wagering, real-money mechanics, or professional services. The
in-game "golden flush" and scoring are ordinary game mechanics with no monetary
value and nothing to purchase.

No protected third-party material is included. All code, artwork and audio are
original and authored by the developer, as described in point 4.
