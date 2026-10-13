// SensoryView.swift
import SwiftUI

struct SensoryView: View {
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = SensoryViewModel()
    @State private var appeared = false

    private let accent = Color(hex: "#BF5AF2")

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.h3BG(scheme).ignoresSafeArea()
                Circle()
                    .fill(accent.opacity(scheme == .dark ? 0.10 : 0.06))
                    .frame(width: 360)
                    .offset(x: 140, y: -200)
                    .blur(radius: 90)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    // Banner simulador — SOLO cuando hay mensajes activos
                    if vm.isSimulatorMode && !vm.messages.isEmpty {
                        simulatorBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if vm.messages.isEmpty {
                        emptyState
                    } else {
                        messageList
                    }

                    if vm.isLoading { loadingIndicator }

                    inputBar
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.82), value: vm.isSimulatorMode)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.isLoading)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    // MARK: - Toolbar
    // El título "Guía Sensorial" SOLO aparece cuando ya hay mensajes (dentro del chat)
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            if !vm.messages.isEmpty {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(accent)
                    }
                    Text(lm.s(L.sensoryTitle))
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(Color.h3Text(scheme))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }

        ToolbarItem(placement: .topBarLeading) {
            if !vm.messages.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.35)) { vm.clearChat() }
                } label: {
                    Text(lm.s(L.sensoryClear))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(accent)
                }
                .transition(.opacity)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.h3Sub(scheme))
            }
        }
    }

    // MARK: - Banner simulador
    private var simulatorBanner: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(accent)
            Text(lm.s(L.sensorySimulatorBanner))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.h3Sub(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(accent.opacity(0.08))
        .overlay(Rectangle().fill(accent.opacity(0.25)).frame(height: 1), alignment: .bottom)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Estado vacío — aquí SÍ aparece el título grande
    private var emptyState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer(minLength: 20)

                // Hero con título — solo visible en estado vacío
                VStack(spacing: 14) {
                    ZStack {
                        ForEach([72, 54, 38].indices, id: \.self) { i in
                            Circle()
                                .stroke(accent.opacity(0.08 - Double(i) * 0.02), lineWidth: 1)
                                .frame(width: CGFloat([72, 54, 38][i]),
                                       height: CGFloat([72, 54, 38][i]))
                        }
                        Circle()
                            .fill(accent.opacity(0.14))
                            .frame(width: 56, height: 56)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(accent)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 6) {
                        // Título grande — solo aquí en el estado vacío
                        Text(lm.s(L.sensoryTitle))
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(Color.h3Text(scheme))
                        Text(lm.s(L.sensorySubtitle))
                            .font(.system(size: 14))
                            .foregroundColor(Color.h3Sub(scheme))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05), value: appeared)

                // Sugerencias
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(accent.opacity(0.5))
                            .frame(width: 3, height: 14)
                            .cornerRadius(2)
                        Text(lm.s(L.sensorySuggestions))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.h3Sub(scheme))
                            .tracking(0.5)
                            .textCase(.uppercase)
                    }
                    .padding(.horizontal, 24)

                    ForEach(Array(vm.quickSuggestions.enumerated()), id: \.offset) { idx, suggestion in
                        Button {
                            vm.inputText = suggestion
                            vm.sendMessage()
                        } label: {
                            HStack(spacing: 12) {
                                Text("\(idx + 1)")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundColor(accent)
                                    .frame(width: 22, height: 22)
                                    .background(accent.opacity(0.12))
                                    .clipShape(Circle())

                                Text(suggestion)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.h3Text(scheme))
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color.h3Sub(scheme).opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.h3Card(scheme))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.h3Separator(scheme), lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                        }
                        .buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.8)
                                .delay(0.12 + Double(idx) * 0.07),
                            value: appeared
                        )
                    }
                }

                Spacer(minLength: 24)
            }
        }
        .onAppear { appeared = true }
    }

    // MARK: - Lista de mensajes
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    ForEach(vm.messages) { message in
                        SensoryMessageBubble(message: message)
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .onChange(of: vm.messages.count) { _, _ in
                if let last = vm.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Loading indicator
    private var loadingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 30, height: 30)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 13))
                    .foregroundColor(accent)
            }

            TypingDotsView(accent: accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.h3Card(scheme))
                .cornerRadius(18, corners: [.topLeft, .topRight, .bottomRight])
                .shadow(color: .black.opacity(scheme == .dark ? 0.2 : 0.05), radius: 6, y: 2)

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Input bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.h3Separator(scheme).opacity(0), Color.h3Separator(scheme)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 1)

            HStack(alignment: .bottom, spacing: 10) {
                TextField(lm.s(L.sensoryPlaceholder), text: $vm.inputText, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(Color.h3Text(scheme))
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color.h3Card(scheme))
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                vm.inputText.isEmpty
                                    ? Color.h3Separator(scheme)
                                    : accent.opacity(0.45),
                                lineWidth: 1.5
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: vm.inputText.isEmpty)
                    .onSubmit { vm.sendMessage() }

                Button { vm.sendMessage() } label: {
                    ZStack {
                        Circle()
                            .fill(
                                vm.canSend
                                    ? LinearGradient(colors: [accent, accent.opacity(0.7)],
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.h3Card2(scheme), Color.h3Card2(scheme)],
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing)
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(vm.canSend ? .white : Color.h3Sub(scheme).opacity(0.4))
                    }
                }
                .disabled(!vm.canSend)
                .scaleEffect(vm.canSend ? 1.0 : 0.9)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: vm.canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .padding(.bottom, 8)
        }
        .background(Color.h3BG(scheme))
    }
}

// MARK: - Typing dots
struct TypingDotsView: View {
    let accent: Color
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(accent.opacity(phase == i ? 0.9 : 0.3))
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.2 : 0.85)
                    .animation(.easeInOut(duration: 0.35), value: phase)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

#Preview {
    SensoryView()
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
