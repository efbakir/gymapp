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
    @State private var showingRestTimerControls = false
    @State private var toastMessage: String?
    @State private var selectedRestSeconds: Int = 90

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
                // Session + rest timer access
                sessionHeaderStrip

                // Current exercise — scrollable
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
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
                                onComplete: { weight, reps, note in
                                    completeSet(exercise: exercise, rule: rule, weight: weight, reps: reps, note: note)
                                }
                            )
                        }
                    }
                    .padding(AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }
                .background(AppColor.background)

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
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.cardBackground)
        }
        .sheet(isPresented: $showingRestTimerControls) {
            restTimerControlsSheet
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.cardBackground)
        }
        .onDisappear {
            restTimer.stop()
        }
    }

    // MARK: - Session Header

    private var sessionHeaderStrip: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(template?.name ?? "Workout")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                Text("Exercise \(min(currentExerciseIndex + 1, max(orderedExercises.count, 1))) of \(max(orderedExercises.count, 1))")
                    .font(AppFont.body.font.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()
            Button {
                showingRestTimerControls = true
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    AppIcon.timer.image(size: 12, weight: .semibold)
                    Text(restTimer.isRunning ? restTimer.label : formatRestDuration(selectedRestSeconds))
                        .font(AppFont.numericTimer)
                }
                .foregroundStyle(restTimer.isRunning ? AppColor.accent : AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.sm)
                .frame(height: 34)
                .background(AppColor.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(restTimer.isRunning ? AppColor.accent : AppColor.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.surface)
    }

    private var restTimerControlsSheet: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Text(restTimer.isRunning ? restTimer.label : formatRestDuration(selectedRestSeconds))
                    .font(AppFont.numericDisplay)
                    .foregroundStyle(restTimer.isRunning ? AppColor.accent : AppColor.textPrimary)
                    .monospacedDigit()

                HStack(spacing: AppSpacing.md) {
                    Button {
                        selectedRestSeconds = max(30, selectedRestSeconds - 30)
                    } label: {
                        AppIcon.remove.image(size: 14, weight: .semibold)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(AppColor.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedRestSeconds = min(300, selectedRestSeconds + 30)
                    } label: {
                        AppIcon.add.image(size: 14, weight: .semibold)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(AppColor.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                AppPrimaryButton(restTimer.isRunning ? "Stop Timer" : "Start Timer") {
                    if restTimer.isRunning {
                        restTimer.stop()
                    } else {
                        restTimer.start(totalSeconds: selectedRestSeconds)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Rest Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        showingRestTimerControls = false
                    }
                }
            }
        }
    }

    private func formatRestDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                showLineup = true
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    AppIcon.list.image(size: 14, weight: .regular)
                    Text("See lineup")
                        .font(AppFont.body.font)
                }
                .foregroundStyle(AppColor.textSecondary)
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
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Move to next exercise: \(orderedExercises[currentExerciseIndex + 1].displayName)")
            } else {
                Button {
                    finishWorkout()
                } label: {
                    Text("End Workout")
                        .font(AppFont.sectionHeader.font)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .frame(height: 44)
                        .background(AppColor.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.surface)
    }

    // MARK: - Lineup Sheet

    private var lineupSheet: some View {
        NavigationStack {
            List {
                ForEach(Array(orderedExercises.enumerated()), id: \.element.id) { index, exercise in
                    HStack {
                        Text(exercise.displayName)
                            .font(AppFont.body.font)
                            .foregroundStyle(index <= currentExerciseIndex ? AppColor.textPrimary : AppColor.textSecondary)
                        Spacer()
                        if index < currentExerciseIndex {
                            AppIcon.checkmarkFilled.image()
                                .foregroundStyle(AppColor.success)
                                .accessibilityHidden(true)
                        } else if index == currentExerciseIndex {
                            Text("Now")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColor.accentSoft)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(minHeight: 44)
                    .accessibilityLabel(index < currentExerciseIndex ? "\(exercise.displayName), done" : index == currentExerciseIndex ? "\(exercise.displayName), current" : exercise.displayName)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Today's Lineup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showLineup = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColor.cardBackground)
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
        note: String = ""
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
            rir: -1,
            targetWeight: targetWeight,
            targetReps: targetReps,
            metTarget: metTarget,
            isWarmup: false,
            isCompleted: true,
            setIndex: setIndex,
            note: note
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

    private func finishWorkout() {
        session.isCompleted = true
        try? modelContext.save()
        if session.overallFeeling == 0 {
            UserDefaults.standard.set(session.id.uuidString, forKey: "pendingFeelingSessionId")
        }
        checkAndShowRecalibrationToast()
        showToast("Workout saved.")
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
            .font(AppFont.caption.font)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.black.opacity(0.85))
            .clipShape(Capsule())
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
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
    let onComplete: (_ weight: Double, _ reps: Int, _ note: String) -> Void

    @State private var showingManualInput = false

    private var weekTarget: ProgressionEngine.WeekTarget? {
        guard let rule = progressionRule, let cycle = activeCycle, weekNumber > 0 else { return nil }
        return ProgressionEngine.target(for: weekNumber, rule: rule.snapshot(weekCount: cycle.weekCount), outcomes: [])
    }

    private var manualPrefill: SetPrefill? {
        if let prefill {
            return prefill
        }
        guard let target = weekTarget else { return nil }
        return SetPrefill(weight: target.weightKg, reps: target.reps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Exercise header + deload badge
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.displayName)
                    .font(AppFont.largeTitle.font)
                Spacer(minLength: 0)
                if weekNumber > 0 {
                    Text("Week \(weekNumber)")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColor.accentSoft)
                        .clipShape(Capsule())
                }
                if progressionRule?.isDeloaded == true {
                    Label { Text("Deload") } icon: { AppIcon.deload.image() }
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.warning)
                        .accessibilityLabel("Deload week")
                }
            }

            // Last vs. context lines
            if let last = lastActual {
                Text("Last: \(last.weight.weightString)kg × \(last.reps)")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .monospacedDigit()
            }

            // Completed set rows
            if !currentEntries.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(currentEntries, id: \.id) { entry in
                        CompletedSetRow(
                            index: entry.setIndex + 1,
                            entry: entry,
                            reference: referenceProvider(entry.setIndex)
                        )
                    }
                }
            }

            // Logging controls
            VStack(spacing: AppSpacing.sm) {
                if let target = weekTarget {
                    AppPrimaryButton("Log \(target.weightKg.weightString)kg × \(target.reps)") {
                        onComplete(target.weightKg, target.reps, "")
                    }
                    .accessibilityLabel("Log set at target: \(target.weightKg.weightString)kg × \(target.reps) reps")

                    Button {
                        showingManualInput = true
                    } label: {
                        Text("Different weight")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 36)
                    }
                    .buttonStyle(.plain)
                } else {
                    AppPrimaryButton("Log Set") {
                        showingManualInput = true
                    }
                }
            }
        }
        .appCardStyle()
        .sheet(isPresented: $showingManualInput) {
            ManualSetInputSheet(prefill: manualPrefill) { weight, reps, note in
                onComplete(weight, reps, note)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.cardBackground)
        }
    }
}

// MARK: - Manual Set Input

private struct ManualSetInputSheet: View {
    let prefill: SetPrefill?
    let onSave: (_ weight: Double, _ reps: Int, _ note: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weightText = ""
    @State private var repsText = ""
    @State private var noteText = ""
    @State private var seeded = false

    private var parsedWeight: Double {
        Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var parsedReps: Int {
        Int(repsText) ?? 0
    }

    private var canSave: Bool {
        parsedWeight > 0 && parsedReps > 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.md) {
                manualInputField(title: "WEIGHT (kg)", text: $weightText, keyboardType: .decimalPad)
                manualInputField(title: "REPS", text: $repsText, keyboardType: .numberPad)

                TextField("Optional note", text: $noteText)
                    .font(AppFont.body.font)
                    .padding(.horizontal, AppSpacing.md)
                    .frame(height: 48)
                    .background(AppColor.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 0.5)
                    )

                Button {
                    onSave(parsedWeight, parsedReps, noteText)
                    dismiss()
                } label: {
                    Text("Log Set")
                        .font(AppFont.label.font)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.6)

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Different Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { dismiss() }
                }
            }
            .onAppear {
                guard !seeded else { return }
                seeded = true
                guard let prefill else { return }
                weightText = prefill.weight.weightString
                repsText = "\(prefill.reps)"
            }
        }
    }

    @ViewBuilder
    private func manualInputField(title: String, text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
            TextField("0", text: text)
                .keyboardType(keyboardType)
                .font(AppFont.numericDisplay)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.sm)
                .frame(height: 64)
                .background(AppColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(AppColor.border, lineWidth: 0.5)
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
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: AppSpacing.sm) {
                Text("Set \(index)")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 44, alignment: .leading)

                Text("\(entry.weight.weightString) kg")
                    .font(AppFont.body.font)
                    .monospacedDigit()
                Text("× \(entry.reps)")
                    .font(AppFont.body.font)
                    .monospacedDigit()

                Spacer(minLength: 0)

                (isFailed ? AppIcon.xmarkFilled : AppIcon.checkmarkFilled).image()
                    .foregroundStyle(isFailed ? AppColor.error : AppColor.success)
                    .accessibilityHidden(true)
            }
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.leading, 52)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .frame(minHeight: 44)
        .background(isFailed ? AppColor.error.opacity(0.07) : AppColor.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(alignment: .leading) {
            if isFailed || isProgressive {
                Rectangle()
                    .fill(isFailed ? AppColor.error : AppColor.success)
                    .frame(width: 3)
                    .clipShape(.rect(
                        topLeadingRadius: AppRadius.md,
                        bottomLeadingRadius: AppRadius.md
                    ))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        let target = entry.targetWeight > 0 ? "Target: \(entry.targetWeight.weightString)kg × \(entry.targetReps). " : ""
        let noteStr = entry.note.isEmpty ? "" : " Note: \(entry.note)."
        return "\(target)Actual: \(entry.weight.weightString)kg × \(entry.reps).\(noteStr)"
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
            VStack(spacing: AppSpacing.lg) {
                Text("How did this workout feel?")
                    .font(AppFont.sectionHeader.font)
                HStack(spacing: AppSpacing.md) {
                    ForEach(1...5, id: \.self) { value in
                        Button("\(value)") {
                            session.overallFeeling = value
                            finishSession()
                        }
                        .font(AppFont.sectionHeader.font)
                        .frame(width: 44, height: 44)
                        .background(session.overallFeeling == value ? AppColor.accent : AppColor.background)
                        .foregroundStyle(session.overallFeeling == value ? .white : AppColor.textPrimary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppColor.border, lineWidth: 0.5))
                    }
                }
                Button("Skip") { finishSession() }
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(minHeight: 44)
                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
            .background(AppColor.background.ignoresSafeArea())
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

// MARK: - SetPrefill

struct SetPrefill {
    let weight: Double
    let reps: Int
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
            return SetPrefill(weight: currentLast.weight, reps: currentLast.reps)
        }

        if let rule, let cycle, currentSession.weekNumber > 0 {
            if let target = ProgressionEngine.target(for: currentSession.weekNumber, rule: rule.snapshot(weekCount: cycle.weekCount), outcomes: []) {
                return SetPrefill(weight: target.weightKg, reps: target.reps)
            }
        }

        guard let reference = latestSessionSet(for: exerciseID, currentSession: currentSession, sessions: sessions) else {
            return nil
        }
        return SetPrefill(weight: reference.weight, reps: reference.reps)
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
}
