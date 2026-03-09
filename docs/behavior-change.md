# Unit — Behavior Change Summary

Short summary of concepts from **Designing for Behavior Change** (Stephen Wendel et al.) relevant to habit formation and workout logging. Full text: [docs/references/Designing for Behavior Change.pdf](references/Designing%20for%20Behavior%20Change.pdf).

---

## 1. Behavior as outcome

- **Idea**: Behavior = what the user does (e.g. “log a set,” “complete a session”). Design for the behavior, not just the product.
- **Unit**: Target behaviors: (1) Start a workout from a template. (2) Log each set in under 3 seconds (Gym Test). (3) Optionally rate session feeling. (4) Use rest timer. We optimize the product so these behaviors are easy and rewarding.

---

## 2. Motivation, ability, and prompts (MAP / Fogg)

- **Idea**: Behavior happens when **motivation** and **ability** are sufficient, and a **prompt** (trigger) occurs. Increase ability (make it easy) and align prompts with context.
- **Unit**: Motivation = “I want to track my program” and “I’m someone who logs” (identity). Ability = high (defaults, one-tap, no required RPE). Prompts = “Start workout” on open, “Next set” after rest, “Complete set” on each row. We don’t rely on raising motivation; we lower the bar (ability) and make prompts obvious.

---

## 3. Identity-based habits

- **Idea**: Lasting change is easier when the user adopts an identity (“I’m a logger”) rather than only chasing outcomes (“I want to get stronger”). Design reinforces identity through small wins and consistency.
- **Unit**: Completing a set and a session are small wins. “You logged 4 sets” and “Session complete” reinforce “I log my workouts.” Optional overall feeling (1–5) adds reflection without friction. No heavy gamification—just clear, consistent logging so identity (“I’m someone who tracks”) is reinforced. See [mental-models.md](mental-models.md) (Identity Change).

---

## 4. Reducing friction and cognitive load

- **Idea**: Friction (steps, fields, decisions) reduces the likelihood of the behavior. Under physical stress (post-set), cognitive load is high—minimize it.
- **Unit**: Gym Test is the design constraint. Defaults (last weight/reps/RPE), one primary CTA (“Complete set”), optional RPE, rest timer on Lock Screen. No multi-step set entry. Every tap should have a clear purpose.

---

## 5. Feedback and reinforcement

- **Idea**: Immediate, clear feedback reinforces the behavior and confirms success.
- **Unit**: After “Complete set,” show clear success (e.g. checkmark, row marked done). Session end: “Workout complete” and optional feeling. History shows past sessions so progress is visible. Feedback is immediate and unambiguous.

---

## 6. What we avoid

- **Guilt or shame**: No “you missed a day” nagging. We might show “last logged: 2 days ago” without blame.
- **Over-promising**: We don’t promise transformation; we promise a fast, reliable log for your program.
- **Required reflection**: Overall feeling (1–5) is optional. We don’t force journaling or long forms.

---

## Summary

| Concept | Unit takeaway |
|--------|---------------------|
| Behavior as outcome | Design for: start workout, log set (&lt;3 s), use rest, optional feeling. |
| Motivation, ability, prompt | Maximize ability (defaults, one-tap); clear prompts (CTAs). |
| Identity | Reinforce “I log” through set/session completion and history. |
| Friction / cognitive load | Gym Test; minimize steps and decisions. |
| Feedback | Immediate success state; session complete; history. |

For full detail and frameworks, see **Designing for Behavior Change** in `docs/references/`.
