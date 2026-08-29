# Flood-It — Product Analytics on Mobile Game Telemetry

End-to-end analysis of 114 days of GA4/Firebase event data from *Flood-It!*, a casual mobile puzzle game, using the public BigQuery export. Covers retention, an investigation into seven anomalous traffic days, score and progression distributions, and monetization behaviour.

The project started as a retention study. The retention work surfaced seven days in late June carrying roughly 2.5–3× baseline traffic, and explaining them became most of the project.

---

## Terms used here

- **User-day** — one player active on one day. 500 players on Monday plus 400 on Tuesday is 900 user-days, even where some are the same people.
- **Reach** — how many user-days an event fired on. Breadth.
- **Intensity** — events per user-day, counting only the user-days where it fired. Depth. Reach × intensity = total events.
- **Event taxonomy** — the set of event names the app logs, and what each one means. Its vocabulary.
- **Logging change** — the app's code changes what it records while nobody's behaviour changes. Usually a new client version.
- **Left-censored** — a user who installed before the window opened, so their early activity is invisible and any lifetime measure undercounts them.
- **Gate** — a check with a known correct answer, computed rather than eyeballed. Shares must sum to 1; a label map must have no nulls; a row count must match a figure established earlier. Wrong tables usually look plausible, so the check has to be arithmetic, not visual.

---

## The data

`firebase-public-project.analytics_153293282` — 114 daily event tables, 12 June to 3 October 2018. 5.7 million events across 37 event types, 15,175 distinct `user_pseudo_id` values.

Two structural facts shape everything downstream.

**The user population splits in two.** 4,319 users (28.5%) log a `first_open` inside the window — the cohort, and the only users with a measurable install date. The other 10,856 installed earlier and appear mid-life, left-censored. Anything needing a per-user clock (retention, days-to-purchase) is defined on the cohort only; questions about game mechanics use everyone. Two different populations, used deliberately.

**Event parameters are nested and typed.** Each event carries a repeated `event_params` field, and every value lands in one of four typed slots — string, int, float, double — with the rest null. Reading a parameter means unnesting and coalescing across all four. Missing a slot silently drops every event logged on whichever platform used it.

One deduction the analysis rests on: `post_score` carries 31 distinct levels where `level_start` carries only 30. Every level that gets played posts a score, so all 30 started levels must already appear among `post_score`'s values — which leaves level 0 as a level that was never started. It is the second game mode's scoring bucket, holding 206,375 of 242,039 posts, and doubles as the mode flag. Three separate checks agree: the level cardinality above; `level_start_quickplay` carrying no `level` parameter at all, only a board size, so quickplay's posts need a bucket that is not a level; and level 0 holding 85.3% of all posts against quickplay's 87.6% share of level starts.

---

## Method

Extraction in BigQuery SQL, analysis in pandas. Twelve query files in `sql/`, five notebooks in `notebooks/`, and a raw chronological working record in `notes/ledger.md`.

- **Two independent implementations for the headline metric.** The retention curve is built once in SQL and once in pandas. All fifteen numbers — eligible, retained, and rate across five horizons — agree digit for digit. One implementation agreeing with itself proves nothing.
- **Design before extraction.** Every pull was specified and argued before it ran, so each query answers one question at minimal grain.
- **Gates are computed, not eyeballed.** Share tables assert to 1.0, label maps assert no nulls, row counts reconcile against known totals. More than one error in this project was caught by a gate that a plausible-looking output would have passed.
- **Types and units at boundaries only.** Strings ride the CTE pipeline; the final `SELECT` stamps types and converts micros. In pandas, parsing happens at load. Never mid-flow.

---

## Findings

### 1. The spike days' most obvious evidence turned out to be unusable

Everything in this section compares pre-window players against themselves — the same population on spike days and on the normal days between them. Spike-day activity was 97.2% pre-window against 78.0% on normal days, so comparing the whole room to the whole room would measure a change in mix rather than a change in behaviour.

On the seven spike days the event mix looks dramatically different. `screen_view` falls from 41.7% of pre-window events to 6.1%; `user_engagement` rises from 22.9% to 39.5%; quickplay events rise across the board. The natural reading is that the spike-day crowd behaved differently, which would rule out a data glitch.

It does not hold. Shares are compositional — they sum to one — so when `screen_view`'s share collapses by 35.6 percentage points, the other events' shares rise to fill the gap, about 1.61×, without anyone behaving differently. Worse, a composition shift driven almost entirely by one event's collapse is precisely what a logging change produces.

The direct evidence for that: measured by reach — user-days on which an event fired — `level_complete_quickplay` fell to 274 from 1,584 while `post_score` rose to 2,440 from 1,792. Completion user-days run at 88% of score-posting user-days on normal days, and at 11% on spike days. Since scores post around level completion, completions were happening and were not being recorded. `select_content` reach at 0.14× and `screen_view` intensity at 0.05× most plausibly belong to the same effect.

The event taxonomy itself changed on those days — across 114 days of a live app, different client versions logging different taxonomies is the plain reading. The composition table therefore cannot be read as behaviour, and every subsequent claim about the spike is built on something else.

*Derivation: `notebooks/04_spike_analysis.ipynb`*

### 2. The spike traffic was real, and a campaign is the likeliest cause

Two quantities separate a genuine influx from a logging change. **Reach** is the number of user-days an event fired on. **Intensity** is events per participating user-day. A logging fault suppresses events without removing people, so it cuts intensity while leaving reach intact; a real influx raises reach across independent events while intensity holds flat.

Reach rose across independent gameplay events: quickplay starts 2,044 → 4,165, user engagement 2,499 → 5,055, score posts 1,792 → 2,440. Intensity on those three held between 0.93× and 1.13×. Twice as many people, each playing about as much. A logging fault does not manufacture two thousand user-days of gameplay.

*Confidence: good.* It rests on three independent events agreeing rather than on any single measure. A logging change would have to hit several unrelated events in the same direction, by a similar factor. And leave per-user rates untouched while doing it.

On cause: `firebase_campaign` fired 102 times across the seven spike days against 20 across the seven interleaved normal days — 5.1×, seven days against seven days from the same fortnight — and 14.6 per day against 3.7 per day over the 94-day stable block. Raw counts, unaffected by the composition problem above.

*Confidence: medium.* It is the only signal that moves with the spike, but co-occurrence is not causation, the absolute counts are small, and installs flatlined on five of the seven days in a way nothing here explains.

Two candidate explanations were dropped rather than weakened. `notification_foreground` fires **once** in the entire 114-day window, so this dataset carries no usable push-notification signal in either direction — untestable, not disproved. Both deep-link events total three events each. All three are recorded in the notebook's "not concluded" section so their absence from these findings is deliberate rather than an oversight.

*Derivation: `notebooks/04_spike_analysis.ipynb`*

### 3. Retention follows a single decay law

| Horizon | Eligible | Retained | Rate |
|---|---|---|---|
| D1 | 4,251 | 915 | 21.52% |
| D3 | 4,151 | 435 | 10.48% |
| D7 | 3,998 | 223 | 5.58% |
| D14 | 3,711 | 137 | 3.69% |
| D30 | 2,963 | 62 | 2.09% |

Denominators shrink by horizon on purpose: a user who installed three days before the window closed never had the chance to return on day 30, and counting them would dilute the later points. Retention is defined as activity on *exactly* day N, the stricter of the two conventions.

In log-log space the five points sit on a straight line. The slopes between consecutive points alternate around −0.7 with no consistent direction — a consistent direction would mean the decay changes partway, alternation means noise — and the visible bends at D14 and D30 fall inside two standard errors. One decay law summarises the curve, which means retention can be estimated for days we didn't measure, and projected past day 30 as long as the projection is labelled as one.

Two things the curve alone hides. Roughly half of all players are active on exactly one day ever (54.2% of the cohort). And D1 retention undercounts recoverable players: because retention is exact-day, a user can miss day 1 and return later, and a substantial share of the cohort does.

The apparent weekly rhythm is noise. Across the 94 stable days the largest weekday-to-weekday gap is 30.7 players against a 39.0 threshold, and the weekend-to-weekday gap is 13.1 against 23.3. The Monday/Tuesday peak visible in the raw weekday averages was the seven spike days dragging those two averages up.

*Derivation: `notebooks/02_retention_analysis.ipynb`, cross-checked against `sql/retention_curve.sql`*

### 4. Scores concentrate on one level; progression falls in three regimes

The two modes score differently. Quickplay decays geometrically and cleanly, from 56,174 posts at score 0 down to a single post at score 15, with no irregularities.

Level mode is not one distribution. Pooled across its thirty levels it shows a large pile-up at score 21 — but the levels do not share a score range, so the pooled series is thirty distributions stacked together that don't cover the same range of scores. Checked per level, score 21 occurs on level 1 and nowhere else, holding 3,415 of level 1's 3,947 posts (86.5%). No other level's maximum exceeds 18, and no other level puts more than 3.8% of its posts at its own maximum. This is one level behaving unlike the other twenty-nine, not a game-wide ceiling.

Progression falls off in three regimes, not two. Levels 1–9 lose 75% of post volume (3,947 → 987) — the early funnel. Levels 10–26 decline gently, 977 → 612, a 37% loss spread across seventeen levels. Then level 27 drops to 314 from 612 — 49% in a single step — and volume stays down through level 30. The contrast between 37% over seventeen levels and 49% over one is what makes the last one a cliff rather than more of the same slope.

Why level 1 concentrates at 21 and why volume halves at level 27 are both real and both unexplainable from this data. The data records outcomes, not rules.

*Derivation: `notebooks/05_score_mode_analysis.ipynb`*

### 5. Purchases happen on install day or not at all

27 purchases across 114 days, by 27 distinct users, with no repeat buyers anywhere in the window. Of the 17 buyers with a measurable install date, 12 bought on install day itself; the median days-to-purchase is 0.

Cohort users are 28.5% of the player base but 63% of buyers — roughly 2.2× over-represented — while their share of ad views tracks the population at 25.8%. Long-tenured players watch ads and rarely buy.

What players buy is friction removal: 20 of the 27 purchases are `remove_ads`, the remaining 7 are extra-step packs.

*Confidence: descriptive only.* These are counts from 27 purchases, not estimates of a rate. The 95% interval around "12 of 17 bought on day 0" spans roughly 47% to 87% — wide enough that the fraction is worth more than the percentage. Read these as what these players did, not as what players do.

*Derivation: `notebooks/05_score_mode_analysis.ipynb`*

---

## Limitations

- **`user_pseudo_id` is an app install on a device, not a person.** One human with two devices is two users; a reinstall may be a third. Unique human players number at most 15,175 and realistically fewer.
- **Pre-window users are left-censored.** 10,856 of 15,175 users appear mid-life with their earlier activity invisible, so any lifetime measure for that group is an undercount. The deep tail of the activity distribution cannot be separated from the censoring that produces it, which is why no claim is made about pre-window players being more dedicated.
- **The event taxonomy is not stable across the window.** Finding 1 documents this on the spike days specifically, but the cause — differing client versions in a live app — applies generally. Any event-composition comparison across distant dates in this dataset deserves suspicion.
- **Monetization is n=27.** No rate, comparison, or trend from that section would survive scrutiny, and none is offered.
- **The install blackout is unexplained.** Five of the seven spike days logged no installs at all, against a baseline near 38 a day. It is the strongest surviving argument for a logging fault and nothing here accounts for it. It also reaches into the analysis: users are labelled pre-window by the absence of a `first_open`, which is the event that blacked out — so an unlogged install wave would land in the pre-window group by construction. The 97.2% figure therefore cannot be read as independent evidence that the spike was the installed base returning. The reach argument in Finding 2 does not depend on the label being right; the population framing does.
- **Post volume is a proxy for players in the progression analysis.** The two are equal only if posts-per-player is roughly constant across levels. That extraction carries no user counts, so it cannot be checked here — and level 1, with 86% of its posts at a single score, is visibly not behaving like the others.
- **Measured and accepted:** 12 users (0.28% of the cohort) show activity before their computed day 0 — pre-window installers who reinstalled in-window. Maximum effect on retention is about 0.3pp, below rounding. Separately, the `(user, timestamp)` event key collides on 12 rows out of 242,039.

---

## Open questions

Four things this data raises and cannot settle:

- **Why installs flatlined on five of the seven spike days.** Unexplained, and the single strongest counter-argument to the campaign reading.
- **Why level 1 puts 86.5% of its posts at score 21.** A scoring rule, a tutorial behaviour, or a first-level logging quirk would all leave this same footprint.
- **Why post volume halves at level 27 and stays down.** A content boundary, a difficulty change, or an observation-window artifact are all consistent with what is here.
- **Why level-mode scores dip at 10, rise at 11–12, then collapse at 13** (1,195 → 1,669 → 1,719 → 617), on counts too large to be noise. The obvious explanation — levels whose maximum falls in that range piling up at their own ceilings — fails on arithmetic: those ten levels contribute about 70 posts between them, against a bump of roughly 3,400.

---

## Repo

```
notebooks/
  01_retention_extraction.ipynb    BigQuery → day_0.csv, user_journal.csv
  02_retention_analysis.ipynb      retention curve, activity patterns, DAU anomaly found
  03_event_pulls.ipynb             three parameter-level extractions
  04_spike_analysis.ipynb          spike investigation and verdict
  05_score_mode_analysis.ipynb     scores, level progression, monetization
sql/                               twelve queries, one question each
data/                              extracted CSVs
notes/ledger.md                    raw session-by-session working record
```

Each notebook opens with its purpose, inputs, outputs, and position in the chain, and closes with what it establishes and what it explicitly does not conclude.

`notes/ledger.md` is a working record, not a polished document. It is chronological and append-only: where a finding was later found wrong, the correction is appended as a new entry rather than edited back into the original. Six claims were corrected that way late in the project, including what had been the headline finding.

---

## Tools

BigQuery (standard SQL), Python, pandas, matplotlib, Google Colab, Git/GitHub.
