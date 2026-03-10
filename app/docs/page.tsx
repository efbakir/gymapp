"use client"

import { useState } from "react"

// Design tokens for the documentation, matching the iOS Theme
const theme = {
  colors: {
    accent: "#FF4400",
    accentSoft: "rgba(255, 68, 0, 0.12)",
    background: "#111318",
    elevated: "#1A1D25",
    card: "#252831",
    textPrimary: "rgba(255, 255, 255, 0.92)",
    textSecondary: "rgba(255, 255, 255, 0.55)",
    border: "rgba(255, 255, 255, 0.12)",
    ghostText: "rgba(255, 255, 255, 0.55)",
    progress: "#D65400",
    failure: "#FF3B30",
    deload: "rgba(255, 165, 0, 0.8)",
  },
  spacing: {
    xxs: 4,
    xs: 8,
    sm: 12,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
    xxxl: 64,
  },
  radius: {
    sm: 10,
    md: 14,
    lg: 18,
  },
}

// Component data
const components = [
  {
    name: "cardStyle()",
    category: "Modifiers",
    description: "Standard card: fill contrast only — no shadow, no border.",
    code: `.cardStyle()
// Equivalent:
.padding(Theme.Spacing.md)
.background(Theme.Colors.card)
.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))`,
    preview: "card",
  },
  {
    name: "ScaleButtonStyle",
    category: "Interactions",
    description: "Micro-scale tap feedback (0.97x) for cards and buttons.",
    code: `Button(action: onStart) {
    // content
}
.buttonStyle(ScaleButtonStyle())`,
    preview: "button",
  },
  {
    name: "TrainingDayCard",
    category: "Cards",
    description: "Context card for training days with exercise targets and delta badges.",
    code: `TrainingDayCard(
    weekNumber: 3,
    templateName: "Push",
    targets: [
        ExerciseTarget(
            exerciseName: "Bench Press",
            weightKg: 100,
            reps: 5,
            deltaKg: 2.5,
            lastWeightKg: 97.5,
            lastReps: 5
        )
    ]
) {
    startWorkout(template)
}`,
    preview: "training-card",
  },
  {
    name: "RestDayCard",
    category: "Cards",
    description: "Rest day context with next session info and recent wins.",
    code: `RestDayCard(
    nextSession: "Pull",
    nextSessionTiming: "Tomorrow",
    wins: [
        SessionWin(exerciseName: "Bench Press", deltaKg: 2.5)
    ]
)`,
    preview: "rest-card",
  },
  {
    name: "DayCardView",
    category: "Cards",
    description: "Quick-start card for selecting a workout template.",
    code: `DayCardView(
    title: "Push",
    splitName: "PPL",
    lastPerformed: "2 days ago",
    topLift: "Bench 100kg × 5"
) {
    startWorkout(template)
}`,
    preview: "day-card",
  },
  {
    name: "ExerciseLoggingCard",
    category: "Workout",
    description: "Full exercise logging with target column, inputs, RIR stepper.",
    code: `ExerciseLoggingCard(
    exercise: exercise,
    progressionRule: rule,
    activeCycle: cycle,
    weekNumber: session.weekNumber,
    currentEntries: currentEntries(for: exercise.id),
    lastActual: (weight: 97.5, reps: 5),
    prefill: viewModel.prefillSet(...),
    referenceProvider: { setIndex in ... },
    onComplete: { weight, reps, rir, isWarmup in ... },
    onRIRZero: { exerciseName, completion in ... }
)`,
    preview: "logging-card",
  },
  {
    name: "RIRStepper",
    category: "Inputs",
    description: "Horizontal capsule buttons for RIR selection (0–5).",
    code: `RIRStepper(selected: $rir)
// Values: [-1, 0, 1, 2, 3, 4, 5]
// -1 = unset, 0 = failure (red highlight)`,
    preview: "rir-stepper",
  },
  {
    name: "MetricInputField",
    category: "Inputs",
    description: "Centered numeric input with label and keyboard type.",
    code: `MetricInputField(
    title: "WEIGHT (kg)",
    text: $weightText,
    keyboard: .decimalPad
)`,
    preview: "metric-input",
  },
  {
    name: "CompletedSetRow",
    category: "Workout",
    description: "Logged set display with success/failure indicators.",
    code: `CompletedSetRow(
    index: entry.setIndex + 1,
    entry: entry,
    reference: referenceProvider(entry.setIndex)
)`,
    preview: "completed-row",
  },
  {
    name: "RestTimerPanel",
    category: "Workout",
    description: "Rest timer with preset buttons and Live Activity support.",
    code: `RestTimerPanel(manager: restTimer)
// Presets: 1:30, 2:00
// Integrates with iOS Live Activities`,
    preview: "rest-timer",
  },
  {
    name: "TargetColumn",
    category: "Workout",
    description: "Ghost/read-only target display from progression engine.",
    code: `TargetColumn(weightKg: 100, reps: 5)`,
    preview: "target-column",
  },
]

const categories = [...new Set(components.map((c) => c.category))]

// Preview components
function CardPreview() {
  return (
    <div
      style={{
        padding: theme.spacing.md,
        background: theme.colors.card,
        borderRadius: theme.radius.lg,
      }}
    >
      <div style={{ color: theme.colors.textPrimary, fontWeight: 600 }}>Card Content</div>
      <div style={{ color: theme.colors.textSecondary, fontSize: 14, marginTop: 4 }}>Secondary text</div>
    </div>
  )
}

function ButtonPreview() {
  const [pressed, setPressed] = useState(false)
  return (
    <button
      onMouseDown={() => setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onMouseLeave={() => setPressed(false)}
      style={{
        transform: pressed ? "scale(0.97)" : "scale(1)",
        transition: "transform 0.15s ease-in-out",
        padding: `${theme.spacing.sm}px ${theme.spacing.md}px`,
        background: theme.colors.accent,
        color: "white",
        borderRadius: 22,
        border: "none",
        fontWeight: 600,
        cursor: "pointer",
      }}
    >
      Start Session
    </button>
  )
}

function TrainingCardPreview() {
  return (
    <div
      style={{
        padding: theme.spacing.md,
        background: theme.colors.card,
        borderRadius: theme.radius.lg,
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <div>
          <div style={{ color: theme.colors.textSecondary, fontSize: 12 }}>Compared to last Push</div>
          <div style={{ color: theme.colors.textPrimary, fontSize: 20, fontWeight: 700 }}>Push</div>
        </div>
        <button
          style={{
            display: "flex",
            alignItems: "center",
            gap: 6,
            padding: `${theme.spacing.xs}px ${theme.spacing.md}px`,
            background: theme.colors.accent,
            color: "white",
            borderRadius: 22,
            border: "none",
            fontWeight: 600,
            fontSize: 14,
          }}
        >
          <span>▶</span> Start Session
        </button>
      </div>
      <div style={{ borderTop: `1px solid ${theme.colors.border}`, marginTop: 12, paddingTop: 12 }}>
        <div style={{ display: "flex", justifyContent: "space-between" }}>
          <span style={{ color: theme.colors.textPrimary, fontSize: 14 }}>Bench Press</span>
          <div style={{ textAlign: "right" }}>
            <div style={{ color: theme.colors.textSecondary, fontSize: 12 }}>Last: 97.5kg × 5</div>
            <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
              <span style={{ color: theme.colors.textPrimary, fontSize: 14 }}>Today: 100kg × 5</span>
              <span
                style={{
                  background: theme.colors.accentSoft,
                  color: theme.colors.accent,
                  padding: "2px 6px",
                  borderRadius: 10,
                  fontSize: 12,
                  fontWeight: 600,
                }}
              >
                +2.5kg
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function RIRStepperPreview() {
  const [selected, setSelected] = useState(2)
  const values = ["-", "0", "1", "2", "3", "4", "5"]
  return (
    <div>
      <div style={{ color: theme.colors.textSecondary, fontSize: 12, marginBottom: 6 }}>RIR (Reps in Reserve)</div>
      <div style={{ display: "flex", gap: 4 }}>
        {values.map((v, i) => (
          <button
            key={i}
            onClick={() => setSelected(i - 1)}
            style={{
              flex: 1,
              padding: "10px 0",
              background: selected === i - 1 ? (i === 1 ? theme.colors.failure : theme.colors.accent) : theme.colors.background,
              color:
                selected === i - 1 ? "white" : i === 1 ? theme.colors.failure : theme.colors.textPrimary,
              borderRadius: 20,
              border: "none",
              fontWeight: selected === i - 1 ? 700 : 400,
              cursor: "pointer",
            }}
          >
            {v}
          </button>
        ))}
      </div>
    </div>
  )
}

function MetricInputPreview() {
  return (
    <div style={{ flex: 1 }}>
      <div style={{ color: theme.colors.textSecondary, fontSize: 12, marginBottom: 4 }}>WEIGHT (kg)</div>
      <div
        style={{
          background: theme.colors.background,
          border: `0.5px solid ${theme.colors.border}`,
          borderRadius: theme.radius.md,
          padding: `${theme.spacing.sm}px`,
          textAlign: "center",
        }}
      >
        <span style={{ color: theme.colors.textPrimary, fontSize: 18, fontWeight: 600 }}>100</span>
      </div>
    </div>
  )
}

function CompletedRowPreview() {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        padding: `${theme.spacing.sm}px`,
        background: theme.colors.background,
        borderRadius: theme.radius.md,
        gap: 12,
      }}
    >
      <span style={{ color: theme.colors.textSecondary, fontSize: 12, width: 44 }}>Set 1</span>
      <span style={{ color: theme.colors.textPrimary, fontSize: 14 }}>100 kg</span>
      <span style={{ color: theme.colors.textPrimary, fontSize: 14 }}>× 5</span>
      <span style={{ flex: 1 }} />
      <span style={{ color: theme.colors.textSecondary, fontSize: 12 }}>RIR 2</span>
      <span style={{ color: theme.colors.accent }}>✓</span>
    </div>
  )
}

function TargetColumnPreview() {
  return (
    <div
      style={{
        background: theme.colors.background,
        borderRadius: theme.radius.md,
        padding: theme.spacing.sm,
        textAlign: "left",
      }}
    >
      <div style={{ color: theme.colors.ghostText, fontSize: 12, marginBottom: 4 }}>TARGET</div>
      <div style={{ color: theme.colors.ghostText, fontSize: 18, fontWeight: 600 }}>100kg</div>
      <div style={{ color: theme.colors.ghostText, fontSize: 12 }}>× 5</div>
    </div>
  )
}

function RestTimerPreview() {
  return (
    <div
      style={{
        padding: theme.spacing.md,
        background: theme.colors.card,
        borderRadius: theme.radius.lg,
      }}
    >
      <div style={{ color: theme.colors.textPrimary, fontWeight: 600, marginBottom: 8 }}>Rest Timer</div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ color: theme.colors.textPrimary, fontSize: 32, fontWeight: 700 }}>1:30</span>
        <div style={{ display: "flex", gap: 8 }}>
          <button
            style={{
              padding: "8px 12px",
              background: "transparent",
              color: theme.colors.accent,
              border: "none",
              fontSize: 14,
              cursor: "pointer",
            }}
          >
            1:30
          </button>
          <button
            style={{
              padding: "8px 12px",
              background: "transparent",
              color: theme.colors.accent,
              border: "none",
              fontSize: 14,
              cursor: "pointer",
            }}
          >
            2:00
          </button>
        </div>
      </div>
    </div>
  )
}

function getPreview(type: string) {
  switch (type) {
    case "card":
      return <CardPreview />
    case "button":
      return <ButtonPreview />
    case "training-card":
      return <TrainingCardPreview />
    case "rir-stepper":
      return <RIRStepperPreview />
    case "metric-input":
      return <MetricInputPreview />
    case "completed-row":
      return <CompletedRowPreview />
    case "target-column":
      return <TargetColumnPreview />
    case "rest-timer":
      return <RestTimerPreview />
    default:
      return <CardPreview />
  }
}

export default function ComponentDocsPage() {
  const [activeCategory, setActiveCategory] = useState<string | null>(null)

  const filteredComponents = activeCategory
    ? components.filter((c) => c.category === activeCategory)
    : components

  return (
    <div
      style={{
        minHeight: "100vh",
        background: theme.colors.background,
        color: theme.colors.textPrimary,
        fontFamily: "system-ui, -apple-system, sans-serif",
      }}
    >
      {/* Header */}
      <header
        style={{
          padding: `${theme.spacing.lg}px ${theme.spacing.md}px`,
          borderBottom: `1px solid ${theme.colors.border}`,
          position: "sticky",
          top: 0,
          background: theme.colors.background,
          zIndex: 100,
        }}
      >
        <div style={{ maxWidth: 1200, margin: "0 auto" }}>
          <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>Unit Design System</h1>
          <p style={{ color: theme.colors.textSecondary, marginTop: 4, fontSize: 14 }}>
            iOS Component Library Documentation
          </p>
        </div>
      </header>

      <div style={{ maxWidth: 1200, margin: "0 auto", padding: theme.spacing.md }}>
        {/* Color Palette */}
        <section style={{ marginBottom: theme.spacing.xxl }}>
          <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: theme.spacing.md }}>Color Palette</h2>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fill, minmax(140px, 1fr))",
              gap: theme.spacing.sm,
            }}
          >
            {Object.entries(theme.colors).map(([name, value]) => (
              <div
                key={name}
                style={{
                  background: theme.colors.card,
                  borderRadius: theme.radius.md,
                  overflow: "hidden",
                }}
              >
                <div style={{ height: 48, background: value }} />
                <div style={{ padding: theme.spacing.sm }}>
                  <div style={{ fontSize: 13, fontWeight: 500 }}>{name}</div>
                  <div style={{ fontSize: 11, color: theme.colors.textSecondary }}>{value}</div>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Spacing Scale */}
        <section style={{ marginBottom: theme.spacing.xxl }}>
          <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: theme.spacing.md }}>Spacing Scale</h2>
          <div style={{ display: "flex", flexWrap: "wrap", gap: theme.spacing.md }}>
            {Object.entries(theme.spacing).map(([name, value]) => (
              <div key={name} style={{ textAlign: "center" }}>
                <div
                  style={{
                    width: value,
                    height: value,
                    background: theme.colors.accent,
                    borderRadius: 4,
                    marginBottom: 4,
                  }}
                />
                <div style={{ fontSize: 12 }}>{name}</div>
                <div style={{ fontSize: 11, color: theme.colors.textSecondary }}>{value}px</div>
              </div>
            ))}
          </div>
        </section>

        {/* Radius Scale */}
        <section style={{ marginBottom: theme.spacing.xxl }}>
          <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: theme.spacing.md }}>Border Radius</h2>
          <div style={{ display: "flex", gap: theme.spacing.lg }}>
            {Object.entries(theme.radius).map(([name, value]) => (
              <div key={name} style={{ textAlign: "center" }}>
                <div
                  style={{
                    width: 64,
                    height: 64,
                    background: theme.colors.card,
                    borderRadius: value,
                    marginBottom: 8,
                  }}
                />
                <div style={{ fontSize: 12 }}>{name}</div>
                <div style={{ fontSize: 11, color: theme.colors.textSecondary }}>{value}px</div>
              </div>
            ))}
          </div>
        </section>

        {/* Category Filter */}
        <section style={{ marginBottom: theme.spacing.lg }}>
          <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: theme.spacing.md }}>Components</h2>
          <div style={{ display: "flex", flexWrap: "wrap", gap: theme.spacing.xs, marginBottom: theme.spacing.md }}>
            <button
              onClick={() => setActiveCategory(null)}
              style={{
                padding: `${theme.spacing.xs}px ${theme.spacing.sm}px`,
                background: !activeCategory ? theme.colors.accent : theme.colors.card,
                color: !activeCategory ? "white" : theme.colors.textPrimary,
                borderRadius: 16,
                border: "none",
                fontSize: 13,
                cursor: "pointer",
              }}
            >
              All
            </button>
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setActiveCategory(cat)}
                style={{
                  padding: `${theme.spacing.xs}px ${theme.spacing.sm}px`,
                  background: activeCategory === cat ? theme.colors.accent : theme.colors.card,
                  color: activeCategory === cat ? "white" : theme.colors.textPrimary,
                  borderRadius: 16,
                  border: "none",
                  fontSize: 13,
                  cursor: "pointer",
                }}
              >
                {cat}
              </button>
            ))}
          </div>
        </section>

        {/* Component Grid */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(360px, 1fr))",
            gap: theme.spacing.md,
          }}
        >
          {filteredComponents.map((comp) => (
            <div
              key={comp.name}
              style={{
                background: theme.colors.card,
                borderRadius: theme.radius.lg,
                overflow: "hidden",
              }}
            >
              {/* Preview */}
              <div
                style={{
                  padding: theme.spacing.md,
                  background: theme.colors.elevated,
                  minHeight: 120,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                {getPreview(comp.preview)}
              </div>

              {/* Info */}
              <div style={{ padding: theme.spacing.md }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 8 }}>
                  <span style={{ fontSize: 16, fontWeight: 600 }}>{comp.name}</span>
                  <span
                    style={{
                      fontSize: 11,
                      padding: "2px 8px",
                      background: theme.colors.accentSoft,
                      color: theme.colors.accent,
                      borderRadius: 10,
                    }}
                  >
                    {comp.category}
                  </span>
                </div>
                <p style={{ color: theme.colors.textSecondary, fontSize: 13, marginBottom: 12 }}>
                  {comp.description}
                </p>
                <pre
                  style={{
                    background: theme.colors.background,
                    padding: theme.spacing.sm,
                    borderRadius: theme.radius.sm,
                    fontSize: 11,
                    overflow: "auto",
                    color: theme.colors.textSecondary,
                    margin: 0,
                  }}
                >
                  {comp.code}
                </pre>
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <footer
          style={{
            marginTop: theme.spacing.xxl,
            paddingTop: theme.spacing.lg,
            borderTop: `1px solid ${theme.colors.border}`,
            textAlign: "center",
            color: theme.colors.textSecondary,
            fontSize: 13,
          }}
        >
          Unit iOS App - Design System v1.0
        </footer>
      </div>
    </div>
  )
}
