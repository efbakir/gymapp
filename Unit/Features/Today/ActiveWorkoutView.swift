//
//  ActiveWorkoutView.swift
//  Unit
//
//  Active workout: execution focus mode — one exercise at a time, target strip, rest timer strip.
//

import ActivityKit
import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query private var progressionRules: [ProgressionRule]
    @Query private var cycles: [Cycle]

    @State private var viewModel = ActiveWorkoutViewModel()
    @State private var restTimer = RestTimerManager()

    @State private var currentExerciseIndex: Int = 0
    @State private var showLineup = false
    @State private var showingEndWorkoutFeeling = false
    @State private var toastMessage: String?
    @State private var showFailureModal = false
    @State private var pendingFailureExerciseName = ""
    @State private var failureCallbackHolder = FailureCallbackHolder()

    private var template: DayTemplate? {
        templates.first(where: { $0.id == session.templateId })
    }

    private var activeCycle: Cycle? {
        guard let cid = session.cycleId else { return nil }
        return cycles.first(where: { $0.id == cid })
    }

    private var orderedExercises: [Exercise] {
        guard let template else { return [] }
        return template.orderedExerciseIds.compactMap { id in
            exercises.first(where: { $0.id == id })
        }
    }

    private var currentExercise: Exercise? {
        guard currentExerciseIndex < orderedExercises.count else { return nil }
        return orderedExercises[currentExerciseIndex]
    }

    private var navigationTitle: String {
        guard !orderedExercises.isEmpty else { return template?.name ?? "Workout" }
        return "\(template?.name ?? "Workout") · \(currentExerciseIndex + 1) of \(orderedExercises.count)"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Rest timer — compact strip, always at top
                restTimerStrip

                // Current exercise — scrollable
                ScrollView {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                        if let exercise = currentExercise {
                            let rule = progressionRules.first(where: {
                                $0.exerciseId == exercise.id && $0.cycleId == session.cycleId
                            })
                            let lastActual: (weight: Double, reps: Int)? = {
                                guard let lastSession = sessions.first(where: {
                                    $0.templateId == session.templateId &&
                                    $0.id != session.id &&
                                    $0.isCompleted
                                }) else { return nil }
                                let best = lastSession.setEntries
                                    .filter { $0.exerciseId == exercise.id && $0.isCompleted && !$0.isWarmup }
                                    .max { $0.weight < $1.weight }
                                return best.map { ($0.weight, $0.reps) }
                            }()
                            ExerciseLoggingCard(
                                exercise: exercise,
                                progressionRule: rule,
                                activeCycle: activeCycle,
                                weekNumber: session.weekNumber,
                                currentEntries: currentEntries(for: exercise.id),
                                lastActual: lastActual,
                                prefill: viewModel.prefillSet(
                                    for: exercise.id,
                                    currentSession: session,
                                    sessions: sessions,
                                    rule: rule,
                                    cycle: activeCycle
                                ),
                                referenceProvider: { setIndex in
                                    viewModel.referenceSet(
                                        for: exercise.id,
                                        setIndex: setIndex,
                                        currentSession: session,
                                        sessions: sessions
                                    )
                                },
                                onComplete: { weight, reps, rir, isWarmup in
                                    completeSet(exercise: exercise, rule: rule, weight: weight, reps: reps, rir: rir, isWarmup: isWarmup)
                                },
                                onRIRZero: { exerciseName, completion in
                                    pendingFailureExerciseName = exerciseName
                                    failureCallbackHolder.completion = completion
                                    showFailureModal = true
                                }
                            )
                        }
                    }
                    .padding(AtlasTheme.Spacing.md)
                    .padding(.bottom, AtlasTheme.Spacing.xl)
                }
                .background(AtlasTheme.Colors.background)

                // Bottom navigation bar
                bottomBar
            }

            // Toast overlay
            if let msg = toastMessage {
                toastView(msg)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                    .padding(.bottom, 80)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: toastMessage)
        .sheet(isPresented: $showLineup) {
            lineupSheet
        }
        .sheet(isPresented: $showingEndWorkoutFeeling) {
            EndWorkoutFeelingView(session: session) {
                showingEndWorkoutFeeling = false
                checkAndShowRecalibrationToast()
            }
        }
        .sheet(isPresented: $showFailureModal) {
            FailureConfirmationSheet(
                exerciseName: pendingFailureExerciseName,
                onConfirm: {
                    failureCallbackHolder.completion?(true)
                    failureCallbackHolder.completion = nil
                },
                onSkip: {
                    failureCallbackHolder.completion?(false)
                    failureCallbackHolder.completion = nil
                }
            )
            .presentationDetents([.height(280)])
        }
        .onDisappear {
            restTimer.stop()
        }
    }

    // MARK: - Rest Timer Strip

    private var restTimerStrip: some View {
        HStack(spacing: AtlasTheme.Spacing.sm) {
            Text(restTimer.isRunning ? restTimer.label : "Rest")
                .font(restTimer.isRunning
                    ? .system(size: 22, weight: .bold, design: .rounded)
                    : .system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(restTimer.isRunning ? AtlasTheme.Colors.accent : AtlasTheme.Colors.textSecondary)
                .animation(.easeInOut(duration: 0.15), value: restTimer.isRunning)
            Spacer()
            if restTimer.isRunning {
                Button("Stop") { restTimer.stop() }
                    .font(AtlasTheme.Typography.body)
                    .foregroundStyle(.red)
                    .frame(minWidth: 44, minHeight: 44)
            } else {
                HStack(spacing: AtlasTheme.Spacing.xs) {
                    Button("1:30") { restTimer.start(totalSeconds: 90) }
                    Button("2:00") { restTimer.start(totalSeconds: 120) }
                }
                .font(AtlasTheme.Typography.body)
                .foregroundStyle(AtlasTheme.Colors.accent)
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.md)
        .padding(.vertical, AtlasTheme.Spacing.xs)
        .background(AtlasTheme.Colors.elevatedBackground)
        .overlay(alignment: .bottom) {
            if restTimer.isRunning && restTimer.totalDuration > 0 {
                GeometryReader { geo in
                    let progress = Double(restTimer.secondsRemaining) / Double(restTimer.totalDuration)
                    Rectangle()
                        .fill(AtlasTheme.Colors.accent.opacity(0.45))
                        .frame(width: geo.size.width * max(0, min(progress, 1)), height: 2)
                        .animation(.linear(duration: 1), value: restTimer.secondsRemaining)
                }
                .frame(height: 2)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: AtlasTheme.Spacing.md) {
            Button {
                showLineup = true
            } label: {
                HStack(spacing: AtlasTheme.Spacing.xxs) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14))
                    Text("Lineup")
                        .font(AtlasTheme.Typography.body)
                }
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View today's exercise lineup")

            Spacer()

            if currentExerciseIndex < orderedExercises.count - 1 {
                let nextName = orderedExercises[currentExerciseIndex + 1].displayName
                    .components(separatedBy: " ").prefix(2).joined(separator: " ")
                Button {
                    currentExerciseIndex += 1
                } label: {
                    Text("Next: \(nextName)")
                        .font(AtlasTheme.Typography.sectionTitle)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .frame(height: 44)
                        .background(AtlasTheme.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Move to next exercise: \(orderedExercises[currentExerciseIndex + 1].displayName)")
            } else {
                Button {
                    showingEndWorkoutFeeling = true
                } label: {
                    Text("End Workout")
                        .font(AtlasTheme.Typography.sectionTitle)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .frame(height: 44)
                        .background(AtlasTheme.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.md)
        .padding(.vertical, AtlasTheme.Spacing.sm)
        .background(AtlasTheme.Colors.elevatedBackground)
    }

    // MARK: - Lineup Sheet

    private var lineupSheet: some View {
        NavigationStack {
            List {
                ForEach(Array(orderedExercises.enumerated()), id: \.element.id) { index, exercise in
                    HStack {
                        Text(exercise.displayName)
                            .font(AtlasTheme.Typography.body)
                            .foregroundStyle(index <= currentExerciseIndex ? AtlasTheme.Colors.textPrimary : AtlasTheme.Colors.textSecondary)
                        Spacer()
                        if index < currentExerciseIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AtlasTheme.Colors.accent)
                                .accessibilityHidden(true)
                        } else if index == currentExerciseIndex {
                            Text("Now")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundStyle(AtlasTheme.Colors.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AtlasTheme.Colors.accentSoft)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(minHeight: 44)
                    .accessibilityLabel(index < currentExerciseIndex ? "\(exercise.displayName), done" : index == currentExerciseIndex ? "\(exercise.displayName), current" : exercise.displayName)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AtlasTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Today's Lineup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showLineup = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(AtlasTheme.Colors.background)
    }

    // MARK: - Helpers

    private func currentEntries(for exerciseID: UUID) -> [SetEntry] {
        session.setEntries
            .filter { $0.exerciseId == exerciseID }
            .sorted { $0.setIndex < $1.setIndex }
    }

    private func completeSet(
        exercise: Exercise,
        rule: ProgressionRule?,
        weight: Double,
        reps: Int,
        rir: Int,
        isWarmup: Bool
    ) {
        let setIndex = currentEntries(for: exercise.id).count

        var targetWeight = 0.0
        var targetReps = 0
        if let rule, let cycle = activeCycle, session.weekNumber > 0 {
            let snapshot = rule.snapshot(weekCount: cycle.weekCount)
            let outcomes = rule.buildOutcomes(from: Array(sessions))
            if let wt = ProgressionEngine.target(for: session.weekNumber, rule: snapshot, outcomes: outcomes) {
                targetWeight = wt.weightKg
                targetReps = wt.reps
            }
        }

        let metTarget = (targetWeight > 0) ? (weight >= targetWeight && reps >= targetReps) : false

        let entry = SetEntry(
            sessionId: session.id,
            exerciseId: exercise.id,
            weight: weight,
            reps: reps,
            rpe: 0,
            rir: rir,
            targetWeight: targetWeight,
            targetReps: targetReps,
            metTarget: metTarget,
            isWarmup: isWarmup,
            isCompleted: true,
            setIndex: setIndex
        )
        entry.session = session
        modelContext.insert(entry)
        try? modelContext.save()

        restTimer.start(totalSeconds: 90)
    }

    private func checkAndShowRecalibrationToast() {
        let hasFailures = session.setEntries.contains { !$0.metTarget && $0.targetWeight > 0 }
        if hasFailures, let cycle = activeCycle, session.weekNumber > 0 {
            let futureWeeks = cycle.weekCount - session.weekNumber
            if futureWeeks > 0 {
                showToast("Future targets adjusted: Weeks \(session.weekNumber + 1)–\(cycle.weekCount) recalibrated")
            }
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            toastMessage = nil
        }
    }

    @ViewBuilder
    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(AtlasTheme.Typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.vertical, AtlasTheme.Spacing.sm)
            .background(AtlasTheme.Colors.elevatedBackground.opacity(0.95))
            .clipShape(Capsule())
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.bottom, AtlasTheme.Spacing.lg)
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Exercise Logging Card

private struct ExerciseLoggingCard: View {
    let exercise: Exercise
    let progressionRule: ProgressionRule?
    let activeCycle: Cycle?
    let weekNumber: Int
    let currentEntries: [SetEntry]
    let lastActual: (weight: Double, reps: Int)?
    let prefill: SetPrefill?
    let referenceProvider: (Int) -> SetEntry?
    let onComplete: (_ weight: Double, _ reps: Int, _ rir: Int, _ isWarmup: Bool) -> Void
    let onRIRZero: (_ exerciseName: String, _ completion: @escaping (Bool) -> Void) -> Void

    @State private var weightText = ""
    @State private var repsText = ""
    @State private var rir: Int = -1
    @State private var isWarmup = false
    @State private var seeded = false

    private var parsedWeight: Double {
        Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var parsedReps: Int { Int(repsText) ?? 0 }
    private var canComplete: Bool { parsedWeight > 0 || parsedReps > 0 }

    private var weekTarget: ProgressionEngine.WeekTarget? {
        guard let rule = progressionRule, let cycle = activeCycle, weekNumber > 0 else { return nil }
        return ProgressionEngine.target(for: weekNumber, rule: rule.snapshot(weekCount: cycle.weekCount), outcomes: [])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            // Exercise header + deload badge
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.displayName)
                    .font(AtlasTheme.Typography.hero)
                Spacer(minLength: 0)
                if weekNumber > 0 {
                    Text("Week \(weekNumber)")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .padding(.horizontal, AtlasTheme.Spacing.xs)
                        .padding(.vertical, AtlasTheme.Spacing.xxs)
                        .background(AtlasTheme.Colors.accentSoft)
                        .clipShape(Capsule())
                }
                if progressionRule?.isDeloaded == true {
                    Label("Deload", systemImage: "arrow.down.circle.fill")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.deloadBadge)
                        .accessibilityLabel("Deload week")
                }
            }

            // Last vs. context lines
            if let last = lastActual {
                Text("Last: \(last.weight.weightString)kg × \(last.reps)")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    .monospacedDigit()
            }

            // Completed set rows
            if !currentEntries.isEmpty {
                VStack(spacing: AtlasTheme.Spacing.xs) {
                    ForEach(currentEntries, id: \.id) { entry in
                        CompletedSetRow(
                            index: entry.setIndex + 1,
                            entry: entry,
                            reference: referenceProvider(entry.setIndex)
                        )
                    }
                }
            }

            // Input section
            VStack(spacing: AtlasTheme.Spacing.sm) {
                // Target strip — primary reference for this set
                if let target = weekTarget {
                    HStack(spacing: AtlasTheme.Spacing.xs) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TARGET")
                                .font(AtlasTheme.Typography.overline)
                                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                                .tracking(1.0)
                            Text("\(target.weightKg.weightString)kg × \(target.reps)")
                                .font(AtlasTheme.Typography.metric)
                                .foregroundStyle(AtlasTheme.Colors.textPrimary)
                                .monospacedDigit()
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.sm)
                    .padding(.vertical, AtlasTheme.Spacing.xs)
                    .background(AtlasTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous)
                            .stroke(AtlasTheme.Colors.accent.opacity(0.35), lineWidth: 1)
                    )
                    .accessibilityLabel("Target: \(target.weightKg.weightString)kg × \(target.reps) reps")
                }

                // Input row: WEIGHT | REPS | SET (done)
                HStack(spacing: AtlasTheme.Spacing.xs) {
                    MetricInputField(title: "WEIGHT (kg)", text: $weightText, keyboard: .decimalPad)
                    MetricInputField(title: "REPS", text: $repsText, keyboard: .numberPad)
                    // Done column
                    VStack(alignment: .center, spacing: AtlasTheme.Spacing.xxs) {
                        Text("SET")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        Button {
                            handleDone()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                                .background(canComplete ? AtlasTheme.Colors.accent : AtlasTheme.Colors.disabled)
                                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canComplete)
                        .accessibilityLabel("Log set")
                    }
                    .frame(maxWidth: 72)
                }

                // RIR stepper (secondary)
                RIRStepper(selected: $rir)

                // Warmup toggle (tertiary)
                Toggle("Warmup", isOn: $isWarmup)
                    .toggleStyle(.switch)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    .frame(minHeight: 44)
            }
        }
        .atlasCardStyle()
        .onAppear { seedFromPrefillIfNeeded() }
    }

    private func handleDone() {
        if rir == 0 {
            onRIRZero(exercise.displayName) { confirmed in
                let finalRir = confirmed ? 0 : -1
                onComplete(parsedWeight, parsedReps, finalRir, isWarmup)
                resetInputs()
            }
        } else {
            onComplete(parsedWeight, parsedReps, rir, isWarmup)
            resetInputs()
        }
    }

    private func resetInputs() {
        rir = -1
    }

    private func seedFromPrefillIfNeeded() {
        guard !seeded else { return }
        seeded = true
        guard let prefill else { return }
        weightText = prefill.weight.weightString
        repsText = "\(prefill.reps)"
        rir = prefill.rir
    }
}

// MARK: - RIR Stepper

private struct RIRStepper: View {
    @Binding var selected: Int

    private let values = [-1, 0, 1, 2, 3, 4, 5]
    private let labels = ["—", "0", "1", "2", "3", "4", "5"]

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
            Text("RIR (Reps in Reserve)")
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
            HStack(spacing: AtlasTheme.Spacing.xxs) {
                ForEach(Array(zip(values, labels)), id: \.0) { value, label in
                    Button {
                        selected = value
                    } label: {
                        Text(label)
                            .font(AtlasTheme.Typography.body.weight(selected == value ? .bold : .regular))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(capsuleBackground(for: value))
                            .foregroundStyle(capsuleForeground(for: value))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(value == -1 ? "No RIR set" : "RIR \(value)\(value == 0 ? " — failure" : "")")
                }
            }
        }
    }

    private func capsuleBackground(for value: Int) -> Color {
        if selected == value {
            return value == 0 ? Color.red : AtlasTheme.Colors.accent
        }
        return AtlasTheme.Colors.background
    }

    private func capsuleForeground(for value: Int) -> Color {
        if selected == value { return .white }
        return value == 0 ? AtlasTheme.Colors.failureAccent : AtlasTheme.Colors.textPrimary
    }
}

// MARK: - Metric Input Field

private struct MetricInputField: View {
    let title: String
    @Binding var text: String
    let keyboard: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
            Text(title)
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
            TextField("0", text: $text)
                .keyboardType(keyboard)
                .font(AtlasTheme.Typography.numericDisplay)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AtlasTheme.Spacing.xs)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(AtlasTheme.Colors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous)
                        .stroke(AtlasTheme.Colors.border, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Completed Set Row

private struct CompletedSetRow: View {
    let index: Int
    let entry: SetEntry
    let reference: SetEntry?

    private var isFailed: Bool {
        entry.targetWeight > 0 && (entry.weight < entry.targetWeight || entry.reps < entry.targetReps)
    }

    private var isProgressive: Bool {
        guard let reference else { return false }
        if entry.weight > reference.weight { return true }
        if entry.weight == reference.weight { return entry.reps > reference.reps }
        return false
    }

    var body: some View {
        HStack(spacing: AtlasTheme.Spacing.sm) {
            Text("Set \(index)")
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                .frame(width: 44, alignment: .leading)

            Text("\(entry.weight.weightString) kg")
                .font(AtlasTheme.Typography.body)
                .monospacedDigit()
            Text("× \(entry.reps)")
                .font(AtlasTheme.Typography.body)
                .monospacedDigit()

            Spacer(minLength: 0)

            if isFailed {
                Label("Missed", systemImage: "xmark.circle.fill")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.failureAccent)
                    .accessibilityLabel("Set missed target")
            } else if entry.rir >= 0 {
                Text("RIR \(entry.rir)")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }

            Image(systemName: isFailed ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isFailed ? AtlasTheme.Colors.failureAccent : AtlasTheme.Colors.accent)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, AtlasTheme.Spacing.sm)
        .frame(minHeight: 52)
        .background(isFailed ? AtlasTheme.Colors.failureAccent.opacity(0.07) : AtlasTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
        .overlay(alignment: .leading) {
            if isFailed || isProgressive {
                Rectangle()
                    .fill(isFailed ? AtlasTheme.Colors.failureAccent : AtlasTheme.Colors.progress)
                    .frame(width: 3)
                    .clipShape(.rect(
                        topLeadingRadius: AtlasTheme.Radius.md,
                        bottomLeadingRadius: AtlasTheme.Radius.md
                    ))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        let target = entry.targetWeight > 0 ? "Target: \(entry.targetWeight.weightString)kg × \(entry.targetReps). " : ""
        return "\(target)Actual: \(entry.weight.weightString)kg × \(entry.reps)."
    }
}

// MARK: - End Workout Feeling

struct EndWorkoutFeelingView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                Text("How did this workout feel?")
                    .font(AtlasTheme.Typography.sectionTitle)
                HStack(spacing: AtlasTheme.Spacing.md) {
                    ForEach(1...5, id: \.self) { value in
                        Button("\(value)") {
                            session.overallFeeling = value
                            finishSession()
                        }
                        .font(AtlasTheme.Typography.sectionTitle)
                        .frame(width: 44, height: 44)
                        .background(session.overallFeeling == value ? AtlasTheme.Colors.accent : AtlasTheme.Colors.background)
                        .foregroundStyle(session.overallFeeling == value ? .white : AtlasTheme.Colors.textPrimary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AtlasTheme.Colors.border, lineWidth: 0.5))
                    }
                }
                Button("Skip") { finishSession() }
                    .font(AtlasTheme.Typography.body)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
                    .frame(minHeight: 44)
                Spacer(minLength: 0)
            }
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func finishSession() {
        session.isCompleted = true
        try? modelContext.save()
        onDone()
        dismiss()
    }
}

// MARK: - Failure Confirmation Sheet

private struct FailureConfirmationSheet: View {
    let exerciseName: String
    let onConfirm: () -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AtlasTheme.Colors.failureAccent)
                    .accessibilityHidden(true)

                Text("You hit failure on \(exerciseName).")
                    .font(AtlasTheme.Typography.sectionTitle)
                    .multilineTextAlignment(.center)

                VStack(spacing: AtlasTheme.Spacing.xs) {
                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        Text("Log as Failure")
                            .font(AtlasTheme.Typography.sectionTitle)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AtlasTheme.Colors.failureAccent)
                            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onSkip()
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(AtlasTheme.Typography.body)
                            .foregroundStyle(AtlasTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - FailureCallbackHolder

@MainActor
@Observable
final class FailureCallbackHolder {
    var completion: ((Bool) -> Void)?
}

// MARK: - SetPrefill

struct SetPrefill {
    let weight: Double
    let reps: Int
    let rir: Int
}

// MARK: - ActiveWorkoutViewModel

@MainActor
@Observable
final class ActiveWorkoutViewModel {

    func prefillSet(
        for exerciseID: UUID,
        currentSession: WorkoutSession,
        sessions: [WorkoutSession],
        rule: ProgressionRule?,
        cycle: Cycle?
    ) -> SetPrefill? {
        let current = currentSession.setEntries
            .filter { $0.exerciseId == exerciseID }
            .sorted { $0.setIndex < $1.setIndex }

        if let currentLast = current.last {
            return SetPrefill(weight: currentLast.weight, reps: currentLast.reps, rir: currentLast.rir)
        }

        if let rule, let cycle, currentSession.weekNumber > 0 {
            if let target = ProgressionEngine.target(for: currentSession.weekNumber, rule: rule.snapshot(weekCount: cycle.weekCount), outcomes: []) {
                return SetPrefill(weight: target.weightKg, reps: target.reps, rir: -1)
            }
        }

        guard let reference = latestSessionSet(for: exerciseID, currentSession: currentSession, sessions: sessions) else {
            return nil
        }
        return SetPrefill(weight: reference.weight, reps: reference.reps, rir: reference.rir)
    }

    func referenceSet(
        for exerciseID: UUID,
        setIndex: Int,
        currentSession: WorkoutSession,
        sessions: [WorkoutSession]
    ) -> SetEntry? {
        guard let lastSession = latestSession(for: exerciseID, currentSession: currentSession, sessions: sessions) else {
            return nil
        }
        let sets = lastSession.setEntries
            .filter { $0.exerciseId == exerciseID && $0.isCompleted }
            .sorted { $0.setIndex < $1.setIndex }
        guard !sets.isEmpty else { return nil }
        return setIndex < sets.count ? sets[setIndex] : sets.last
    }

    private func latestSessionSet(for exerciseID: UUID, currentSession: WorkoutSession, sessions: [WorkoutSession]) -> SetEntry? {
        guard let session = latestSession(for: exerciseID, currentSession: currentSession, sessions: sessions) else { return nil }
        return session.setEntries
            .filter { $0.exerciseId == exerciseID && $0.isCompleted }
            .sorted { $0.setIndex < $1.setIndex }
            .first
    }

    private func latestSession(for exerciseID: UUID, currentSession: WorkoutSession, sessions: [WorkoutSession]) -> WorkoutSession? {
        sessions.first { session in
            session.id != currentSession.id
                && session.isCompleted
                && session.setEntries.contains(where: { $0.exerciseId == exerciseID && $0.isCompleted })
        }
    }
}

// MARK: - RestTimerManager

@MainActor
@Observable
final class RestTimerManager {
    var secondsRemaining: Int = 0
    var isRunning: Bool = false
    private(set) var totalDuration: Int = 0

    private var task: Task<Void, Never>?
    private var activity: Activity<RestTimerAttributes>?

    var label: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start(totalSeconds: Int) {
        stop()
        totalDuration = totalSeconds
        secondsRemaining = totalSeconds
        isRunning = true

        let endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        let attributes = RestTimerAttributes()
        let state = RestTimerAttributes.ContentState(endDate: endDate)
        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(60))
        activity = try? Activity<RestTimerAttributes>.request(attributes: attributes, content: content, pushType: nil)

        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let manager = self else { return }
                guard manager.secondsRemaining > 0 else {
                    manager.completeIfFinished()
                    return
                }

                try? await Task.sleep(for: .seconds(1))

                if Task.isCancelled { return }

                guard let manager = self else { return }
                manager.secondsRemaining -= 1
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
        secondsRemaining = 0
        totalDuration = 0
        endCurrentActivity(dismissalPolicy: .immediate)
    }

    private func completeIfFinished() {
        if secondsRemaining <= 0 {
            secondsRemaining = 0
            isRunning = false
            task = nil
            endCurrentActivity(dismissalPolicy: .after(.now))
        }
    }

    private func endCurrentActivity(dismissalPolicy: ActivityUIDismissalPolicy) {
        guard let activity else { return }
        Task { await activity.end(nil, dismissalPolicy: dismissalPolicy) }
        self.activity = nil
    }
}

#Preview {
    NavigationStack {
        let container = PreviewSampleData.makePreviewContainer()
        let session = (try? container.mainContext.fetch(FetchDescriptor<WorkoutSession>()))?.first
        return Group {
            if let session {
                ActiveWorkoutView(session: session).modelContainer(container)
            }
        }
    }
    .preferredColorScheme(.dark)
}
