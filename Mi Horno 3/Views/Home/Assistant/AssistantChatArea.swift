// AssistantChatArea.swift

import SwiftUI

struct AssistantChatArea: View {
    @ObservedObject var vm: AssistantViewModel
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            switch vm.state {
            case .downloadingModel(let p):
                ModelLoadingScreen(phrase: vm.currentLoadingPhrase,
                                   progress: p, isDownloading: true)
                    .transition(.opacity)

            case .loadingModel:
                ModelLoadingScreen(phrase: vm.currentLoadingPhrase,
                                   progress: 1.0, isDownloading: false)
                    .transition(.opacity)

            default:
                chatView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: vm.state)
    }

    // MARK: - Chat

    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {

                    if vm.messages.isEmpty && vm.streamingText.isEmpty {
                        emptyState
                            .padding(.top, 60)
                    }

                    ForEach(vm.messages) { msg in
                        ChatBubble(message: msg)
                            .id(msg.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: msg.role == .user ? .trailing : .leading)
                                    .combined(with: .opacity),
                                removal: .opacity))
                    }

                    if !vm.streamingText.isEmpty {
                        StreamingBubble(text: vm.streamingText).id("streaming")
                    }

                    if vm.state == .processing {
                        TypingBubble().id("typing")
                    }

                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.messages.count)
            }
            .onChange(of: vm.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("bottom") }
            }
            .onChange(of: vm.streamingText) { _ in
                proxy.scrollTo("streaming", anchor: .bottom)
            }
            .onChange(of: vm.state) { s in
                if s == .processing {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Estado vacío

    private var emptyState: some View {
        VStack(spacing: 20) {
            // Ícono del museo
            ZStack {
                Circle()
                    .fill(Color.h3Orange.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "building.columns")
                    .font(.system(size: 32))
                    .foregroundColor(Color.h3Orange.opacity(0.5))
            }

            VStack(spacing: 6) {
                Text(lm.s(L.assistantEmptyHint))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.h3Text(scheme).opacity(0.6))
                    .multilineTextAlignment(.center)

                Text("↓")
                    .font(.system(size: 20))
                    .foregroundColor(Color.h3Orange.opacity(0.4))
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Pantalla de carga

struct ModelLoadingScreen: View {
    let phrase: String
    let progress: Double
    let isDownloading: Bool
    @Environment(\.colorScheme) var scheme

    @State private var rotation: Double = 0
    @State private var pulse    = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Ícono animado
            ZStack {
                // Anillo exterior pulsante
                Circle()
                    .stroke(Color.h3Orange.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 130, height: 130)
                    .scaleEffect(pulse ? 1.08 : 1.0)

                // Arco giratorio
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.h3Orange, Color.h3Orange.opacity(0.2)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(rotation))

                // Ícono centro
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color.h3Orange)
                    Text("H3")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color.h3Orange)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .padding(.bottom, 36)

            // Frase rotante
            Text(phrase)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.h3Text(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .animation(.easeInOut(duration: 0.4), value: phrase)
                .padding(.bottom, 8)

            // Subtítulo
            if isDownloading {
                Text("Solo la primera vez · ~400 MB")
                    .font(.system(size: 12))
                    .foregroundColor(Color.h3Sub(scheme))
                    .padding(.bottom, 32)
            } else {
                Text("Iniciando el motor de IA…")
                    .font(.system(size: 12))
                    .foregroundColor(Color.h3Sub(scheme))
                    .padding(.bottom, 32)
            }

            // Barra de progreso
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.h3Card2(scheme))
                            .frame(height: 5)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.h3Orange, Color(hex: "#FF9A5C")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(max(progress, 0), 1), height: 5)
                            .animation(.easeInOut(duration: 0.4), value: progress)
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 48)

                if isDownloading && progress > 0 {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.h3Orange)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Burbuja usuario / asistente

struct ChatBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) var scheme

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                // Avatar del asistente
                ZStack {
                    Circle()
                        .fill(Color.h3Orange.opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color.h3Orange)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(isUser
                        ? .white
                        : Color.h3Text(scheme))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(bubbleBackground)
                    .cornerRadius(20, corners: isUser
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight])

                Text(timeString)
                    .font(.system(size: 10))
                    .foregroundColor(Color.h3Sub(scheme).opacity(0.5))
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isUser {
            Color.h3Orange
        } else {
            scheme == .dark
                ? Color.white.opacity(0.09)
                : Color.black.opacity(0.06)
        }
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: message.timestamp)
    }
}

// MARK: - Burbuja streaming

struct StreamingBubble: View {
    let text: String
    @Environment(\.colorScheme) var scheme
    @State private var cursor = true

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.h3Orange.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color.h3Orange)
            }

            Text(text + (cursor ? "▍" : " "))
                .font(.system(size: 15))
                .foregroundColor(Color.h3Text(scheme))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    scheme == .dark
                        ? Color.white.opacity(0.09)
                        : Color.black.opacity(0.06)
                )
                .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])

            Spacer(minLength: 60)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                cursor.toggle()
            }
        }
    }
}

// MARK: - Typing indicator

struct TypingBubble: View {
    @State private var d1 = false
    @State private var d2 = false
    @State private var d3 = false
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.h3Orange.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color.h3Orange)
            }

            HStack(spacing: 5) {
                ForEach([(d1, 0.0), (d2, 0.18), (d3, 0.36)], id: \.1) { active, delay in
                    Circle()
                        .fill(Color.h3Orange.opacity(0.7))
                        .frame(width: 7, height: 7)
                        .offset(y: active ? -5 : 0)
                        .animation(
                            .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(delay),
                            value: active)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                scheme == .dark
                    ? Color.white.opacity(0.09)
                    : Color.black.opacity(0.06)
            )
            .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])

            Spacer(minLength: 60)
        }
        .onAppear { d1 = true; d2 = true; d3 = true }
    }
}

#Preview("Dark") {
    AssistantChatArea(vm: AssistantViewModel())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    AssistantChatArea(vm: AssistantViewModel())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.light)
}
