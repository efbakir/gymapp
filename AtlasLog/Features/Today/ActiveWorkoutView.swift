//
//  ActiveWorkoutView.swift
//  AtlasLog
//
//  Active workout: large set rows, smart prefill, one-tap complete, overload signal, and rest timer.
//

import ActivityKit
import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]

    @StateObject private var viewModel = ActiveWorkoutViewModel()
    @StateObject private var restTimer = RestTimerManager()
    @State private var showingEndWorkoutFeeling = false

    private var template: DayTemplate? {
        templates.first(where: { $0.id == session.templateId })
    }

    private var orderedExercises: [Exercise] {
        guard let template else { return [] }
        return template.orderedExerciseIds.compactMap { id in
            exercises.first(where: { $0.id == id })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                headerCard

                ForEach(orderedExercises, id: \.id) { exercise in
                    ExerciseLoggingCard(
                        exercise: exercise,
                        currentEntries: currentEntries(for: exercise.id),
                        prefill: viewModel.prefillSet(
                            for: exercise.id,
                            currentSession: session,
                            sessions: sessions
                        ),
                        referenceProvider: { setIndex in
                            viewModel.referenceSet(
                                for: exercise.id,
                                setIndex: setIndex,
                                currentSession: session,
                                sessions: sessions
                            )
                        },
                        onComplete: { weight, reps, rpe, isWarmup in
                            completeSet(
                                exercise: exercise,
                                weight: weight,
                                reps: reps,
                                rpe: rpe,
                                isWarmup: isWarmup
                            )
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
        }
        .background(AtlasTheme.Colors.background)
        .navigationTitle(template?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEndWorkoutFeeling) {
            EndWorkoutFeelingView(session: session) {
                showingEndWorkoutFeeling = false
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
            Text(template?.name ?? "Workout")
                .font(AtlasTheme.Typography.hero)
            Text("Dumbbell logging uses total weight by default.")
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
        }
        .atlasCardStyle()
    }

    private func currentEntries(for exerciseID: UUID) -> [SetEntry] {
        session.setEntries
            .filter { $0.exerciseId == exerciseID }
            .sorted { $0.setIndex < $1.setIndex }
    }

    private func completeSet(exercise: Exercise, weight: Double, reps: Int, rpe: Double, isWarmup: Bool) {
        let setIndex = currentEntries(for: exercise.id).count
        let entry = SetEntry(
            sessionId: session.id,
            exerciseId: exercise.id,
            weight: weight,
            reps: reps,
            rpe: rpe,
            isWarmup: isWarmup,
            isCompleted: true,
            setIndex: setIndex
        )
        entry.session = session
        modelContext.insert(entry)

        // Resilience requirement: persist on every completed set.
        try? modelContext.save()

        restTimer.start(totalSeconds: 90)
    }
}

private struct ExerciseLoggingCard: View {
    let exercise: Exercise
    let currentEntries: [SetEntry]
    let prefill: SetPrefill?
    let referenceProvider: (Int) -> SetEntry?
    let onComplete: (_ weight: Double, _ reps: Int, _ rpe: Double, _ isWarmup: Bool) -> Void

    @State private var weightText = ""
    @State private var repsText = ""
    @State private var rpe: Double = 0
    @State private var isWarmup = false
    @State private var seeded = false

    private var parsedWeight: Double {
        Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var parsedReps: Int {
        Int(repsText) ?? 0
    }

    private var canComplete: Bool {
        parsedWeight > 0 || parsedReps > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            Text(exercise.displayName)
                .font(AtlasTheme.Typography.sectionTitle)

            VStack(spacing: AtlasTheme.Spacing.xs) {
                ForEach(currentEntries, id: \.id) { entry in
                    CompletedSetRow(
                        index: entry.setIndex + 1,
                        entry: entry,
                        reference: referenceProvider(entry.setIndex)
                    )
                }
            }

            VStack(spacing: AtlasTheme.Spacing.sm) {
                HStack(spacing: AtlasTheme.Spacing.xs) {
                    MetricInputField(title: "Weight (kg)", text: $weightText, keyboard: .decimalPad)
                    MetricInputField(title: "Reps", text: $repsText, keyboard: .numberPad)
                }

                HStack(spacing: AtlasTheme.Spacing.xs) {
                    Menu {
                        Button("Clear RPE") { rpe = 0 }
                        ForEach(1...10, id: \.self) { value in
                            Button("\(value)") { rpe = Double(value) }
                        }
                    } label: {
                        HStack {
                            Text(rpe > 0 ? "RPE \(Int(rpe))" : "RPE Optional")
                                .font(AtlasTheme.Typography.body)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, AtlasTheme.Spacing.sm)
                        .frame(height: 44)
                        .background(AtlasTheme.Colors.background)
                        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous)
                                .stroke(AtlasTheme.Colors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Toggle("Warmup", isOn: $isWarmup)
                        .toggleStyle(.switch)
                        .frame(minHeight: 44)
                }

                Button {
                    onComplete(parsedWeight, parsedReps, rpe, isWarmup)
                } label: {
                    Text("Done")
                        .font(AtlasTheme.Typography.sectionTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canComplete ? AtlasTheme.Colors.accent : Color.gray.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canComplete)
            }
        }
        .atlasCardStyle()
        .onAppear {
            seedFromPrefillIfNeeded()
        }
    }

    private func seedFromPrefillIfNeeded() {
        guard !seeded else { return }
        seeded = true

        guard let prefill else { return }
        weightText = formatWeight(prefill.weight)
        repsText = "\(prefill.reps)"
        rpe = prefill.rpe
    }

    private func formatWeight(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

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
                        .stroke(AtlasTheme.Colors.border, lineWidth: 1)
                )
        }
    }
}

private struct CompletedSetRow: View {
    let index: Int
    let entry: SetEntry
    let reference: SetEntry?

    private var isProgressive: Bool {
        guard let reference else { return false }
        if entry.weight > reference.weight {
            return true
        }
        if entry.weight == reference.weight {
            return entry.reps > reference.reps
        }
        return false
    }

    var body: some View {
        HStack(spacing: AtlasTheme.Spacing.sm) {
            Text("Set \(index)")
                .font(AtlasTheme.Typography.caption)
                .foregroundStyle(AtlasTheme.Colors.textSecondary)
                .frame(width: 50, alignment: .leading)
            Text("\(formatWeight(entry.weight)) kg")
                .font(AtlasTheme.Typography.body)
                .monospacedDigit()
            Text("× \(entry.reps)")
                .font(AtlasTheme.Typography.body)
                .monospacedDigit()
            Spacer(minLength: 0)
            if entry.rpe > 0 {
                Text("RPE \(formatWeight(entry.rpe))")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundStyle(AtlasTheme.Colors.textSecondary)
            }
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AtlasTheme.Colors.accent)
        }
        .padding(.horizontal, AtlasTheme.Spacing.sm)
        .frame(height: 52)
        .background(AtlasTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AtlasTheme.Radius.md, style: .continuous)
                .stroke(isProgressive ? AtlasTheme.Colors.progress : AtlasTheme.Colors.border, lineWidth: isProgressive ? 2 : 1)
        )
    }

    private func formatWeight(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

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
                    Button("Stop") {
                        manager.stop()
                    }
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
                        .background(
                            session.overallFeeling == value ? AtlasTheme.Colors.accent : AtlasTheme.Colors.background
                        )
                        .foregroundStyle(session.overallFeeling == value ? .white : AtlasTheme.Colors.textPrimary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AtlasTheme.Colors.border, lineWidth: 1))
                    }
                }

                Button("Skip") {
                    finishSession()
                }
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

struct SetPrefill {
    let weight: Double
    let reps: Int
    let rpe: Double
}

@MainActor
final class ActiveWorkoutViewModel: ObservableObject {
    func prefillSet(for exerciseID: UUID, currentSession: WorkoutSession, sessions: [WorkoutSession]) -> SetPrefill? {
        let current = currentSession.setEntries
            .filter { $0.exerciseId == exerciseID }
            .sorted { $0.setIndex < $1.setIndex }

        if let currentLast = current.last {
            return SetPrefill(weight: currentLast.weight, reps: currentLast.reps, rpe: currentLast.rpe)
        }

        guard let reference = latestSessionSet(for: exerciseID, currentSession: currentSession, sessions: sessions) else {
            return nil
        }

        return SetPrefill(weight: reference.weight, reps: reference.reps, rpe: reference.rpe)
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

        if setIndex < sets.count {
            return sets[setIndex]
        }

        return sets.last
    }

    private func latestSessionSet(for exerciseID: UUID, currentSession: WorkoutSession, sessions: [WorkoutSession]) -> SetEntry? {
        guard let session = latestSession(for: exerciseID, currentSession: currentSession, sessions: sessions) else {
            return nil
        }

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

        activity = try? Activity<RestTimerAttributes>.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )

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
        Task {
            await activity.end(nil, dismissalPolicy: dismissalPolicy)
        }
        self.activity = nil
    }

    deinit {
        task?.cancel()
    }
}

#Preview {
    NavigationStack {
        let container = PreviewSampleData.makePreviewContainer()
        let session = (try? container.mainContext.fetch(FetchDescriptor<WorkoutSession>()))?.first

        return Group {
            if let session {
                ActiveWorkoutView(session: session)
                    .modelContainer(container)
            }
        }
    }
}
