//
//  ActiveWorkoutView.swift
//  Unit
//
//  Active workout: target column, RIR stepper, failure detection, deload badge, rest timer.
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

    @StateObject private var viewModel = ActiveWorkoutViewModel()
    @StateObject private var restTimer = RestTimerManager()

    @State private var showingEndWorkoutFeeling = false
    @State private var toastMessage: String?
    @State private var showFailureModal = false
    @State private var pendingFailureExerciseName = ""
    @State private var pendingFailureCompletion: ((Bool) -> Void)?

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

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    headerCard

                    ForEach(orderedExercises, id: \.id) { exercise in
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
                                pendingFailureCompletion = completion
                                showFailureModal = true
                            }
                        )
                    }

                    RestTimerPanel(manager: restTimer)

                    Button {
                        showingEndWorkoutFeeling = true
                    } label: {
                        HStack {
                            Text("End Workout")
                                .font(Theme.Typography.title)
                            Spacer(minLength: 0)
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
                .padding(Theme.Spacing.md)
                .padding(.bottom, toastMessage != nil ? 80 : 0)
            }
            .background(Theme.Colors.background)

            // Toast overlay
            if let msg = toastMessage {
                toastView(msg)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .navigationTitle(template?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: toastMessage)
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
                    pendingFailureCompletion?(true)
                    pendingFailureCompletion = nil
                },
                onSkip: {
                    pendingFailureCompletion?(false)
                    pendingFailureCompletion = nil
                }
            )
            .presentationDetents([.height(280)])
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(template?.name ?? "Workout")
                    .font(Theme.Typography.hero)
                Spacer(minLength: 0)
                if session.weekNumber > 0 {
                    Text("Week \(session.weekNumber)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, Theme.Spacing.xxs)
                        .background(Theme.Colors.accentSoft)
                        .clipShape(Capsule())
                }
            }
            Text("Dumbbell logging uses total weight by default.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .cardStyle()
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

        // Compute target snapshot for this set
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
        // Show toast if any future weeks were recalibrated (i.e. any set failed target)
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
            .font(Theme.Typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color.black.opacity(0.85))
            .clipShape(Capsule())
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.lg)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Exercise header + deload badge
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.displayName)
                    .font(Theme.Typography.title)
                Spacer(minLength: 0)
                if progressionRule?.isDeloaded == true {
                    Label("Deload", systemImage: "arrow.down.circle.fill")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.deload)
                        .accessibilityLabel("Deload week")
                }
            }

            // Last vs. Planned context lines
            if let last = lastActual, let target = weekTarget {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last: \(last.weight.weightString)kg × \(last.reps)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .monospacedDigit()
                    Text("Planned: \(target.weightKg.weightString)kg × \(target.reps)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.ghostText)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Last: \(last.weight.weightString)kg × \(last.reps). Planned: \(target.weightKg.weightString)kg × \(target.reps)")
            } else if let target = weekTarget {
                Text("First session · Planned: \(target.weightKg.weightString)kg × \(target.reps)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .monospacedDigit()
            }

            // Completed set rows
            if !currentEntries.isEmpty {
                VStack(spacing: Theme.Spacing.xs) {
                    ForEach(currentEntries, id: \.id) { entry in
                        CompletedSetRow(
                            index: entry.setIndex + 1,
                            entry: entry,
                            reference: referenceProvider(entry.setIndex)
                        )
                    }
                }
            }

            // 3-column input: TARGET | WEIGHT | REPS
            VStack(spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.xs) {
                    if let target = weekTarget {
                        TargetColumn(weightKg: target.weightKg, reps: target.reps)
                    }
                    MetricInputField(title: "WEIGHT (kg)", text: $weightText, keyboard: .decimalPad)
                    MetricInputField(title: "REPS", text: $repsText, keyboard: .numberPad)
                }

                // RIR stepper (0–5 capsule buttons)
                RIRStepper(selected: $rir)

                // Warmup toggle + Done button
                HStack(spacing: Theme.Spacing.xs) {
                    Toggle("Warmup", isOn: $isWarmup)
                        .toggleStyle(.switch)
                        .frame(minHeight: 44)

                    Spacer(minLength: 0)

                    Button {
                        handleDone()
                    } label: {
                        Text("Done")
                            .font(Theme.Typography.title)
                            .foregroundStyle(.white)
                            .frame(minWidth: 80, minHeight: 44)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .background(canComplete ? Theme.Colors.accent : Color.gray.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canComplete)
                }
            }
        }
        .cardStyle()
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
        // Keep weight/reps prefilled for next set
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

// MARK: - Target Column (ghost, read-only)

private struct TargetColumn: View {
    let weightKg: Double
    let reps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("TARGET")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.ghostText)
            VStack(alignment: .leading, spacing: 2) {
                Text(weightKg.weightString + "kg")
                    .font(Theme.Typography.metric)
                    .foregroundStyle(Theme.Colors.ghostText)
                    .monospacedDigit()
                Text("× \(reps)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.ghostText)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(Theme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .accessibilityLabel("Target: \(weightKg.weightString)kg × \(reps) reps")
    }
}

// MARK: - RIR Stepper

private struct RIRStepper: View {
    @Binding var selected: Int

    private let values = [-1, 0, 1, 2, 3, 4, 5]
    private let labels = ["—", "0", "1", "2", "3", "4", "5"]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("RIR (Reps in Reserve)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            HStack(spacing: Theme.Spacing.xxs) {
                ForEach(Array(zip(values, labels)), id: \.0) { value, label in
                    Button {
                        selected = value
                    } label: {
                        Text(label)
                            .font(Theme.Typography.body.weight(selected == value ? .bold : .regular))
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
            return value == 0 ? Color.red : Theme.Colors.accent
        }
        return Theme.Colors.background
    }

    private func capsuleForeground(for value: Int) -> Color {
        if selected == value { return .white }
        return value == 0 ? Theme.Colors.failure : Theme.Colors.textPrimary
    }
}

// MARK: - Metric Input Field

private struct MetricInputField: View {
    let title: String
    @Binding var text: String
    let keyboard: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            TextField("0", text: $text)
                .keyboardType(keyboard)
                .font(Theme.Typography.metric)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.Colors.background)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(Theme.Colors.border, lineWidth: 0.5)
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
        HStack(spacing: Theme.Spacing.sm) {
            Text("Set \(index)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 44, alignment: .leading)

            Text("\(entry.weight.weightString) kg")
                .font(Theme.Typography.body)
                .monospacedDigit()
            Text("× \(entry.reps)")
                .font(Theme.Typography.body)
                .monospacedDigit()

            Spacer(minLength: 0)

            if isFailed {
                // HIG: never color alone — add icon + label
                Label("Missed", systemImage: "xmark.circle.fill")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.failure)
                    .accessibilityLabel("Set missed target")
            } else if entry.rir >= 0 {
                Text("RIR \(entry.rir)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Image(systemName: isFailed ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isFailed ? Theme.Colors.failure : Theme.Colors.accent)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .frame(minHeight: 52)
        .background(isFailed ? Theme.Colors.failure.opacity(0.08) : Theme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            Group {
                if isFailed || isProgressive {
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(
                            isFailed ? Theme.Colors.failure.opacity(0.5) : Theme.Colors.progress,
                            lineWidth: 1.5
                        )
                }
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        let target = entry.targetWeight > 0 ? "Target: \(entry.targetWeight.weightString)kg × \(entry.targetReps). " : ""
        return "\(target)Actual: \(entry.weight.weightString)kg × \(entry.reps)."
    }
}

// MARK: - Rest Timer Panel

private struct RestTimerPanel: View {
    @ObservedObject var manager: RestTimerManager

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Rest Timer")
                .font(Theme.Typography.title)
            HStack {
                Text(manager.label)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Spacer(minLength: 0)
                if manager.isRunning {
                    Button("Stop") { manager.stop() }
                        .font(Theme.Typography.body)
                        .foregroundStyle(.red)
                        .frame(minWidth: 64, minHeight: 44)
                } else {
                    HStack(spacing: Theme.Spacing.xs) {
                        Button("1:30") { manager.start(totalSeconds: 90) }
                        Button("2:00") { manager.start(totalSeconds: 120) }
                    }
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
        .cardStyle()
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
            VStack(spacing: Theme.Spacing.lg) {
                Text("How did this workout feel?")
                    .font(Theme.Typography.title)
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(1...5, id: \.self) { value in
                        Button("\(value)") {
                            session.overallFeeling = value
                            finishSession()
                        }
                        .font(Theme.Typography.title)
                        .frame(width: 44, height: 44)
                        .background(session.overallFeeling == value ? Theme.Colors.accent : Theme.Colors.background)
                        .foregroundStyle(session.overallFeeling == value ? .white : Theme.Colors.textPrimary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.Colors.border, lineWidth: 0.5))
                    }
                }
                Button("Skip") { finishSession() }
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(minHeight: 44)
                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.background.ignoresSafeArea())
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
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.failure)
                    .accessibilityHidden(true)

                Text("You hit failure on \(exerciseName).")
                    .font(Theme.Typography.title)
                    .multilineTextAlignment(.center)

                VStack(spacing: Theme.Spacing.xs) {
                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        Text("Log as Failure")
                            .font(Theme.Typography.title)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.Colors.failure)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onSkip()
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - SetPrefill

struct SetPrefill {
    let weight: Double
    let reps: Int
    let rir: Int
}

// MARK: - ActiveWorkoutViewModel

@MainActor
final class ActiveWorkoutViewModel: ObservableObject {

    func prefillSet(
        for exerciseID: UUID,
        currentSession: WorkoutSession,
        sessions: [WorkoutSession],
        rule: ProgressionRule?,
        cycle: Cycle?
    ) -> SetPrefill? {
        // First: use the current session's last completed set for this exercise
        let current = currentSession.setEntries
            .filter { $0.exerciseId == exerciseID }
            .sorted { $0.setIndex < $1.setIndex }

        if let currentLast = current.last {
            return SetPrefill(weight: currentLast.weight, reps: currentLast.reps, rir: currentLast.rir)
        }

        // If a progression rule exists, use the engine target as prefill weight
        if let rule, let cycle, currentSession.weekNumber > 0 {
            if let target = ProgressionEngine.target(for: currentSession.weekNumber, rule: rule.snapshot(weekCount: cycle.weekCount), outcomes: []) {
                return SetPrefill(weight: target.weightKg, reps: target.reps, rir: -1)
            }
        }

        // Fallback: last historical set
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
final class RestTimerManager: ObservableObject {
    @Published var secondsRemaining: Int = 0
    @Published var isRunning: Bool = false

    private var task: Task<Void, Never>?
    private var activity: Activity<RestTimerAttributes>?

    var label: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start(totalSeconds: Int) {
        stop()
        secondsRemaining = totalSeconds
        isRunning = true

        let endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        let attributes = RestTimerAttributes()
        let state = RestTimerAttributes.ContentState(endDate: endDate)
        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(60))
        activity = try? Activity<RestTimerAttributes>.request(attributes: attributes, content: content, pushType: nil)

        task = Task { [weak self] in
            guard let self else { return }
            while self.secondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                self.secondsRemaining -= 1
            }
            self.completeIfFinished()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
        secondsRemaining = 0
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

    deinit { task?.cancel() }
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
