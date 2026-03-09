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
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
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
                                .font(AtlasTheme.Typography.sectionTitle)
                            Spacer(minLength: 0)
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .foregroundStyle(AtlasTheme.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .atlasCardStyle()
                    }
                    .buttonStyle(.plain)
                }
                .padding(AtlasTheme.Spacing.md)
                .padding(.bottom, toastMessage != nil ? 80 : 0)
            }
            .background(AtlasTheme.Colors.background)

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
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
            HStack {
                Text(template?.name ?? "Workout")
                    .font(AtlasTheme.Typography.hero)
                Spacer(minLength: 0)
                if session.weekNumber > 0 {
                    Text("Week \(session.weekNumber)")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .padding(.horizontal, AtlasTheme.Spacing.xs)
                        .padding(.vertical, AtlasTheme.Spacing.xxs)
                        .background(AtlasTheme.Colors.accentSoft)
                        .clipShape(Capsule())
                }
            }
            Text("Dumbbell logging uses total weight by default.")
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
        }
        .atlasCardStyle()
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
            .font(AtlasTheme.Typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.vertical, AtlasTheme.Spacing.sm)
            .background(Color.black.opacity(0.85))
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
                    .font(AtlasTheme.Typography.sectionTitle)
                Spacer(minLength: 0)
                if progressionRule?.isDeloaded == true {
                    Label("Deload", systemImage: "arrow.down.circle.fill")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.deloadBadge)
                        .accessibilityLabel("Deload week")
                }
            }

            // Last vs. Planned context lines
            if let last = lastActual, let target = weekTarget {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last: \(last.weight.weightString)kg × \(last.reps)")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.textSecondary)
                        .monospacedDigit()
                    Text("Planned: \(target.weightKg.weightString)kg × \(target.reps)")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundStyle(AtlasTheme.Colors.ghostText)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Last: \(last.weight.weightString)kg × \(last.reps). Planned: \(target.weightKg.weightString)kg × \(target.reps)")
            } else if let target = weekTarget {
                Text("First session · Planned: \(target.weightKg.weightString)kg × \(target.reps)")
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

            // 3-column input: TARGET | WEIGHT | REPS
            VStack(spacing: AtlasTheme.Spacing.sm) {
                HStack(spacing: AtlasTheme.Spacing.xs) {
                    if let target = weekTarget {
                        TargetColumn(weightKg: target.weightKg, reps: target.reps)
                    }
                    MetricInputField(title: "WEIGHT (kg)", text: $weightText, keyboard: .decimalPad)
                    MetricInputField(title: "REPS", text: $repsText, keyboard: .numberPad)
                }

                // RIR stepper (0–5 capsule buttons)
                RIRStepper(selected: $rir)

                // Warmup toggle + Done button
                HStack(spacing: AtlasTheme.Spacing.xs) {
                    Toggle("Warmup", isOn: $isWarmup)
                        .toggleStyle(.switch)
                        .frame(minHeight: 44)

                    Spacer(minLength: 0)

                    Button {
                        handleDone()
                    } label: {
                        Text("Done")
                            .font(AtlasTheme.Typography.sectionTitle)
                            .foregroundStyle(.white)
                            .frame(minWidth: 80, minHeight: 44)
                            .padding(.horizontal, AtlasTheme.Spacing.sm)
                            .background(canComplete ? AtlasTheme.Colors.accent : Color.gray.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canComplete)
                }
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
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xxs) {
            Text("TARGET")
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.ghostText)
            VStack(alignment: .leading, spacing: 2) {
                Text(weightKg.weightString + "kg")
                    .font(AtlasTheme.Typography.metric)
                    .foregroundStyle(AtlasTheme.Colors.ghostText)
                    .monospacedDigit()
                Text("× \(reps)")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.ghostText)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .padding(.horizontal, AtlasTheme.Spacing.sm)
        .background(AtlasTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
        .accessibilityLabel("Target: \(weightKg.weightString)kg × \(reps) reps")
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
                .font(AtlasTheme.Typography.metric)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AtlasTheme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
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
                // HIG: never color alone — add icon + label
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
        .background(isFailed ? AtlasTheme.Colors.failureAccent.opacity(0.08) : AtlasTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
        .overlay(
            Group {
                if isFailed || isProgressive {
                    RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous)
                        .stroke(
                            isFailed ? AtlasTheme.Colors.failureAccent.opacity(0.5) : AtlasTheme.Colors.progress,
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
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            Text("Rest Timer")
                .font(AtlasTheme.Typography.sectionTitle)
            HStack {
                Text(manager.label)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Spacer(minLength: 0)
                if manager.isRunning {
                    Button("Stop") { manager.stop() }
                        .font(AtlasTheme.Typography.body)
                        .foregroundStyle(.red)
                        .frame(minWidth: 64, minHeight: 44)
                } else {
                    HStack(spacing: AtlasTheme.Spacing.xs) {
                        Button("1:30") { manager.start(totalSeconds: 90) }
                        Button("2:00") { manager.start(totalSeconds: 120) }
                    }
                    .font(AtlasTheme.Typography.body)
                    .foregroundStyle(AtlasTheme.Colors.accent)
                }
            }
        }
        .atlasCardStyle()
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
}
