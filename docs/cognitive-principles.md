# Unit — Cognitive Principles

Principles from [abtest.design](https://abtest.design/) and [growth.design/psychology](https://growth.design/psychology) applied to Unit for persuasiveness, behavior change, and retention.

---

## 1. Reduced friction

- **Principle**: Every step and field increases drop-off. Remove or defer non-essential input.
- **Unit**: Gym Test = log a set in under 3 seconds. Defaults (last weight/reps, last RPE). One-tap “complete set.” Optional RPE, not required. Rest timer in-flow and on Lock Screen so no app switching.
- **Source**: Friction reduction is a recurring theme in abtest.design (e.g. streamlined checkout, simpler onboarding).

---

## 2. Clarity of value

- **Principle**: User should immediately understand why they’re here and what they get.
- **Unit**: Home/Today = “Start workout” or “Continue session.” No discovery or feed. Value = “your program, logged fast, with history.” Templates and history reinforce “this is your log.”
- **Source**: Clear value props improve conversion (e.g. “How your free trial works,” clearer pricing).

---

## 3. Commitment and consistency

- **Principle**: Small commitments (e.g. logging one set) increase likelihood of continuing; consistency (streaks, identity) reinforces habit.
- **Unit**: Completing one set is a micro-commitment. Session completion and “overall feeling” (1–5) reinforce “I finished.” Future: streaks or “sessions this week” without gamification overload. Identity: “I’m someone who logs” (see [mental-models.md](mental-models.md)).
- **Source**: Duolingo’s decoupling streaks from daily goals (+40% on streak); consistency drives retention.

---

## 4. Social proof (light touch)

- **Principle**: Others’ behavior can motivate; too much shifts focus from personal progress.
- **Unit**: No social feed. Optional future: “X workouts logged” or “You’re in the top 10% of consistent loggers” (personal, not feed). We avoid comparison-heavy social proof that distracts from the Gym Test.
- **Source**: Social validation can help (e.g. Headspace trial survival); we use it sparingly and for personal progress only.

---

## 5. Loss aversion

- **Principle**: People are more motivated to avoid losing progress than to gain something new.
- **Unit**: “Don’t lose this set” — make it easy to log so the user doesn’t “lose” the data. Rest timer visible so they don’t “lose” rest time. Session in progress = “finish so you don’t lose the workout.”
- **Apply**: Save state; don’t require long forms that risk abandonment. Clear “you’re logged” feedback.

---

## 6. Clear CTAs

- **Principle**: One primary action per context; label should state the outcome.
- **Unit**: Primary CTA = “Complete set” (not “Save” or “Submit”). “Start workout,” “Start rest,” “End workout.” Buttons are large and use accent color (see [visual-language.md](visual-language.md)).
- **Source**: Optimal CTA design and placement (e.g. Unacademy, Instasize) improve clicks and conversions.

---

## 7. Ability and motivation (Behavior Change)

- **Principle**: Behavior happens when user has both ability (easy to do) and motivation (want to do). Reduce barriers and reinforce identity.
- **Unit**: Ability = Gym Test (easy), defaults, one-tap. Motivation = clear progress (history, session done), optional feeling (1–5), and identity (“I log my workouts”). See [behavior-change.md](behavior-change.md).
- **Source**: Designing for Behavior Change (Fogg, etc.); growth.design/psychology.

---

## 8. Predictability

- **Principle**: Showing the target eliminates the cognitive load of deciding what to lift. The user’s decision-making at the bar is reduced to “did I hit it or not?”
- **Unit**: The engine computes the target weight before every set and displays it as ghost text in the Target Column. The user does not need to remember last week’s weight, estimate an increment, or calculate a deload. The number is there.
- **Apply**: Target must be visible in < 0.5s after session start. Ghost text styling (`Color.secondary`) distinguishes it from editable inputs. The user never enters the target — they only enter the actual.

---

## Summary

| Principle | Unit application |
|-----------|------------------------|
| Reduced friction | Defaults, one-tap set, RIR stepper, Live Activity rest. |
| Clarity of value | “Your target, computed. Log actual. Engine adjusts.”; no feed. |
| Commitment/consistency | 8-week cycle as commitment architecture; streak counter. |
| Social proof | Minimal; personal progress only, no feed. |
| Loss aversion | Easy logging so data isn’t lost; clear saved state. |
| Clear CTAs | “Done,” “Start Session,” “End Workout.” |
| Ability + motivation | Gym Test + engine-driven progress signal. |
| Predictability | Target shown before set; zero cognitive load at the bar. |

These principles guide feature and copy choices so Unit supports **behavior change** (logging consistently, following the progressive overload plan) without dark patterns.
