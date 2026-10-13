// SurveyView.swift
import SwiftUI

// MARK: - SurveyView

struct SurveyView: View {
    @StateObject private var vm = SurveyViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            Color.h3BG(scheme).ignoresSafeArea()

            Circle()
                .fill(Color.h3Orange.opacity(scheme == .dark ? 0.08 : 0.05))
                .frame(width: 280).offset(x: 130, y: -80)
                .blur(radius: 70).ignoresSafeArea()

            if vm.submitted {
                SuccessView(onClose: { dismiss() })
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity))
            } else {
                questionFlow
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: vm.submitted)
    }

    // MARK: - Question flow

    private var questionFlow: some View {
        VStack(spacing: 0) {
            surveyHeader
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    progressBar
                    questionCard
                    if vm.isLast && vm.selectedOption != nil {
                        submitButton
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
    }

    // MARK: - Header

    private var surveyHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.h3Text(scheme))
                    .padding(10)
                    .background(Color.h3Card(scheme))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Encuesta de visita")
                .font(.system(size: 17, weight: .black))
                .foregroundColor(Color.h3Text(scheme))

            Spacer()

            Text("\(vm.currentIndex + 1)/\(vm.questions.count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.h3Sub(scheme))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.h3Card(scheme))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.h3Separator(scheme))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [Color.h3OrangeLight, Color.h3Orange],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * vm.progress, height: 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: vm.progress)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Question card

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pregunta \(vm.currentIndex + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.h3Orange)
                    .textCase(.uppercase)
                    .tracking(1)

                Text(vm.current.text)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(Color.h3Text(scheme))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }

            VStack(spacing: 10) {
                ForEach(Array(vm.current.options.enumerated()), id: \.offset) { _, option in
                    SurveyOptionButton(
                        label: option,
                        isSelected: vm.selectedOption == option,
                        scheme: scheme
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        vm.select(option)
                    }
                }
            }

            if vm.current.hasFollowUp && vm.selectedOption != nil {
                followUpBox
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if vm.current.hasFollowUp && vm.selectedOption != nil && !vm.isLast {
                nextButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(24)
        .background(Color.h3Card(scheme))
        .cornerRadius(24)
        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.07), radius: 16, x: 0, y: 6)
        .id(vm.currentIndex)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)))
    }

    // MARK: - Follow-up text box

    private var followUpBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.h3Orange)
                Text("Cuéntanos más (opcional)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.h3Sub(scheme))
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.h3BG(scheme))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.h3Orange.opacity(0.35), lineWidth: 1.5))

                if (vm.followUpTexts[vm.current.id] ?? "").isEmpty {
                    Text("Escribe tu respuesta aquí…")
                        .font(.system(size: 14))
                        .foregroundColor(Color.h3Sub(scheme).opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }

                TextEditor(text: Binding(
                    get: { vm.followUpTexts[vm.current.id] ?? "" },
                    set: { vm.followUpTexts[vm.current.id] = $0 }
                ))
                .font(.system(size: 14))
                .foregroundColor(Color.h3Text(scheme))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(8)
            }
            .frame(minHeight: 90)
        }
    }

    // MARK: - Next button

    private var nextButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            vm.next()
        } label: {
            HStack(spacing: 8) {
                Text("Siguiente")
                    .font(.system(size: 16, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.h3Orange)
            .cornerRadius(16)
            .shadow(color: Color.h3Orange.opacity(0.4), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit button

    private var submitButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            vm.submit()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                Text("Enviar respuestas")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LinearGradient(
                colors: [Color(hex: "#30D158"), Color(hex: "#25A244")],
                startPoint: .leading, endPoint: .trailing))
            .cornerRadius(18)
            .shadow(color: Color(hex: "#30D158").opacity(0.4), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SurveyOptionButton

struct SurveyOptionButton: View {
    let label: String
    let isSelected: Bool
    let scheme: ColorScheme
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.h3Orange : Color.h3Separator(scheme), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.h3Orange)
                            .frame(width: 13, height: 13)
                    }
                }
                Text(label)
                    .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color.h3Orange : Color.h3Text(scheme))
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.h3Orange.opacity(0.10) : Color.h3BG(scheme))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.h3Orange : Color.h3Separator(scheme),
                                lineWidth: isSelected ? 1.5 : 1))
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
            .animation(.spring(response: 0.18, dampingFraction: 0.55), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded   { _ in pressed = false })
    }
}

// MARK: - SuccessView

struct SuccessView: View {
    let onClose: () -> Void
    @Environment(\.colorScheme) var scheme
    @State private var scale: CGFloat = 0.6
    @State private var badgeScale: CGFloat = 0.5
    @State private var badgeOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#30D158").opacity(0.12))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)
                        Image("encuesta")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .shadow(color: Color(hex: "#30D158").opacity(0.4), radius: 20, y: 8)
                            .scaleEffect(badgeScale)
                            .opacity(badgeOpacity)
                    }
                    VStack(spacing: 6) {
                        Text("🎉 ¡Medalla desbloqueada!")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#30D158"))
                        Text("Voz del Horno")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(Color.h3Text(scheme))
                        Text("Gracias por compartir tu experiencia.\nTus respuestas nos ayudan a mejorar.")
                            .font(.system(size: 14))
                            .foregroundColor(Color.h3Sub(scheme))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                }
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onClose()
                } label: {
                    Text("Cerrar")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(LinearGradient(
                            colors: [Color(hex: "#30D158"), Color(hex: "#25A244")],
                            startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(18)
                        .shadow(color: Color(hex: "#30D158").opacity(0.4), radius: 12, y: 5)
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .background(Color.h3Card(scheme))
            .cornerRadius(32)
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.08), radius: 24, y: 8)
            .padding(.horizontal, 24)
            .scaleEffect(scale)
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { scale = 1.0 }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.2)) {
                badgeScale = 1.0
                badgeOpacity = 1.0
            }
        }
    }
}

#Preview {
    SurveyView()
        .preferredColorScheme(.dark)
}
