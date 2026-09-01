# Flush Simulator — App Store listing copy

Everything App Store Connect asks for, ready to paste. Character limits are noted
because ASC silently truncates rather than warning you.

---

## Name (30 max)

```
Flush Simulator
```

## Subtitle (30 max)

Recommended — leads with skill, which is what stops a reviewer filing this under
"novelty":

```
Perfect the pull. Every day.
```
*(27)*

Alternatives:
- `A daily test of handle skill` *(28)*
- `The art of the perfect flush` *(28)*

## Promotional text (170 max — editable without a new build)

```
One roll in a hundred isn't paper. Hold the handle, let go inside the window, and
see how far a single tank gets you. A new challenge every day.
```
*(151)*

## Keywords (100 max, comma-separated, NO spaces after commas)

Deliberately excludes "flush", "toilet" and "simulator" — those already sit in the
name and subtitle, and Apple indexes those fields. Repeating them wastes the field.

```
plunger,daily,streak,timing,arcade,casual,score,leaderboard,challenge,reflex,tap,porcelain,silly
```
*(97)*

---

## Description (4000 max)

```
Pull the handle. Hold it. Let go at exactly the right moment.

That's the whole game, and it is harder than it sounds.

A FLUSH WORTH GETTING RIGHT
Every cistern wants the lever held for a beat. Let go early and you get a half
flush. Lean on it and you're just wasting water. Land inside the window and you
get a perfect pull — and a streak worth protecting.

ONE TANK AT A TIME
A run is twenty flushes. Grime builds, the bowl gets temperamental, and scrubbing
it costs you water you could have flushed with. Every square of paper you draw off
the roll is worth more points and more risk. Push your luck or bank the run.

TEAR IT PROPERLY
The roll is on the wall. Pull down for the squares you want, then swipe across to
tear. Forget the tear and the bowl takes the whole roll with it, which goes about
as well as you'd expect. Then it's the plunger, the wand, and starting over.

FIVE FIXTURES, FIVE PROBLEMS
The Outhouse blocks if you look at it wrong and pays 1.6x for the trouble. Chrome
Pressure swallows anything and pays the least. The Victorian Throne takes its time.
The Orbital Vacuum has no water and no down. Your collection is a choice, not a
skin.

THE DAILY FLUSH
Everyone gets the same toilet, the same starting grime, and the same paper target.
One attempt. Share the grid.

ALSO
Golden flushes. Ranks nobody asked for. A global leaderboard. And one roll in a
hundred that isn't paper at all.

No accounts. No ads. Nothing leaves your phone.
```

---

## What's New (1.0)

Leave empty for a first release; ASC does not require it.

---

## URLs — YOURS TO FILL

Both are mandatory and the submission is blocked without them.

| Field | Needs |
|---|---|
| Support URL | A page with a way to contact you. A single page on a site you own is enough. |
| Privacy Policy URL | Required for every app. Must be reachable and must actually describe the policy. |

Draft privacy policy text, since the honest version is short:

```
Flush Simulator does not collect, store, or transmit any personal information.
Your progress is kept on your device. If you choose to open the global
leaderboard, scores are submitted through Apple's Game Center, which is governed
by Apple's privacy policy. There is no analytics, no advertising, and no
third-party SDK of any kind in this app.
```

---

## Category

- **Primary:** Games → Casual
- **Secondary:** Games → Arcade

Both matter for the 4.3 question below: a "Casual game" is a category Apple expects
short, simple loops in. "Entertainment" would invite the wrong comparison.

---

## Age rating

Answer the questionnaire honestly. Expect **4+**. The one question worth thinking
about is crude humour — the app's jokes are toilet-adjacent but mild, and there is
nothing suggestive. If in doubt, "Infrequent/Mild" on that item yields 9+, which is
harmless.

---

## App Privacy

Answer: **"No, we do not collect data from this app."**

The app touches `UserDefaults` for local progress only, which is not collection.
Game Center is Apple's own service and is declared by Apple, not by you. There is
no SDK, no analytics, and no network call the app makes on its own.

---

## App Review notes — THE IMPORTANT ONE

Guideline 4.3 (Spam) and 2.1 (minimum functionality) are the real risk on a
novelty-sounding first submission. These notes exist to answer that objection
before it is raised. Paste into the Notes field:

```
Flush Simulator is a timing-and-risk arcade game.

The core mechanic is a held gesture: the player presses and holds the flush lever
and must release inside a narrow window (0.55s-0.88s) for a "perfect" pull.
Releasing early or late is scored worse and breaks the streak.

Around that sit four interacting systems:

- A bounded run. Each run is a tank of 20 flushes ending in a score. Cleaning the
  bowl consumes a flush from that budget, so grime management is a real cost.
- A physical paper mechanic. The player drags squares off a wall-mounted roll and
  swipes to tear. More paper scores more but raises the chance of blocking. An
  untorn sheet is dragged in whole and always blocks.
- A recovery loop. A blocked bowl must be cut free, then cleared by dragging an
  on-screen plunger onto the bowl and pumping it, then cleaned.
- Five fixtures with genuinely different values - drain tolerance from 0.55 to 1.9
  and score payouts from 0.7x to 1.6x - so the choice is strategic.

There is also a daily challenge: a fixture, starting grime and paper target derived
deterministically from the date, so every player worldwide gets the same setup, one
attempt per day, with a shareable result grid.

Game Center leaderboards are configured (lifetime flushes, best day).

No ads, no third-party SDKs, no data collection, no accounts, no network calls
except Game Center.
```

---

## Screenshot order

Order matters — reviewers and browsers see the first three. Lead with the systems,
not the joke.

| # | Shot | Says |
|---|---|---|
| 1 | `1-standard` | Clean hero. Tank counter and score visible. |
| 2 | `6-daily` | It's a daily game with a challenge. |
| 3 | `5-paper` | The paper mechanic — the thing nothing else does. |
| 4 | `3-orbital` | Collection, and the art range. |
| 5 | `4-upkeep` | The grime/clog loop and the plunger. |
| 6 | `2-victorian` | More collection. |

Apple only requires the 6.9" iPhone and 13" iPad sets; the rest are scaled down
automatically.
