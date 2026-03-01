# Atlas Log — Company / Product Goals

Ordered goals with success criteria. Used to prioritize and say no.

---

## 1. Ship a minimal lovable product (MLP)

- **Goal**: Launch an iOS app that does one thing exceptionally well: log strength workouts from your own templates, with a rest timer, in under 3 seconds per set.
- **Success**: App in TestFlight or App Store; users can create templates, start a session, log sets (weight, reps, optional RPE), run rest (including Live Activity), and rate session feeling. No critical bugs in core flow.

---

## 2. Pass the Gym Test

- **Goal**: A user can log one set (weight, reps, optional RPE, warmup flag) in under 3 seconds, under physical stress.
- **Success**: Measured time from “looking at set row” to “set marked complete” &lt; 3 s with defaults and one-tap. No required fields that slow the flow.

---

## 3. Establish design and doc foundation

- **Goal**: Strategy docs (competitors, design principles, visual language, cognitive/behavior, mental models, values, goals) and Cursor rules so all work is aligned.
- **Success**: Docs in `docs/`; Cursor/AGENTS reference them and the stack (Swift 6, SwiftUI, SwiftData, iOS 18+). New contributors can onboard from docs.

---

## 4. Grow revenue

- **Goal**: Monetize in a sustainable way (e.g. one-time purchase, subscription for sync/advanced features) without undermining trust.
- **Success**: Defined monetization and first paying users (or clear path to it). No dark patterns.

---

## 5. Expand reach

- **Goal**: Get Atlas Log in front of program-focused lifters who are tired of notes or bloated apps.
- **Success**: Marketing and distribution (landing, positioning, channels) in place; measurable reach (downloads, signups, or waitlist).

---

## Out of scope for initial release

- CloudKit sync (design schema for it; implement later).
- Exercise library / discovery (user-created exercises only at launch).
- Export (CSV/PDF) and onboarding flows (define in roadmap; implement in a later phase).
- Social, videos, or AI-generated plans.

---

Goals 1–3 are immediate (ship MLP, Gym Test, docs/rules). Goals 4–5 follow once the product is in users’ hands.
