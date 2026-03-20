# Unit — Company / Product Goals

Ordered goals with success criteria. Used to prioritize and say no.

---

## 1. Ship the 8-Week Cycle + Cascading Failure Engine

- **Goal**: Launch the Adaptive Periodization Engine: 8-week cycle creation, per-exercise progression rules, target weight displayed before every set, cascading failure detection (3 misses → 10% deload), and auto-recalibration of future weeks.
- **Success criteria**:
  - Target weight visible on set row in < 0.5s after session start.
  - Create Cycle → Week 1 shows targets → log below target → Week 2 shows same weight.
  - 3 consecutive failures triggers deload badge and 10% weight reduction.
  - App passes Gym Test: log a set with RIR in under 3 seconds on device.
  - No critical bugs in core cycle flow.

---

## 2. Pass the Gym Test

- **Goal**: A user can log one set (weight, reps, optional RPE, warmup flag) in under 3 seconds, under physical stress.
- **Success**: Measured time from “looking at set row” to “set marked complete” &lt; 3 s with defaults and one-tap. No required fields that slow the flow.

---

## 3. Establish design and doc foundation

- **Goal**: Strategy docs (competitors, design principles, visual language, **atomic design system**, cognitive/behavior, mental models, values, goals) and Cursor rules so all work is aligned.
- **Success**: Docs in `docs/` (including `atomic-design-system.md`); Cursor/AGENTS reference them and the stack (Swift 6, SwiftUI, SwiftData, iOS 18+). New contributors can onboard from docs.

---

## 4. Grow revenue

- **Goal**: Monetize in a sustainable way (e.g. one-time purchase, subscription for sync/advanced features) without undermining trust.
- **Success**: Defined monetization and first paying users (or clear path to it). No dark patterns.

---

## 5. Expand reach

- **Goal**: Get Unit in front of program-focused lifters who are tired of notes or bloated apps.
- **Success**: Marketing and distribution (landing, positioning, channels) in place; measurable reach (downloads, signups, or waitlist).

---

## Out of scope for initial release

- CloudKit sync (design schema for it; implement later).
- Exercise library / discovery (user-created exercises only at launch).
- Export (CSV/PDF) and onboarding flows (define in roadmap; implement in a later phase).
- Social, videos, or AI-generated plans.

---

Goals 1–3 are immediate (ship MLP, Gym Test, docs/rules). Goals 4–5 follow once the product is in users’ hands.
