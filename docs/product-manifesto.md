# Unit — Product Manifesto

## The Problem

Every gym app on the market is a passive logger. You tap in your weights, close the app, and come back next week with no idea what to lift. The app recorded history. It did not help you.

The result: decision fatigue at the bar. You pick a number from memory, or you ask someone else, or you add a little and hope for the best. The plan is in your head — or nowhere at all.

Logging without progression is bookkeeping.

## The Solution: Adaptive Periodization Engine

Unit is an **Adaptive Periodization Engine**. It does not record what you did — it computes what you should do next, then adjusts when reality diverges from the plan.

The 8-Week Cycle is the primary container. Every exercise in your program has a base weight, a weekly increment, and a failure tolerance. The engine applies these rules every week:

- **You hit the target** → increment applies next week. No action required.
- **You miss the target** → weight repeats next week. Two misses in a row still repeats.
- **Three consecutive misses** → 10% deload. Failure count resets. You build back up.

The target is shown before every set. Actual vs. Target is the core UI paradigm. The app is a coach, not a clipboard.

## The Promise

Eight weeks. No guesswork. Every set has a number. When you fail, the plan adapts — not your resolve.

---

## Personas

### The Architect

Goals are numeric and tracked. Wants to know the optimal load for every exercise every session. Frustrated that other apps show history but not direction. Lives in spreadsheets between sessions.

Unit's engine replaces the spreadsheet. The Architect sets the cycle parameters once and trusts the output.

### The Grinder

Shows up every session, puts in the work, but never feels like they're making progress. Stalls happen and they don't know why — or what to do. Often repeats the same weights for months.

Unit's cascading failure detection surfaces the stall immediately and prescribes a deload before the plateau becomes permanent.

### The Recoverer

Returning after injury, break, or life interruption. Cautious about loading. Doesn't know where to restart.

Unit's CreateCycle flow seeds base weights from the last recorded session — a conservative, calibrated starting point. The 10% deload logic prevents overloading a recovery phase.
