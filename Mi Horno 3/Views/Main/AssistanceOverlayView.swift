import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - Model
// ─────────────────────────────────────────────

enum AssistanceIncidentOption: String, CaseIterable, Identifiable {
    case lostChild        = "LOST_CHILD"
    case medicalEmergency = "MEDICAL_EMERGENCY"
    case securityIssue    = "SECURITY_ISSUE"
    case exhibitIssue     = "EXHIBIT_ISSUE"
    case accessibilityHelp = "ACCESSIBILITY_HELP"
    case generalHelp      = "GENERAL_HELP"

    var id: String { rawValue }

    var backendTitle: String {
        switch self {
        case .lostChild:         return "Niño extraviado"
        case .medicalEmergency:  return "Emergencia médica"
        case .securityIssue:     return "Incidente de seguridad"
        case .exhibitIssue:      return "Problema en exhibición"
        case .accessibilityHelp: return "Apoyo de accesibilidad"
        case .generalHelp:       return "Ayuda general"
        }
    }

    func title(lm: LocalizationManager) -> String {
        switch self {
        case .lostChild:         return lm.s(L.assistanceLostChild)
        case .medicalEmergency:  return lm.s(L.assistanceMedicalEmergency)
        case .securityIssue:     return lm.s(L.assistanceSecurityIssue)
        case .exhibitIssue:      return lm.s(L.assistanceExhibitIssue)
        case .accessibilityHelp: return lm.s(L.assistanceAccessibilityLabel)
        case .generalHelp:       return lm.s(L.assistanceGeneralHelp)
        }
    }

    func description(lm: LocalizationManager) -> String {
        switch self {
        case .lostChild:         return lm.s(L.assistanceDescLostChild)
        case .medicalEmergency:  return lm.s(L.assistanceDescMedical)
        case .securityIssue:     return lm.s(L.assistanceDescSecurity)
        case .exhibitIssue:      return lm.s(L.assistanceDescExhibit)
        case .accessibilityHelp: return lm.s(L.assistanceDescAccessibility)
        case .generalHelp:       return lm.s(L.assistanceDescGeneral)
        }
    }

    var sfSymbol: String {
        switch self {
        case .lostChild:         return "figure.and.child.holdinghands"
        case .medicalEmergency:  return "cross.case.fill"
        case .securityIssue:     return "shield.lefthalf.filled.badge.checkmark"
        case .exhibitIssue:      return "wrench.and.screwdriver.fill"
        case .accessibilityHelp: return "figure.roll"
        case .generalHelp:       return "person.crop.circle.badge.questionmark"
        }
    }

    var isEmergency: Bool {
        switch self {
        case .lostChild, .medicalEmergency, .securityIssue: return true
        default: return false
        }
    }

    var tint: Color { isEmergency ? .red : .h3Orange }
}

// ─────────────────────────────────────────────
// MARK: - ViewModel
// ─────────────────────────────────────────────

@MainActor
final class AssistanceOverlayModel: ObservableObject {
    @Published var isPresented           = false
    @Published var selectedIncident: AssistanceIncidentOption = .generalHelp
    @Published var details               = ""
    @Published var accessibilityRequired = false
    @Published var translationRequired   = false
    @Published var didSubmit             = false
    @Published var submittedFolio: String?
    @Published var isSubmitting          = false
    @Published var submissionError: String?
    @Published var submissionMessage     = "La solicitud fue enviada al panel de asistencia."
    @Published var submissionNote        = "El personal verá el folio, la ubicación y los apoyos requeridos en tiempo real."

    // Posición del botón flotante (coordenadas globales)
    @Published var buttonPosition: CGPoint = .zero
    var initialPositionSet = false
    private let apiClient = AssistanceAPIClient()

    func toggle() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            isPresented.toggle()
        }
        if !isPresented { didSubmit = false }
    }

    func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
            isPresented = false
        }
    }

    func selectIncident(_ option: AssistanceIncidentOption) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
            selectedIncident = option
        }
        if option == .accessibilityHelp { accessibilityRequired = true }
    }

    func submitDraft() {
        submittedFolio = String(UUID().uuidString.prefix(8)).uppercased()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            didSubmit = true
        }
    }

    fileprivate func submit(context: AssistanceSubmissionContext) async {
        guard !isSubmitting else { return }

        isSubmitting = true
        submissionError = nil

        do {
            let response = try await apiClient.submitReport(
                incidentType: selectedIncident.rawValue,
                title: selectedIncident.backendTitle,
                description: details,
                sourceContext: context.sourceContext,
                locationLabel: context.locationLabel,
                userID: context.userID,
                sourceType: context.sourceType,
                locationSource: context.locationSource,
                floorCode: context.floorCode,
                zoneCode: context.zoneCode,
                mapNodeID: context.mapNodeID,
                qrCodeScanned: context.qrCodeScanned,
                x: context.x,
                y: context.y,
                destinationName: context.destinationName,
                routeName: context.routeName,
                requesterName: context.requesterName,
                requesterEmail: context.requesterEmail,
                preferredLanguageCode: context.preferredLanguageCode,
                accessibilityRequired: accessibilityRequired,
                translationRequired: translationRequired,
                isEmergency: selectedIncident.isEmergency,
                priority: selectedIncident.isEmergency ? "critical" : (selectedIncident == .accessibilityHelp ? "high" : "medium")
            )

            submittedFolio = response.folio
            submissionMessage = "La solicitud fue enviada al panel de asistencia."
            submissionNote = "El dashboard de admin ya puede seguir este caso como pendiente, en proceso o finalizado."
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                didSubmit = true
            }
        } catch {
            submissionError = "No se pudo enviar la solicitud. Verifica la API del museo e inténtalo de nuevo."
        }

        isSubmitting = false
    }

    func resetDraft() {
        selectedIncident      = .generalHelp
        details               = ""
        accessibilityRequired = false
        translationRequired   = false
        didSubmit             = false
        submittedFolio        = nil
        isSubmitting          = false
        submissionError       = nil
        submissionMessage     = "La solicitud fue enviada al panel de asistencia."
        submissionNote        = "El personal verá el folio, la ubicación y los apoyos requeridos en tiempo real."
    }
}

// ─────────────────────────────────────────────
// MARK: - View
// ─────────────────────────────────────────────

struct AssistanceOverlayView: View {
    @EnvironmentObject var router:     AppRouter
    @EnvironmentObject var lm:         LocalizationManager
    @EnvironmentObject var assistance: AssistanceOverlayModel
    @Environment(\.colorScheme) private var scheme

    // delta en tiempo real — se actualiza cada frame sin pasar por @State
    @GestureState private var dragOffset: CGSize = .zero

    // isSnapped: si está pegado a una orilla (cambia solo al SOLTAR, nunca durante el drag)
    @State private var isSnapped:      Bool  = false
    @State private var snappedToRight: Bool  = false
    @State private var pulse:          Bool  = false
    // shimmer phase para la animación del tabPill
    @State private var shimmerPhase:   CGFloat = 0

    private var shouldShow: Bool { router.screen == .main }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if assistance.isPresented {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { assistance.dismiss() }
                        .transition(.opacity)
                        .zIndex(8)
                }
                if assistance.isPresented {
                    sheet(in: proxy)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
                if shouldShow && !assistance.isPresented {
                    draggableButton(in: proxy)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .zIndex(9)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.4, dampingFraction: 0.78), value: assistance.isPresented)
            .onAppear {
                guard !assistance.initialPositionSet else { return }
                // Arranca pegado al lado izquierdo
                assistance.buttonPosition = CGPoint(
                    x: 22,
                    y: proxy.size.height - proxy.safeAreaInsets.bottom - 160
                )
                assistance.initialPositionSet = true
                isSnapped      = true
                snappedToRight = false
                startShimmer()
            }
        }
        .allowsHitTesting(router.screen != .splash)
    }

    // ─────────────────────────────────────────
    // MARK: Draggable button
    // ─────────────────────────────────────────

    private func draggableButton(in proxy: GeometryProxy) -> some View {
        let btnR: CGFloat = 28
        let tabH: CGFloat = 90
        let safeB         = proxy.safeAreaInsets.bottom
        let safeT         = proxy.safeAreaInsets.top
        let minY          = safeT + 60
        let maxY          = proxy.size.height - safeB - tabH - btnR

        // POSICIÓN LIVE durante el drag: base + delta de GestureState (sin re-render de @State)
        let liveX = assistance.buttonPosition.x + dragOffset.width
        let liveY = min(max(assistance.buttonPosition.y + dragOffset.height, minY), maxY)

        let dragging = dragOffset != .zero

        // Durante el drag: círculo siguiendo el dedo 1:1.
        // Al soltar: SIEMPRE va a la orilla más cercana → siempre pill.
        let posX: CGFloat = dragging
            ? min(max(liveX, btnR), proxy.size.width - btnR)
            : (snappedToRight ? proxy.size.width - 22 : 22)
        let posY: CGFloat = liveY

        return Group {
            if dragging {
                // Mientras arrastras: círculo que sigue el dedo exactamente
                circleButton(radius: btnR * 2)
                    .position(x: posX, y: posY)
                    .scaleEffect(1.12)
            } else {
                // En reposo: siempre pill pegada a la orilla
                tabPill(toRight: snappedToRight)
                    .position(x: posX, y: posY)
                    .onAppear { startPulse(); startShimmer() }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    let inertiaFactor: CGFloat = 0.09
                    let projX = assistance.buttonPosition.x
                        + value.translation.width
                        + value.velocity.width * inertiaFactor
                    let projY = assistance.buttonPosition.y
                        + value.translation.height
                        + value.velocity.height * inertiaFactor

                    let clY     = min(max(projY, minY), maxY)
                    // Siempre snap a la orilla más cercana
                    let toRight = projX > proxy.size.width / 2

                    withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
                        snappedToRight = toRight
                        isSnapped      = true
                        assistance.buttonPosition = CGPoint(
                            x: toRight ? proxy.size.width - 22 : 22,
                            y: clY
                        )
                    }
                    startShimmer()
                }
        )
    }

    // ─────────────────────────────────────────
    // MARK: Circle button
    // ─────────────────────────────────────────

    private func circleButton(radius: CGFloat) -> some View {
        Button { assistance.toggle() } label: {
            ZStack {
                // Aro de pulso exterior
                Circle()
                    .fill(Color.h3Orange.opacity(0.15))
                    .frame(width: radius + 22, height: radius + 22)
                    .scaleEffect(pulse ? 1.35 : 1.0)
                    .opacity(pulse ? 0.0 : 0.55)
                    .animation(
                        .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                        value: pulse
                    )

                // Botón principal
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.h3OrangeLight, Color.h3Orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: radius, height: radius)

                Circle()
                    .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                    .frame(width: radius, height: radius)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color.h3Orange.opacity(0.4), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lm.s(L.assistanceTitle))
    }

    // ─────────────────────────────────────────
    // MARK: Tab pill SOS — discreta pero reconocible
    //
    // Diseño: fondo semitransparente oscuro/claro del sistema (sin rojo gritón),
    // ícono de campana pequeño + punto naranja de estado = señal de "ayuda disponible".
    // El rojo queda reservado para el interior del sheet, donde el contexto
    // explica qué es y para qué sirve.
    // ─────────────────────────────────────────

    private func tabPill(toRight: Bool) -> some View {
        Button { assistance.toggle() } label: {
            HStack(spacing: 0) {
                if toRight {
                    pillChevron(pointingLeft: true)
                    pillContent()
                } else {
                    pillContent()
                    pillChevron(pointingLeft: false)
                }
            }
            .frame(height: 44)
            // Fondo: material del sistema (glass) — se mezcla con el fondo de la app
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            // Borde sutil — una línea fina del color del separador, no rojo
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.h3Separator(scheme), lineWidth: 1)
            )
            // Sombra suave — apenas elevación, sin resplandor rojo
            .shadow(color: .black.opacity(scheme == .dark ? 0.28 : 0.10),
                    radius: 8, x: toRight ? -3 : 3, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lm.s(L.assistanceTitle))
    }

    // Ícono de campana + punto de estado naranja
    // El punto de estado (badge) es un patrón universal de iOS:
    // las personas saben que significa "hay algo aquí".
    @ViewBuilder
    private func pillContent() -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.h3Text(scheme).opacity(0.75))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

            // Punto naranja — discreta señal de "disponible / activo"
            Circle()
                .fill(Color.h3Orange)
                .frame(width: 7, height: 7)
                .offset(x: -9, y: 8)
        }
    }

    // Chevron indicador de lado — más suave, mismo color que el ícono
    @ViewBuilder
    private func pillChevron(pointingLeft: Bool) -> some View {
        Image(systemName: pointingLeft ? "chevron.left" : "chevron.right")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(Color.h3Sub(scheme).opacity(0.5))
            .padding(.horizontal, 5)
    }

    // startShimmer: ya no hay shimmer (fondo transparente no lo necesita),
    // se mantiene la función para no romper las llamadas existentes en onAppear/onEnded.
    private func startShimmer() {
        // No-op: el diseño discreto no usa shimmer rojo.
        // La variable shimmerPhase se mantiene para compatibilidad.
    }

    private func startPulse() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { pulse = true }
    }

    // ─────────────────────────────────────────
    // MARK: Sheet
    // ─────────────────────────────────────────

    private func sheet(in proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.h3Separator(scheme))
                .frame(width: 44, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(lm.s(L.assistanceTitle))
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color.h3Text(scheme))

                    Text(lm.s(L.assistanceSubtitle))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.h3Sub(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button { assistance.dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.h3Text(scheme))
                        .frame(width: 34, height: 34)
                        .background(Color.h3Card2(scheme))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    emergencySummaryCard
                    incidentTypeSection
                    supportFlagsSection
                    locationCard
                    detailsCard
                    submitButton
                    submissionErrorCard

                    if assistance.didSubmit {
                        confirmationCard
                            .transition(.scale(scale: 0.94).combined(with: .opacity))
                    }

                    Spacer(minLength: max(proxy.safeAreaInsets.bottom, 18) + 24)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: proxy.size.height * 0.92, alignment: .top)
        .background(Color.h3Card(scheme))
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(scheme == .dark ? 0.34 : 0.14), radius: 24, y: -8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
    }

    // ─────────────────────────────────────────
    // MARK: Sheet subviews
    // ─────────────────────────────────────────

    private var emergencySummaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(assistance.selectedIncident.tint.opacity(0.14))
                    .frame(width: 54, height: 54)

                Image(systemName: assistance.selectedIncident.sfSymbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(assistance.selectedIncident.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(assistance.selectedIncident.title(lm: lm))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.h3Text(scheme))

                Text(assistance.selectedIncident.description(lm: lm))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.h3Sub(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text(assistance.selectedIncident.isEmergency
                 ? lm.s(L.assistanceEmergency)
                 : lm.s(L.assistanceStandard))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(assistance.selectedIncident.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(assistance.selectedIncident.tint.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.h3Card2(scheme))
        .cornerRadius(22)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: assistance.selectedIncident.id)
    }

    private var incidentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lm.s(L.assistanceIncidentType))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.h3Text(scheme))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AssistanceIncidentOption.allCases) { option in
                    Button {
                        assistance.selectIncident(option)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: option.sfSymbol)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(option.tint)
                                Spacer(minLength: 4)
                                if option.isEmergency {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.red)
                                }
                            }

                            Text(option.title(lm: lm))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.h3Text(scheme))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(option.description(lm: lm))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.h3Sub(scheme))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(3)
                        }
                        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
                        .padding(14)
                        .background(
                            assistance.selectedIncident == option
                                ? option.tint.opacity(0.13)
                                : Color.h3Card2(scheme)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    assistance.selectedIncident == option
                                        ? option.tint.opacity(0.85)
                                        : Color.h3Separator(scheme),
                                    lineWidth: assistance.selectedIncident == option ? 2 : 1
                                )
                        )
                        .cornerRadius(18)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25, dampingFraction: 0.75),
                               value: assistance.selectedIncident == option)
                }
            }
        }
    }

    private var supportFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lm.s(L.assistanceNeeds))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.h3Text(scheme))

            Toggle(isOn: $assistance.accessibilityRequired) {
                Label(lm.s(L.assistanceAccessibility), systemImage: "figure.roll")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.h3Text(scheme))
            }
            .toggleStyle(SwitchToggleStyle(tint: .h3Orange))

            Toggle(isOn: $assistance.translationRequired) {
                Label(lm.s(L.assistanceTranslation), systemImage: "captions.bubble.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.h3Text(scheme))
            }
            .toggleStyle(SwitchToggleStyle(tint: .h3Orange))
        }
        .padding(16)
        .background(Color.h3Card2(scheme))
        .cornerRadius(22)
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm.s(L.assistanceLocationTitle))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.h3Text(scheme))

            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.h3Orange)
                    .frame(width: 34, height: 34)
                    .background(Color.h3Orange.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(contextualLocationLabel)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.h3Text(scheme))

                    Text(contextualLocationHint)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.h3Sub(scheme))
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.h3Card2(scheme))
        .cornerRadius(22)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm.s(L.assistanceDetails))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.h3Text(scheme))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.h3Card(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.h3Separator(scheme), lineWidth: 1)
                    )
                    .frame(minHeight: 120)

                if assistance.details.isEmpty {
                    Text(lm.s(L.assistanceDetailsPlaceholder))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.h3Sub(scheme))
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $assistance.details)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.h3Text(scheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minHeight: 120)
            }
        }
        .padding(16)
        .background(Color.h3Card2(scheme))
        .cornerRadius(22)
    }

    private var submitButton: some View {
        Button {
            Task { await submitAssistance() }
        } label: {
            HStack(spacing: 10) {
                if assistance.isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: assistance.selectedIncident.isEmergency
                          ? "siren.fill" : "bell.badge.fill")
                        .font(.system(size: 16, weight: .bold))
                }

                Text(assistance.isSubmitting
                     ? "Enviando..."
                     : assistance.selectedIncident.isEmergency
                     ? lm.s(L.assistanceSubmitEmergency)
                     : lm.s(L.assistanceSubmit))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: assistance.selectedIncident.isEmergency
                        ? [Color(red: 1, green: 0.35, blue: 0.35), Color.red]
                        : [Color.h3OrangeLight, Color.h3Orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(18)
            .shadow(color: assistance.selectedIncident.tint.opacity(0.28), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(assistance.isSubmitting)
        .opacity(assistance.isSubmitting ? 0.9 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.8),
                   value: assistance.selectedIncident.isEmergency)
    }

    private var submissionErrorCard: some View {
        Group {
            if let submissionError = assistance.submissionError, !submissionError.isEmpty {
                Text(submissionError)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
            }
        }
    }

    private var confirmationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(lm.s(L.assistanceSubmittedTitle), systemImage: "checkmark.seal.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "#30D158"))

            Text(assistance.submissionMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.h3Text(scheme))

            if let folio = assistance.submittedFolio {
                Text("\(lm.s(L.assistanceFolio)): \(folio)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.h3Text(scheme))
            }

            Text(assistance.submissionNote)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.h3Sub(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "#30D158").opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#30D158").opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    // ─────────────────────────────────────────
    // MARK: Helpers
    // ─────────────────────────────────────────

    private var currentSectionLabel: String {
        switch router.screen {
        case .splash: return lm.s(L.assistanceLoadingScreen)
        case .login:  return lm.s(L.assistanceAccess)
        case .main:   return router.activeTab.label(lm: lm)
        }
    }

    private var currentMapFloorLabel: String? {
        guard let floorCode = router.indoorMapContext.floorCode else { return nil }
        switch floorCode.uppercased() {
        case "L1", "LEVEL1", "NIVEL1", "PB":
            return "Nivel 1"
        case "L2", "LEVEL2", "NIVEL2", "P1":
            return "Nivel 2"
        case "L3", "LEVEL3", "NIVEL3", "P2":
            return "Nivel 3"
        default:
            return nil
        }
    }

    private var contextualLocationLabel: String {
        guard router.activeTab == .map else { return currentSectionLabel }

        let nodeName = router.indoorMapContext.currentNodeName
        let floorLabel = currentMapFloorLabel

        if let nodeName, let floorLabel {
            return "\(nodeName) · \(floorLabel)"
        }
        if let nodeName {
            return nodeName
        }
        if let floorLabel {
            return "\(currentSectionLabel) · \(floorLabel)"
        }
        return currentSectionLabel
    }

    private var contextualLocationHint: String {
        guard router.activeTab == .map else { return lm.s(L.assistanceLocationHint) }

        var parts: [String] = []

        if let routeName = router.indoorMapContext.selectedRouteName, !routeName.isEmpty {
            parts.append("Ruta: \(routeName)")
        }

        if let destinationName = router.indoorMapContext.selectedDestinationName, !destinationName.isEmpty {
            parts.append("Destino: \(destinationName)")
        }

        return parts.isEmpty ? lm.s(L.assistanceLocationHint) : parts.joined(separator: " · ")
    }

    private var contextualSourceContext: String {
        guard router.activeTab == .map else { return currentSectionLabel }

        var parts = [currentSectionLabel]

        if let routeName = router.indoorMapContext.selectedRouteName, !routeName.isEmpty {
            parts.append("Ruta \(routeName)")
        }

        if let destinationName = router.indoorMapContext.selectedDestinationName, !destinationName.isEmpty {
            parts.append("Destino \(destinationName)")
        }

        return parts.joined(separator: " · ")
    }

    private func submitAssistance() async {
        await assistance.submit(
            context: AssistanceSubmissionContext(
                sourceContext: contextualSourceContext,
                locationLabel: contextualLocationLabel,
                userID: router.userId > 0 ? router.userId : nil,
                sourceType: router.activeTab == .map ? "map_tap" : "help_button",
                locationSource: router.activeTab == .map
                    ? (router.indoorMapContext.currentNodeID != nil ? "node" : (router.indoorMapContext.qrCode != nil ? "qr" : "manual"))
                    : "unknown",
                floorCode: router.activeTab == .map ? router.indoorMapContext.floorCode : nil,
                zoneCode: nil,
                mapNodeID: router.activeTab == .map ? router.indoorMapContext.currentNodeID : nil,
                qrCodeScanned: router.activeTab == .map ? router.indoorMapContext.qrCode : nil,
                x: router.activeTab == .map ? router.indoorMapContext.x : nil,
                y: router.activeTab == .map ? router.indoorMapContext.y : nil,
                destinationName: router.activeTab == .map ? router.indoorMapContext.selectedDestinationName : nil,
                routeName: router.activeTab == .map ? router.indoorMapContext.selectedRouteName : nil,
                requesterName: router.userName.isEmpty ? nil : router.userName,
                requesterEmail: router.userEmail.isEmpty ? nil : router.userEmail,
                preferredLanguageCode: Locale.current.language.languageCode?.identifier ?? "es"
            )
        )
    }
}

private struct AssistanceSubmissionContext {
    let sourceContext: String
    let locationLabel: String
    let userID: Int?
    let sourceType: String
    let locationSource: String
    let floorCode: String?
    let zoneCode: String?
    let mapNodeID: Int?
    let qrCodeScanned: String?
    let x: Double?
    let y: Double?
    let destinationName: String?
    let routeName: String?
    let requesterName: String?
    let requesterEmail: String?
    let preferredLanguageCode: String
}

private struct AssistanceSubmitPayload: Encodable {
    let incidentType: String
    let title: String
    let description: String
    let sourceContext: String
    let locationLabel: String
    let userID: Int?
    let sourceType: String
    let locationSource: String
    let floorCode: String?
    let zoneCode: String?
    let mapNodeID: Int?
    let qrCodeScanned: String?
    let x: Double?
    let y: Double?
    let destinationName: String?
    let routeName: String?
    let requesterName: String?
    let requesterEmail: String?
    let preferredLanguageCode: String
    let accessibilityRequired: Bool
    let translationRequired: Bool
    let isEmergency: Bool
    let priority: String
}

private struct AssistanceSubmitResponse: Decodable {
    let folio: String
}

private struct AssistanceAPIClient {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func submitReport(
        incidentType: String,
        title: String,
        description: String,
        sourceContext: String,
        locationLabel: String,
        userID: Int?,
        sourceType: String,
        locationSource: String,
        floorCode: String?,
        zoneCode: String?,
        mapNodeID: Int?,
        qrCodeScanned: String?,
        x: Double?,
        y: Double?,
        destinationName: String?,
        routeName: String?,
        requesterName: String?,
        requesterEmail: String?,
        preferredLanguageCode: String,
        accessibilityRequired: Bool,
        translationRequired: Bool,
        isEmergency: Bool,
        priority: String
    ) async throws -> AssistanceSubmitResponse {
        guard let url = URL(string: Config.baseURL + "/assistance/requests") else {
            throw URLError(.badURL)
        }

        let payload = AssistanceSubmitPayload(
            incidentType: incidentType,
            title: title,
            description: description,
            sourceContext: sourceContext,
            locationLabel: locationLabel,
            userID: userID,
            sourceType: sourceType,
            locationSource: locationSource,
            floorCode: floorCode,
            zoneCode: zoneCode,
            mapNodeID: mapNodeID,
            qrCodeScanned: qrCodeScanned,
            x: x,
            y: y,
            destinationName: destinationName,
            routeName: routeName,
            requesterName: requesterName,
            requesterEmail: requesterEmail,
            preferredLanguageCode: preferredLanguageCode,
            accessibilityRequired: accessibilityRequired,
            translationRequired: translationRequired,
            isEmergency: isEmergency,
            priority: priority
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try decoder.decode(AssistanceSubmitResponse.self, from: data)
    }
}
