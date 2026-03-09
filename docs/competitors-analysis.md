# Unit — Competitors Analysis

Deeper analysis: feature matrix, UX patterns for “log under stress,” and takeaways for Unit.

---

## 1. Feature matrix

| Feature | Hevy | Strong | Fitbod | Notes/Sheets | Unit (target) |
|--------|------|--------|--------|--------------|--------------------|
| Programs / templates | Yes | Basic | AI plans | Manual | **DayTemplate** (ordered exercises) |
| Set logging (weight, reps) | Yes | Yes | Yes | Manual | **SetEntry** (weight, reps, RPE, warmup) |
| RPE (1–10) | Yes | Some | Some | No | **Optional RPE** on each set |
| Rest timer | In-app | In-app | Optional | No | **Live Activity** (Lock Screen / Dynamic Island) |
| Export | Yes | Yes | Varies | N/A | Later phase |
| Exercise library | Large | Large | Large | None | User-created (later: optional library) |
| Social / feed | Yes | No | No | No | **No** |
| Videos / demos | Yes | Some | Yes | No | **No** |
| Sync | Cloud | Cloud | Cloud | Manual | Local-first (CloudKit-ready later) |
| Overall feeling / mood | Some | Rare | Rare | No | **Session overallFeeling 1–5** |

**Takeaway**: Unit competes on **structure** (templates, session, set schema), **speed** (Gym Test), **focus** (no social/videos), and **rest timer visibility** (Live Activity). RPE and session feeling are differentiators for serious lifters.

---

## 2. UX patterns: “Log under stress”

How competitors handle logging during or right after a hard set:

- **Hevy**: Pre-filled “last weight/reps” for next set; rest timer in same flow. Good. Some taps to open exercise, then set row.
- **Strong**: Similar “last” defaults; simple list. Can get tap-heavy if many exercises.
- **Fitbod**: Focus on “what to do next” (AI plan); logging is secondary to following the plan.
- **Notes/Sheets**: No defaults; manual typing. Fails Gym Test.
- **Common pitfalls**: Too many screens (exercise picker → set form → confirm). Optional fields (e.g. RPE) presented as required. Small tap targets. No “repeat last set” one-tap.

**Takeaways for Unit**:

- **Copy**: Default next set to last weight/reps (and last RPE if used). Single screen per exercise with all sets visible. Rest timer always accessible (Live Activity so it survives app background).
- **Avoid**: Multi-step set entry. Required RPE. Small buttons. Burying “complete set” behind another screen.
- **Innovate**: One-tap “same as previous set” for speed. Big primary CTA for “complete set.” Optional RPE with 1–10 picker, not free text.

---

## 3. Information architecture

- **Hevy**: Tabs (Workout, History, Exercises, More). Workout = active or start; History = past sessions.
- **Strong**: Similar: Today/Workouts, History, Exercises.
- **Unit (target)**: Minimal tabs or root: **Today** (start or continue session), **Templates** (edit DayTemplates, exercises), **History** (past sessions). No “Discover” or “Social.”

---

## 4. Data model alignment

Competitors often use: Workout → Exercises → Sets, with optional Program/Routine. Unit aligns as:

- **DayTemplate** = program day (e.g. “Push A”) with ordered exercises.
- **WorkoutSession** = one instance of a template on a date, with optional overall feeling.
- **SetEntry** = one set (session, exercise, weight, reps, RPE, warmup, completed).

This matches how program-focused users think (day → exercises → sets) and keeps schema CloudKit-ready (UUIDs, no non-persisted refs).

---

## 5. Summary: what to copy, what to avoid

| Copy | Avoid |
|------|--------|
| Last weight/reps (and RPE) as default for next set | Multi-step set entry flows |
| Rest timer in flow (and on Lock Screen via Live Activity) | Required RPE or optional fields that feel required |
| Template → session → sets hierarchy | Social feed, videos, discovery |
| Big “complete set” / primary CTA | Small tap targets, buried actions |
| Card-style blocks for exercises/sets | Cluttered dashboards |
| Optional session “how did it feel?” (1–5) | Mandatory long forms post-workout |

Unit wins by being the **fastest, most focused** way to log a program-based strength session, with no social or media clutter.
