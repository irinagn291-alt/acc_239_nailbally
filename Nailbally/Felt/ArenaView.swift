import SwiftUI

/// Role: Felt. Arena is the wheel. Fair-share nail is the home verb; nights and booth arrive as sheets.
@MainActor
struct ArenaView: View {
    let store: FeltStore
    var handlesLaunch: Bool
    var onNight: (() -> Void)?
    var onBooth: (() -> Void)?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var nameFocused: Bool
    @State private var draft = ""
    @State private var note: String?
    @State private var showSpinner = false
    @State private var showOnboarding = false
    @State private var showJoin = false
    @State private var showFairShare = false
    @State private var phoneSheet: MidwayPane?
    @State private var reviewConsumed = false
    @State private var pieDegrees = 0.0
    @State private var shownNails: UInt64 = 0
    @State private var coastPlan: SpinPlan?
    @State private var coastID: UUID?
    @State private var coasting = false
    @State private var dropTarget: Slice?
    @State private var flashSeat = false

    init(store: FeltStore, handlesLaunch: Bool = true, onNight: (() -> Void)? = nil, onBooth: (() -> Void)? = nil) {
        self.store = store
        self.handlesLaunch = handlesLaunch
        self.onNight = onNight
        self.onBooth = onBooth
    }

    init() {
        self.init(store: FeltFixture.populated(), handlesLaunch: false)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            arena
        }
        .background(TentInk.Palette.background.ignoresSafeArea())
        .sheet(item: $phoneSheet) { pane in
            switch pane {
            case .night:
                HistoryView(store: store)
            case .booth:
                SettingsView(store: store, onRerunOnboarding: rerunOnboarding)
            }
        }
        .sheet(isPresented: $showFairShare) {
            FairShareView(store: store)
        }
        .sheet(isPresented: $showJoin) {
            joinBooth
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                store.markOnboardingComplete()
                showOnboarding = false
                applyReview()
            }
        }
        .confirmationDialog("Lift this name from the felt?", isPresented: Binding(
            get: { dropTarget != nil },
            set: { if !$0 { dropTarget = nil } }
        ), titleVisibility: .visible) {
            Button("Lift name", role: .destructive) {
                if let dropTarget {
                    drop(dropTarget.id)
                }
            }
            Button("Keep", role: .cancel) { dropTarget = nil }
        }
        .task {
            guard handlesLaunch else {
                shownNails = store.felt.nailedMask
                return
            }
            await bootstrap()
        }
        .onChange(of: scenePhase) { _, phase in
            guard handlesLaunch else { return }
            if phase == .inactive || phase == .background {
                Task { await store.flush() }
            }
        }
        .onChange(of: store.felt.onboardingComplete) { _, complete in
            guard handlesLaunch, !complete else { return }
            showOnboarding = true
        }
    }

    private var arena: some View {
        VStack(spacing: TentInk.space(1)) {
            TentHeaderBand()
            chrome
            if let warning = store.warning {
                banner(text: warningCopy(warning), action: "Reload") {
                    Task { await store.load() }
                }
            } else if let error = store.lastWriteError {
                banner(text: "The felt did not save. \(error)", action: "Retry") {
                    Task { await store.flush() }
                }
            } else if store.felt.slices.isEmpty {
                emptyPage
            } else {
                wheelPage
            }
        }
        .overlay {
            if showSpinner {
                ProgressView()
                    .tint(TentInk.Palette.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TentInk.Palette.background.opacity(0.55))
            }
            TentFlash(visible: flashSeat)
        }
    }

    private var chrome: some View {
        HStack(alignment: .top, spacing: TentInk.space(1)) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Nailbally")
                    .tentText(.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(store.felt.slices.first?.name ?? "Empty felt")
                    .tentText(.caption)
                    .foregroundStyle(TentInk.Palette.muted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: TentInk.space(1))
            chromeButton("Night", label: "Night order") { openNight() }
            chromeButton("Booth", label: "Booth settings") { openBooth() }
        }
        .padding(.horizontal, TentInk.space(2))
        .padding(.top, TentInk.space(1))
    }

    private var wheelPage: some View {
        let face = PieFace.project(store.felt, rotation: pieDegrees, nails: shownNails)
        return VStack(spacing: TentInk.space(1)) {
            Button {
                showFairShare = true
            } label: {
                HStack(spacing: TentInk.space(1)) {
                    Text("Open \(TentFigures.count(face.eligibleCount))")
                        .tentText(.figure)
                        .layoutPriority(1)
                    Text("·")
                        .tentText(.caption)
                    Text("Nailed \(TentFigures.count(face.wedges.filter(\.nailed).count))")
                        .tentText(.figure)
                        .layoutPriority(1)
                    Text("Fair-share")
                        .tentText(.caption)
                        .foregroundStyle(TentInk.Palette.accent)
                }
                .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                .padding(.horizontal, TentInk.space(2))
                .background { TentCardBackdrop() }
                .overlay(
                    RoundedRectangle(cornerRadius: TentInk.radius)
                        .stroke(TentInk.Palette.ink.opacity(0.22), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, TentInk.space(2))
            .accessibilityLabel("Fair-share nail. Open names stay in the draw. Nailed names stay on the pie.")
            if let note {
                Text(note)
                    .tentText(.caption)
                    .padding(.horizontal, TentInk.space(2))
            }
            PieCanvas(
                face: face,
                plan: coastPlan,
                planID: coastID,
                hapticsOn: store.felt.hapticsOn,
                reduceMotion: reduceMotion,
                onSeat: seatNail
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(TentInk.space(2))
            .accessibilityLabel("Prize wheel")
            .accessibilityHint("Flick to land an open name")
            roomRow
            Button {
                flick()
            } label: {
                HStack(spacing: TentInk.space(1)) {
                    if let face = TentArt.image(TentStage.control) {
                        face
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                    }
                    Text(flickTitle)
                        .tentText(.body)
                        .foregroundStyle(canFlick ? TentInk.Palette.background : TentInk.Palette.ink)
                }
                .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                .background(canFlick ? TentInk.Palette.accent : TentInk.Palette.surface)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canFlick)
            .padding(.horizontal, TentInk.space(2))
            .padding(.bottom, TentInk.space(2))
        }
    }

    private var roomRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TentInk.space(1)) {
                Button {
                    showJoin = true
                } label: {
                    Text("Join")
                        .tentText(.caption)
                        .frame(minWidth: TentInk.tap, minHeight: TentInk.tap)
                        .tentPanel()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a name")
                ForEach(store.felt.slices) { slice in
                    Button {
                        dropTarget = slice
                    } label: {
                        Text(slice.name)
                            .tentText(.caption)
                            .lineLimit(1)
                            .frame(minHeight: TentInk.tap)
                            .padding(.horizontal, TentInk.space(1))
                            .tentPanel()
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Lift \(slice.name)")
                }
            }
            .padding(.horizontal, TentInk.space(2))
        }
    }

    private var emptyPage: some View {
        VStack(spacing: TentInk.space(2)) {
            emptyMark
                .frame(width: 160, height: 160)
                .accessibilityHidden(true)
            Text("The felt is empty")
                .tentText(.title)
                .multilineTextAlignment(.center)
            Text("Type a name or load a pack. The wheel is the room.")
                .tentText(.body)
                .multilineTextAlignment(.center)
            if let note {
                Text(note)
                    .tentText(.caption)
            }
            Spacer(minLength: 0)
            Button {
                showJoin = true
            } label: {
                Text("Type a name")
                    .tentText(.body)
                    .foregroundStyle(TentInk.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                    .background(TentInk.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                openBooth()
            } label: {
                Text("Load a pack")
                    .tentText(.body)
                    .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                    .tentPanel()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(TentInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var joinBooth: some View {
        VStack(alignment: .leading, spacing: TentInk.space(2)) {
            Text("Seat a name")
                .tentText(.title)
            Text("A late joiner sits open and stays in the draw.")
                .tentText(.body)
            TextField("Name or dare", text: $draft)
                .tentText(.body)
                .focused($nameFocused)
                .padding(.horizontal, TentInk.space(1))
                .frame(minHeight: TentInk.tap)
                .tentPanel()
                .onSubmit { join() }
            Spacer(minLength: 0)
            Button {
                join()
            } label: {
                Text("Seat on the felt")
                    .tentText(.body)
                    .foregroundStyle(canJoin ? TentInk.Palette.background : TentInk.Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                    .background(canJoin ? TentInk.Palette.accent : TentInk.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canJoin || coasting)
        }
        .padding(TentInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TentInk.Palette.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .onAppear { nameFocused = true }
    }

    @ViewBuilder
    private var emptyMark: some View {
        if let art = TentArt.image(TentStage.emptyHome) {
            art.resizable().scaledToFit()
        } else {
            WheelMark()
                .stroke(TentInk.Palette.ink, lineWidth: 2)
        }
    }

    private var canJoin: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canFlick: Bool {
        !coasting && store.felt.openMask != 0
    }

    private var flickTitle: String {
        if coasting { return "Coasting" }
        if store.felt.eligibleCount == 1 { return "Award last open" }
        return "Flick"
    }

    private func chromeButton(_ title: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .tentText(.caption)
                .frame(minWidth: TentInk.tap, minHeight: TentInk.tap)
                .tentPanel()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func banner(text: String, action: String, run: @escaping () -> Void) -> some View {
        VStack(spacing: TentInk.space(1)) {
            Text(text)
                .tentText(.body)
                .multilineTextAlignment(.center)
            Button(action: run) {
                Text(action)
                    .tentText(.body)
                    .foregroundStyle(TentInk.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: TentInk.tap)
                    .tentPanel()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(TentInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openNight() {
        if let onNight {
            onNight()
        } else {
            phoneSheet = .night
        }
    }

    private func openBooth() {
        if let onBooth {
            onBooth()
        } else {
            phoneSheet = .booth
        }
    }

    private func rerunOnboarding() {
        phoneSheet = nil
        store.reopenOnboarding()
        showOnboarding = true
    }

    private func join() {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            try store.join(name)
            draft = ""
            showJoin = false
            nameFocused = false
            note = nil
            shownNails = store.felt.nailedMask
        } catch let fault as FeltFault {
            note = faultCopy(fault)
        } catch {
            note = "That name could not sit."
        }
    }

    private func drop(_ id: UUID) {
        do {
            try store.drop(id)
            dropTarget = nil
            shownNails = store.felt.nailedMask
            note = "Only that nail lifted."
        } catch {
            note = "That name could not lift."
        }
    }

    private func flick() {
        guard !coasting else { return }
        let beforeNails = store.felt.nailedMask
        let open = store.felt.openMask
        do {
            let outcome = try store.land()
            switch outcome.call {
            case .spin(let bit):
                let extra = outcome.plan?.extraTurns ?? 6
                guard let plan = SpinPlan.make(
                    bit: bit,
                    open: open,
                    extraTurns: extra,
                    currentDegrees: pieDegrees
                ) else {
                    note = "The wheel could not coast."
                    return
                }
                shownNails = beforeNails
                coasting = true
                coastPlan = plan
                coastID = UUID()
                note = outcome.land.map { "Landing \($0.name)" }
            case .awardWithoutSpin(let bit):
                shownNails = store.felt.nailedMask
                let name = store.felt.slice(bit: bit)?.name ?? outcome.land?.name ?? "Last open"
                note = store.felt.nailedMask == 0
                    ? "\(name) — last open. Nails lift."
                    : "\(name) awarded without a flick."
                flash()
            case .liftAll:
                shownNails = 0
                note = "Nails lift. Next round."
            }
        } catch let fault as FeltFault {
            note = faultCopy(fault)
        } catch {
            note = "The wheel could not land."
        }
    }

    private func seatNail() {
        if let plan = coastPlan {
            pieDegrees = SpinPlan.normalize(pieDegrees + plan.clockwiseDegrees)
        }
        shownNails = store.felt.nailedMask
        coasting = false
        coastPlan = nil
        if let land = store.lastOutcome?.land {
            note = store.felt.nailedMask == 0
                ? "\(land.name) nailed. Nails lift."
                : "\(land.name) nailed for the round."
        }
        flash()
    }

    private func flash() {
        flashSeat = true
        Task {
            try? await Task.sleep(nanoseconds: 280_000_000)
            flashSeat = false
        }
    }

    private func bootstrap() async {
        let delay = Task {
            try await Task.sleep(nanoseconds: 150_000_000)
            showSpinner = true
        }
        await store.load()
        await store.seedDemoIfNeeded()
        shownNails = store.felt.nailedMask
        delay.cancel()
        showSpinner = false
        if !store.felt.onboardingComplete {
            showOnboarding = true
        } else {
            applyReview()
        }
    }

    private func applyReview() {
        guard handlesLaunch, !reviewConsumed else { return }
        reviewConsumed = true
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-ReviewScreen"), args.indices.contains(index + 1) else { return }
        switch args[index + 1] {
        case "log":
            openNight()
        case "goals":
            openBooth()
        default:
            break
        }
    }

    private func warningCopy(_ warning: FeltWarning) -> String {
        switch warning {
        case .recoveredFromBackup:
            return "The felt was recovered from a backup."
        case .startedEmpty:
            return "The felt file was unreadable. Starting empty."
        }
    }

    private func faultCopy(_ fault: FeltFault) -> String {
        switch fault {
        case .emptyFelt: return "Seat a name first."
        case .fullFelt: return "The pie is full."
        case .blankName: return "Type a name."
        case .unknownSlice: return "That name is not on the felt."
        case .unknownPack: return "That pack is gone."
        case .badDraw: return "The land missed the mask."
        }
    }
}

private struct WheelMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        path.addEllipse(in: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2))
        path.addEllipse(in: CGRect(x: center.x - outer * 0.4, y: center.y - outer * 0.4, width: outer * 0.8, height: outer * 0.8))
        for index in 0 ..< 6 {
            let angle = Double(index) * .pi / 3 - .pi / 2
            path.move(to: center)
            path.addLine(to: CGPoint(
                x: center.x + CGFloat(cos(angle)) * outer,
                y: center.y + CGFloat(sin(angle)) * outer
            ))
        }
        return path
    }
}
