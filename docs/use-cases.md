# Unit — Use Cases

## Use Case 1: The Architect Runs a Structured Cycle

**Persona:** Architect — numeric, data-driven, plans everything.

**Scenario:** Marcus has been lifting for 3 years. He programs in Excel: base weight, weekly increment per exercise, deload rules. He rebuilds the spreadsheet every 8 weeks. It works but the friction is high — updating formulas when he misses a lift takes 10 minutes.

**How the Engine Serves Him:**
Marcus opens Create Cycle, selects his PPL split, sets per-exercise base weights (seeded from last session), and confirms 2.5kg increments. The engine replaces the spreadsheet. Week 1 targets appear on the logging screen before his first set. When he hits failure on bench in Week 4, the engine detects it and holds the weight for Week 5. He doesn't touch a spreadsheet. He just lifts.

---

## Use Case 2: The Grinder Breaks a Plateau

**Persona:** Grinder — consistent, hardworking, frustrated by invisible stalls.

**Scenario:** Priya has been doing 80kg squat for 6 weeks. She doesn't know why she isn't progressing — she shows up, she tries. Her app shows the history but offers no diagnosis.

**How the Engine Serves Her:**
Unit's failure count detects that she has missed the target 3 times in a row on squat. The deload badge appears in her logging card. Week 7 shows 72kg — 10% below her stall weight. She completes the deload. Week 8 targets 75kg. The plateau breaks.

---

## Use Case 3: The Recoverer Restarts Safely

**Persona:** Recoverer — returning after a 3-month break, cautious, uncertain where to start.

**Scenario:** Tomas had shoulder surgery. He's cleared to lift but doesn't know where to begin. His last session in the app was 3 months ago at weights he can't safely hit today.

**How the Engine Serves Him:**
CreateCycle seeds base weights from his last recorded session. He manually adjusts bench to 50% — the stepper makes this easy. The engine begins his 8-week return cycle from this conservative baseline, incrementing 2.5kg per week. By Week 8 he's back to 65% of his pre-surgery best. The app gave him a structured runway, not a blank page.
