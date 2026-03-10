"use client"

import { useState } from "react"

// Navigation sections
const sections = [
  { id: "colors", label: "Colors" },
  { id: "typography", label: "Typography" },
  { id: "spacing", label: "Spacing" },
  { id: "radius", label: "Radius" },
  { id: "components", label: "Components" },
]

// Color tokens
const colors = [
  { name: "accent", value: "#FF4400", description: "Primary brand color, CTAs" },
  { name: "accent-soft", value: "rgba(255, 68, 0, 0.12)", description: "Subtle accent backgrounds" },
  { name: "background", value: "#111318", description: "Page background" },
  { name: "elevated", value: "#1A1D25", description: "Sheets, grouped sections" },
  { name: "card", value: "#252831", description: "Card surfaces" },
  { name: "text-primary", value: "rgba(255, 255, 255, 0.92)", description: "Main text" },
  { name: "text-secondary", value: "rgba(255, 255, 255, 0.55)", description: "Supporting text" },
  { name: "border", value: "rgba(255, 255, 255, 0.12)", description: "Dividers, input borders" },
  { name: "ghost", value: "rgba(255, 255, 255, 0.55)", description: "Target/readonly values" },
  { name: "progress", value: "#D65400", description: "Charts, progress indicators" },
  { name: "failure", value: "#FF3B30", description: "Error states, RIR 0" },
  { name: "deload", value: "rgba(255, 165, 0, 0.8)", description: "Deload week badges" },
]

// Spacing scale
const spacingScale = [
  { name: "xxs", value: 4 },
  { name: "xs", value: 8 },
  { name: "sm", value: 12 },
  { name: "md", value: 16 },
  { name: "lg", value: 24 },
  { name: "xl", value: 32 },
  { name: "xxl", value: 48 },
  { name: "xxxl", value: 64 },
]

// Radius scale
const radiusScale = [
  { name: "sm", value: 10, usage: "Small elements, badges" },
  { name: "md", value: 14, usage: "Inputs, buttons" },
  { name: "lg", value: 18, usage: "Cards, containers" },
]

// Typography scale
const typographyScale = [
  { name: "hero", size: "22px", weight: 700, usage: "Page titles, large numbers" },
  { name: "title", size: "17px", weight: 600, usage: "Section headers, card titles" },
  { name: "body", size: "15px", weight: 400, usage: "Body text, descriptions" },
  { name: "caption", size: "13px", weight: 400, usage: "Labels, metadata" },
  { name: "metric", size: "20px", weight: 600, usage: "Numeric displays" },
]

// Component definitions
const components = [
  {
    name: "Card",
    category: "Layout",
    description: "Standard card container with fill contrast only - no shadow, no border.",
    swiftCode: `.cardStyle()
// Equivalent to:
.padding(Theme.Spacing.md)
.background(Theme.Colors.card)
.clipShape(RoundedRectangle(
    cornerRadius: Theme.Radius.lg,
    style: .continuous
))`,
    preview: "card",
  },
  {
    name: "ScaleButtonStyle",
    category: "Interaction",
    description: "Micro-scale tap feedback (0.97x) for interactive elements.",
    swiftCode: `Button(action: onTap) {
    Text("Start Session")
}
.buttonStyle(ScaleButtonStyle())`,
    preview: "scale-button",
  },
  {
    name: "RIR Stepper",
    category: "Input",
    description: "Horizontal capsule buttons for RIR selection (0-5). Zero shows red highlight.",
    swiftCode: `RIRStepper(selected: $rir)
// Values: [-1, 0, 1, 2, 3, 4, 5]
// -1 = unset, 0 = failure (red)`,
    preview: "rir-stepper",
  },
  {
    name: "Metric Input",
    category: "Input",
    description: "Centered numeric input with label for weight/reps entry.",
    swiftCode: `MetricInputField(
    title: "WEIGHT (kg)",
    text: $weightText,
    keyboard: .decimalPad
)`,
    preview: "metric-input",
  },
  {
    name: "Target Column",
    category: "Display",
    description: "Ghost/read-only target display from progression engine.",
    swiftCode: `TargetColumn(
    weightKg: 100,
    reps: 5
)`,
    preview: "target-column",
  },
  {
    name: "Completed Set Row",
    category: "Display",
    description: "Logged set display with success/failure indicators.",
    swiftCode: `CompletedSetRow(
    index: entry.setIndex + 1,
    entry: entry,
    reference: referenceProvider(entry.setIndex)
)`,
    preview: "completed-row",
  },
  {
    name: "Delta Badge",
    category: "Feedback",
    description: "Shows weight progression delta with accent background.",
    swiftCode: `DeltaBadge(deltaKg: 2.5)
// Displays: "+2.5kg" with accent-soft bg`,
    preview: "delta-badge",
  },
  {
    name: "Rest Timer",
    category: "Workout",
    description: "Rest timer with preset buttons and countdown display.",
    swiftCode: `RestTimerPanel(manager: restTimer)
// Presets: 1:30, 2:00
// Integrates with iOS Live Activities`,
    preview: "rest-timer",
  },
]

const categories = [...new Set(components.map((c) => c.category))]

// Preview Components
function CardPreview() {
  return (
    <div className="rounded-[18px] bg-[#252831] p-4">
      <p className="text-[rgba(255,255,255,0.92)] font-semibold">Card Title</p>
      <p className="text-[rgba(255,255,255,0.55)] text-sm mt-1">Supporting description text</p>
    </div>
  )
}

function ScaleButtonPreview() {
  const [pressed, setPressed] = useState(false)
  return (
    <button
      onMouseDown={() => setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onMouseLeave={() => setPressed(false)}
      className="flex items-center gap-2 px-4 py-2.5 bg-[#FF4400] text-white rounded-full font-semibold text-sm transition-transform duration-150"
      style={{ transform: pressed ? "scale(0.97)" : "scale(1)" }}
    >
      <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M8 5v14l11-7z" />
      </svg>
      Start Session
    </button>
  )
}

function RIRStepperPreview() {
  const [selected, setSelected] = useState(2)
  const values = ["-", "0", "1", "2", "3", "4", "5"]
  return (
    <div className="w-full max-w-xs">
      <p className="text-[rgba(255,255,255,0.55)] text-xs mb-2">RIR (Reps in Reserve)</p>
      <div className="flex gap-1">
        {values.map((v, i) => {
          const isSelected = selected === i - 1
          const isZero = i === 1
          return (
            <button
              key={i}
              onClick={() => setSelected(i - 1)}
              className={`flex-1 py-2.5 rounded-full text-sm font-medium transition-colors ${
                isSelected
                  ? isZero
                    ? "bg-[#FF3B30] text-white"
                    : "bg-[#FF4400] text-white font-bold"
                  : isZero
                    ? "bg-[#111318] text-[#FF3B30]"
                    : "bg-[#111318] text-[rgba(255,255,255,0.92)]"
              }`}
            >
              {v}
            </button>
          )
        })}
      </div>
    </div>
  )
}

function MetricInputPreview() {
  return (
    <div className="flex gap-3 w-full max-w-xs">
      <div className="flex-1">
        <p className="text-[rgba(255,255,255,0.55)] text-xs mb-1.5 uppercase tracking-wide">Weight (kg)</p>
        <div className="bg-[#111318] border border-[rgba(255,255,255,0.12)] rounded-[14px] py-3 text-center">
          <span className="text-[rgba(255,255,255,0.92)] text-lg font-semibold">100</span>
        </div>
      </div>
      <div className="flex-1">
        <p className="text-[rgba(255,255,255,0.55)] text-xs mb-1.5 uppercase tracking-wide">Reps</p>
        <div className="bg-[#111318] border border-[rgba(255,255,255,0.12)] rounded-[14px] py-3 text-center">
          <span className="text-[rgba(255,255,255,0.92)] text-lg font-semibold">5</span>
        </div>
      </div>
    </div>
  )
}

function TargetColumnPreview() {
  return (
    <div className="bg-[#111318] rounded-[14px] p-3 text-left">
      <p className="text-[rgba(255,255,255,0.55)] text-xs mb-1">TARGET</p>
      <p className="text-[rgba(255,255,255,0.55)] text-xl font-semibold">100kg</p>
      <p className="text-[rgba(255,255,255,0.55)] text-sm">x 5</p>
    </div>
  )
}

function CompletedRowPreview() {
  return (
    <div className="flex items-center gap-3 p-3 bg-[#111318] rounded-[14px] w-full max-w-sm">
      <span className="text-[rgba(255,255,255,0.55)] text-xs w-10">Set 1</span>
      <span className="text-[rgba(255,255,255,0.92)] text-sm">100 kg</span>
      <span className="text-[rgba(255,255,255,0.92)] text-sm">x 5</span>
      <span className="flex-1" />
      <span className="text-[rgba(255,255,255,0.55)] text-xs">RIR 2</span>
      <svg className="w-4 h-4 text-[#FF4400]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
      </svg>
    </div>
  )
}

function DeltaBadgePreview() {
  return (
    <span className="inline-flex items-center px-2 py-0.5 bg-[rgba(255,68,0,0.12)] text-[#FF4400] rounded-full text-xs font-semibold">
      +2.5kg
    </span>
  )
}

function RestTimerPreview() {
  return (
    <div className="rounded-[18px] bg-[#252831] p-4 w-full max-w-xs">
      <p className="text-[rgba(255,255,255,0.92)] font-semibold mb-3">Rest Timer</p>
      <div className="flex items-center justify-between">
        <span className="text-[rgba(255,255,255,0.92)] text-4xl font-bold tabular-nums">1:30</span>
        <div className="flex gap-2">
          <button className="px-3 py-1.5 text-[#FF4400] text-sm font-medium">1:30</button>
          <button className="px-3 py-1.5 text-[#FF4400] text-sm font-medium">2:00</button>
        </div>
      </div>
    </div>
  )
}

function getPreview(type: string) {
  switch (type) {
    case "card":
      return <CardPreview />
    case "scale-button":
      return <ScaleButtonPreview />
    case "rir-stepper":
      return <RIRStepperPreview />
    case "metric-input":
      return <MetricInputPreview />
    case "target-column":
      return <TargetColumnPreview />
    case "completed-row":
      return <CompletedRowPreview />
    case "delta-badge":
      return <DeltaBadgePreview />
    case "rest-timer":
      return <RestTimerPreview />
    default:
      return <CardPreview />
  }
}

function CodeBlock({ code }: { code: string }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = () => {
    navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="relative group">
      <pre className="bg-[#111318] rounded-[10px] p-3 text-xs overflow-x-auto">
        <code className="text-[rgba(255,255,255,0.75)]">{code}</code>
      </pre>
      <button
        onClick={handleCopy}
        className="absolute top-2 right-2 p-1.5 rounded-md bg-[#252831] opacity-0 group-hover:opacity-100 transition-opacity"
      >
        {copied ? (
          <svg className="w-4 h-4 text-[#FF4400]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
        ) : (
          <svg className="w-4 h-4 text-[rgba(255,255,255,0.55)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
            />
          </svg>
        )}
      </button>
    </div>
  )
}

export default function DesignSystemPage() {
  const [activeCategory, setActiveCategory] = useState<string | null>(null)
  const [activeSection, setActiveSection] = useState("colors")

  const filteredComponents = activeCategory
    ? components.filter((c) => c.category === activeCategory)
    : components

  return (
    <div className="min-h-screen bg-[#111318]">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-[#111318]/95 backdrop-blur-sm border-b border-[rgba(255,255,255,0.08)]">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-[rgba(255,255,255,0.92)]">Unit Design System</h1>
            <p className="text-sm text-[rgba(255,255,255,0.55)]">iOS Component Library</p>
          </div>
          <nav className="hidden md:flex items-center gap-1">
            {sections.map((section) => (
              <a
                key={section.id}
                href={`#${section.id}`}
                onClick={() => setActiveSection(section.id)}
                className={`px-3 py-1.5 rounded-full text-sm transition-colors ${
                  activeSection === section.id
                    ? "bg-[rgba(255,68,0,0.12)] text-[#FF4400]"
                    : "text-[rgba(255,255,255,0.55)] hover:text-[rgba(255,255,255,0.92)]"
                }`}
              >
                {section.label}
              </a>
            ))}
          </nav>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-4 py-8">
        {/* Hero */}
        <section className="mb-16">
          <div className="rounded-[18px] bg-gradient-to-br from-[#1A1D25] to-[#252831] p-8 md:p-12">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 rounded-[14px] bg-[#FF4400] flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z"
                  />
                </svg>
              </div>
              <div>
                <h2 className="text-2xl font-bold text-[rgba(255,255,255,0.92)]">Design Tokens & Components</h2>
                <p className="text-[rgba(255,255,255,0.55)]">Dark-only theme inspired by Revolut</p>
              </div>
            </div>
            <p className="text-[rgba(255,255,255,0.75)] max-w-2xl leading-relaxed">
              Unit uses a restrained dark palette with orange (#FF4400) as the primary accent. 
              The design philosophy emphasizes fill contrast without shadows, continuous corner radius, 
              and subtle micro-interactions for feedback.
            </p>
          </div>
        </section>

        {/* Colors */}
        <section id="colors" className="mb-16 scroll-mt-20">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-8 h-8 rounded-lg bg-[#FF4400] flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 22C6.49 22 2 17.51 2 12S6.49 2 12 2s10 4.04 10 9c0 3.31-2.69 6-6 6h-1.77c-.28 0-.5.22-.5.5 0 .12.05.23.13.33.41.47.64 1.06.64 1.67A2.5 2.5 0 0112 22zm0-18c-4.41 0-8 3.59-8 8s3.59 8 8 8c.28 0 .5-.22.5-.5a.54.54 0 00-.14-.35c-.41-.46-.63-1.05-.63-1.65a2.5 2.5 0 012.5-2.5H16c2.21 0 4-1.79 4-4 0-3.86-3.59-7-8-7z" />
                <circle cx="6.5" cy="11.5" r="1.5" />
                <circle cx="9.5" cy="7.5" r="1.5" />
                <circle cx="14.5" cy="7.5" r="1.5" />
                <circle cx="17.5" cy="11.5" r="1.5" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-[rgba(255,255,255,0.92)]">Color Palette</h3>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            {colors.map((color) => (
              <div key={color.name} className="rounded-[14px] bg-[#252831] overflow-hidden">
                <div className="h-16" style={{ background: color.value }} />
                <div className="p-3">
                  <p className="text-sm font-medium text-[rgba(255,255,255,0.92)]">{color.name}</p>
                  <p className="text-xs text-[rgba(255,255,255,0.55)] mt-0.5">{color.description}</p>
                  <p className="text-xs text-[rgba(255,255,255,0.35)] mt-1 font-mono">{color.value}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Typography */}
        <section id="typography" className="mb-16 scroll-mt-20">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-8 h-8 rounded-lg bg-[#FF4400] flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M5 4v3h5.5v12h3V7H19V4z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-[rgba(255,255,255,0.92)]">Typography</h3>
          </div>
          <div className="rounded-[18px] bg-[#252831] overflow-hidden">
            {typographyScale.map((type, i) => (
              <div
                key={type.name}
                className={`flex flex-col md:flex-row md:items-center gap-2 md:gap-6 p-4 ${
                  i !== typographyScale.length - 1 ? "border-b border-[rgba(255,255,255,0.08)]" : ""
                }`}
              >
                <div className="w-24 shrink-0">
                  <span className="text-xs font-mono text-[rgba(255,255,255,0.55)]">{type.name}</span>
                </div>
                <div className="flex-1">
                  <p
                    className="text-[rgba(255,255,255,0.92)]"
                    style={{ fontSize: type.size, fontWeight: type.weight }}
                  >
                    The quick brown fox
                  </p>
                </div>
                <div className="flex items-center gap-4 text-xs text-[rgba(255,255,255,0.55)]">
                  <span>{type.size}</span>
                  <span>Weight {type.weight}</span>
                </div>
                <p className="text-xs text-[rgba(255,255,255,0.35)] md:w-40">{type.usage}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Spacing */}
        <section id="spacing" className="mb-16 scroll-mt-20">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-8 h-8 rounded-lg bg-[#FF4400] flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"
                />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-[rgba(255,255,255,0.92)]">Spacing Scale</h3>
          </div>
          <div className="rounded-[18px] bg-[#252831] p-6">
            <div className="flex flex-wrap items-end gap-6">
              {spacingScale.map((space) => (
                <div key={space.name} className="flex flex-col items-center">
                  <div
                    className="bg-[#FF4400] rounded"
                    style={{ width: space.value, height: space.value }}
                  />
                  <p className="text-xs font-mono text-[rgba(255,255,255,0.55)] mt-2">{space.name}</p>
                  <p className="text-xs text-[rgba(255,255,255,0.35)]">{space.value}px</p>
                </div>
              ))}
            </div>
            <div className="mt-6 pt-4 border-t border-[rgba(255,255,255,0.08)]">
              <CodeBlock
                code={`enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}`}
              />
            </div>
          </div>
        </section>

        {/* Radius */}
        <section id="radius" className="mb-16 scroll-mt-20">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-8 h-8 rounded-lg bg-[#FF4400] flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M4 5a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM14 5a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1V5zM4 15a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H5a1 1 0 01-1-1v-4zM14 15a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z"
                />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-[rgba(255,255,255,0.92)]">Border Radius</h3>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {radiusScale.map((radius) => (
              <div key={radius.name} className="rounded-[18px] bg-[#252831] p-6">
                <div
                  className="w-24 h-24 bg-[#1A1D25] mb-4"
                  style={{ borderRadius: radius.value }}
                />
                <p className="text-sm font-semibold text-[rgba(255,255,255,0.92)]">{radius.name}</p>
                <p className="text-xs text-[rgba(255,255,255,0.55)] mt-1">{radius.value}px</p>
                <p className="text-xs text-[rgba(255,255,255,0.35)] mt-2">{radius.usage}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Components */}
        <section id="components" className="scroll-mt-20">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-8 h-8 rounded-lg bg-[#FF4400] flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-[rgba(255,255,255,0.92)]">Components</h3>
          </div>

          {/* Category Filter */}
          <div className="flex flex-wrap gap-2 mb-6">
            <button
              onClick={() => setActiveCategory(null)}
              className={`px-3 py-1.5 rounded-full text-sm transition-colors ${
                !activeCategory
                  ? "bg-[#FF4400] text-white"
                  : "bg-[#252831] text-[rgba(255,255,255,0.75)] hover:text-white"
              }`}
            >
              All
            </button>
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setActiveCategory(cat)}
                className={`px-3 py-1.5 rounded-full text-sm transition-colors ${
                  activeCategory === cat
                    ? "bg-[#FF4400] text-white"
                    : "bg-[#252831] text-[rgba(255,255,255,0.75)] hover:text-white"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          {/* Component Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {filteredComponents.map((comp) => (
              <div key={comp.name} className="rounded-[18px] bg-[#252831] overflow-hidden">
                {/* Preview */}
                <div className="bg-[#1A1D25] p-6 min-h-[140px] flex items-center justify-center">
                  {getPreview(comp.preview)}
                </div>
                {/* Info */}
                <div className="p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <h4 className="font-semibold text-[rgba(255,255,255,0.92)]">{comp.name}</h4>
                    <span className="px-2 py-0.5 bg-[rgba(255,68,0,0.12)] text-[#FF4400] rounded-full text-xs">
                      {comp.category}
                    </span>
                  </div>
                  <p className="text-sm text-[rgba(255,255,255,0.55)] mb-4">{comp.description}</p>
                  <CodeBlock code={comp.swiftCode} />
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Footer */}
        <footer className="mt-16 pt-8 border-t border-[rgba(255,255,255,0.08)]">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4 text-sm text-[rgba(255,255,255,0.55)]">
            <p>Unit Design System - iOS SwiftUI Component Library</p>
            <p>Theme: Dark only | Accent: #FF4400</p>
          </div>
        </footer>
      </main>
    </div>
  )
}
