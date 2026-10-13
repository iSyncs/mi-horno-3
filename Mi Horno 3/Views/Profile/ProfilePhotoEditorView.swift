// ProfilePhotoEditorView.swift
import SwiftUI
import PhotosUI

// MARK: - Helpers de color locales (delegan en DesignSystem.swift)
// Estos evitan problemas de inferencia de tipos en closures y subcomponentes
private func edSub(_ s: ColorScheme)  -> Color { Color.h3Sub(s) }
private func edCard(_ s: ColorScheme) -> Color { Color.h3Card(s) }
private func edCard2(_ s: ColorScheme)-> Color { Color.h3Card2(s) }
private func edText(_ s: ColorScheme) -> Color { Color.h3Text(s) }
private func edSep(_ s: ColorScheme)  -> Color { Color.h3Separator(s) }

// MARK: - Modelos

enum AvatarBackground: Equatable {
    case gradient(Int)
    case solidColor(Int)
}

enum AvatarFrame: String, CaseIterable {
    case none    = "Ninguno"
    case classic = "Clásico"
    case rainbow = "Arcoíris"
    case glow    = "Brillo"
    case dots    = "Puntos"
    case dashes  = "Guiones"
    case double_ = "Doble"
    case pride   = "Orgullo"
}

enum AvatarShape: String, CaseIterable {
    case circle   = "Círculo"
    case rounded  = "Redondeado"
    case squircle = "Squircle"
    case hexagon  = "Hexágono"
    case flower   = "Flor"
}

enum AvatarMode: String, CaseIterable {
    case photo    = "Foto"
    case initials = "Iniciales"
}

struct ProfilePhotoConfig {
    var mode: AvatarMode             = .initials
    var photo: UIImage?              = nil
    var initials: String             = "JD"
    var background: AvatarBackground = .gradient(0)
    var frame: AvatarFrame           = .classic
    var shape: AvatarShape           = .circle
    var frameOpacity: Double         = 1.0
    var fontStyle: Int               = 0
}

// MARK: - Vista principal del editor

struct ProfilePhotoEditorView: View {

    @Binding var isShowing: Bool
    var initialConfig: ProfilePhotoConfig = ProfilePhotoConfig()
    var onSave: (ProfilePhotoConfig) -> Void

    @Environment(\.colorScheme) var scheme
    @State private var config          = ProfilePhotoConfig()
    @State private var selectedTab     = 0
    @State private var appeared        = false
    @State private var photosItem: PhotosPickerItem? = nil
    @State private var showPhotoPicker = false

    private let tabs     = ["Estilo", "Color", "Marco", "Forma"]
    private let tabIcons = ["person.crop.circle", "paintpalette", "circle.dashed", "square.on.circle"]

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { dismissEditor() }

            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {

                    RoundedRectangle(cornerRadius: 2.5).fill(Color.white.opacity(0.35))
                        .frame(width: 36, height: 5).padding(.top, 12).padding(.bottom, 8)

                    HStack {
                        Button("Cancelar") { dismissEditor() }
                            .font(.system(size: 16)).foregroundColor(edSub(scheme))
                        Spacer()
                        Text("Editar foto").font(.system(size: 17, weight: .bold))
                            .foregroundColor(edText(scheme))
                        Spacer()
                        Button("Listo") {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onSave(config); dismissEditor()
                        }
                        .font(.system(size: 16, weight: .bold)).foregroundColor(Color.h3Orange)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 20)

                    avatarPreview.padding(.bottom, 4)
                    modePicker.padding(.top, 8)
                    tabBar.padding(.top, 14)
                    tabContent.frame(height: 265)

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSave(config); dismissEditor()
                    } label: {
                        Text("Guardar foto de perfil")
                            .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Color.h3Orange).cornerRadius(16)
                    }
                    .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 8)

                    Color.clear.frame(height: 20)
                }
                .background(edCard(scheme))
                .clipShape(RoundedCornerShape(radius: 28, corners: [.topLeft, .topRight]))
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photosItem, matching: .images)
        .onChange(of: photosItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img  = UIImage(data: data) { config.photo = img; config.mode = .photo }
            }
        }
        .onAppear {
            // Carga el config actual (con iniciales reales del perfil)
            config = initialConfig
            withAnimation(.spring(response: 0.5)) { appeared = true }
        }
    }

    // MARK: - Preview

    private var avatarPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Color.h3Orange.opacity(0.05))
                .frame(height: 155).padding(.horizontal, 20)

            VStack(spacing: 10) {
                AvatarFullView(config: config, size: 100)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)
                Text("Vista previa").font(.system(size: 11)).foregroundColor(edSub(scheme))
            }

            VStack {
                HStack {
                    Spacer()
                    Button { randomize() } label: {
                        ZStack {
                            Circle().fill(edCard2(scheme)).frame(width: 38, height: 38)
                                .overlay(Circle().stroke(edSep(scheme), lineWidth: 0.5))
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                            Image(systemName: "dice.fill")
                                .font(.system(size: 16, weight: .semibold)).foregroundColor(Color.h3Orange)
                        }
                    }.buttonStyle(.plain)
                }.padding(.trailing, 32)
                Spacer()
            }.frame(height: 155)
        }
    }

    // MARK: - Selector de modo

    private var modePicker: some View {
        HStack(spacing: 10) {
            modeButton(mode: .photo,    icon: "photo.on.rectangle.angled", label: "Subir foto")
            modeButton(mode: .initials, icon: "textformat.size",            label: "Iniciales")
        }.padding(.horizontal, 20)
    }

    private func modeButton(mode: AvatarMode, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { config.mode = mode }
            if mode == .photo { showPhotoPicker = true }
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(label).font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(config.mode == mode ? .white : edText(scheme))
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(config.mode == mode ? Color.h3Orange : edCard2(scheme)))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(config.mode == mode ? Color.clear : edSep(scheme), lineWidth: 0.5))
        }.buttonStyle(.plain)
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(0..<tabs.count, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedTab = i }
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tabIcons[i]).font(.system(size: 12, weight: .semibold))
                            Text(tabs[i]).font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == i ? .white : edSub(scheme))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 20)
                            .fill(selectedTab == i ? Color.h3Orange : edCard2(scheme)))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 20)
        }
    }

    // MARK: - Contenido de tabs

    @ViewBuilder
    private var tabContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                case 0: styleTab
                case 1: colorTab
                case 2: frameTab
                case 3: shapeTab
                default: EmptyView()
                }
            }.padding(.horizontal, 20).padding(.vertical, 14)
        }
    }

    // MARK: - Tab: Estilo

    private var styleTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if config.mode == .photo {
                VStack(spacing: 12) {
                    if let img = config.photo {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 70, height: 70).clipShape(AvatarShapeClip(shape: config.shape))
                    }
                    Button { showPhotoPicker = true } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled").foregroundColor(Color.h3Orange)
                            Text("Cambiar foto").foregroundColor(edText(scheme))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(edSub(scheme)).font(.system(size: 13))
                        }.padding(14).background(edCard2(scheme)).cornerRadius(14)
                    }.buttonStyle(.plain)
                }
            } else {
                EditorSectionTitle("Estilo de tipografía", scheme: scheme)

                // Info: las iniciales vienen del nombre del perfil
                HStack(spacing: 7) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12)).foregroundColor(Color.h3Orange)
                    Text("Las iniciales se toman automáticamente de tu nombre y apellido")
                        .font(.system(size: 12)).foregroundColor(edSub(scheme))
                }
                .padding(10).background(Color.h3Orange.opacity(0.07)).cornerRadius(10)

                Text("Elige cómo se ven tus iniciales")
                    .font(.system(size: 12)).foregroundColor(edSub(scheme))

                let fonts: [(String, Font.Design)] = [
                    ("System",  .default), ("Rounded", .rounded),
                    ("Serif",   .serif),   ("Mono",    .monospaced),
                ]
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(0..<fonts.count, id: \.self) { i in
                        Button { withAnimation { config.fontStyle = i } } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14).fill(bgGradient).frame(height: 56)
                                    Text(config.initials.isEmpty ? "AB" : config.initials.uppercased())
                                        .font(.system(size: 22, weight: .black, design: fonts[i].1))
                                        .foregroundColor(.white)
                                }
                                Text(fonts[i].0).font(.system(size: 12, weight: .medium))
                                    .foregroundColor(config.fontStyle == i ? Color.h3Orange : edSub(scheme))
                            }
                            .padding(10).background(edCard2(scheme)).cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(config.fontStyle == i ? Color.h3Orange : Color.clear, lineWidth: 2))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var bgGradient: LinearGradient {
        let pairs: [(String, String)] = [
            ("#F05A28","#FF9A3C"),("#FF3B30","#FF9500"),("#AF52DE","#FF2D55"),("#007AFF","#5856D6"),
            ("#34C759","#00C7BE"),("#FFCC00","#FF9500"),("#1C1C1E","#636366"),("#5856D6","#007AFF"),
            ("#FF2D55","#FF6B9D"),("#00C7BE","#34C759"),("#A2845E","#FF9500"),("#BF5AF2","#5856D6"),
        ]
        let solids = ["#F05A28","#FF3B30","#FF2D55","#AF52DE","#007AFF","#32ADE6",
                      "#34C759","#00C7BE","#FFCC00","#A2845E","#636366","#1C1C1E"]
        switch config.background {
        case .gradient(let i):
            let p = pairs[min(i, pairs.count-1)]
            return LinearGradient(colors: [Color(hex: p.0), Color(hex: p.1)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .solidColor(let i):
            let h = solids[min(i, solids.count-1)]
            return LinearGradient(colors: [Color(hex: h), Color(hex: h)], startPoint: .top, endPoint: .bottom)
        }
    }

    // MARK: - Tab: Color

    private var colorTab: some View {
        let gradPairs: [(String, String)] = [
            ("#F05A28","#FF9A3C"),("#FF3B30","#FF9500"),("#AF52DE","#FF2D55"),("#007AFF","#5856D6"),
            ("#34C759","#00C7BE"),("#FFCC00","#FF9500"),("#1C1C1E","#636366"),("#5856D6","#007AFF"),
            ("#FF2D55","#FF6B9D"),("#00C7BE","#34C759"),("#A2845E","#FF9500"),("#BF5AF2","#5856D6"),
        ]
        let solidHex = ["#F05A28","#FF3B30","#FF2D55","#AF52DE","#007AFF","#32ADE6",
                        "#34C759","#00C7BE","#FFCC00","#A2845E","#636366","#1C1C1E"]
        return VStack(alignment: .leading, spacing: 16) {
            EditorSectionTitle("Gradientes", scheme: scheme)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(Array(gradPairs.enumerated()), id: \.offset) { i, g in
                    let sel: Bool = { if case .gradient(let idx) = config.background { return idx == i }; return false }()
                    Button { withAnimation { config.background = .gradient(i) } } label: {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: g.0), Color(hex: g.1)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(sel ? edText(scheme) : Color.clear, lineWidth: 3))
                            .overlay(sel ? Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(.white) : nil)
                    }.buttonStyle(.plain)
                }
            }
            EditorSectionTitle("Colores sólidos", scheme: scheme)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(Array(solidHex.enumerated()), id: \.offset) { i, hex in
                    let sel: Bool = { if case .solidColor(let idx) = config.background { return idx == i }; return false }()
                    Button { withAnimation { config.background = .solidColor(i) } } label: {
                        Circle().fill(Color(hex: hex)).frame(width: 44, height: 44)
                            .overlay(Circle().stroke(sel ? edText(scheme) : Color.clear, lineWidth: 3))
                            .overlay(sel ? Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(.white) : nil)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Tab: Marco

    private var frameTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").font(.system(size: 12)).foregroundColor(Color.h3Orange)
                Text("Los marcos son animados y se adaptan a la forma")
                    .font(.system(size: 12)).foregroundColor(edSub(scheme))
            }.padding(10).background(Color.h3Orange.opacity(0.08)).cornerRadius(10)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                ForEach(AvatarFrame.allCases, id: \.self) { frame in
                    Button {
                        withAnimation { config.frame = frame }
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        VStack(spacing: 6) {
                            // Preview animado de cada marco
                            AnimatedFramePreview(frame: frame, shape: config.shape,
                                                 selected: config.frame == frame)
                                .frame(width: 54, height: 54)
                            Text(frame.rawValue).font(.system(size: 10, weight: .medium))
                                .foregroundColor(config.frame == frame ? Color.h3Orange : edSub(scheme))
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                    }.buttonStyle(.plain)
                }
            }

            EditorSectionTitle("Intensidad", scheme: scheme)
            HStack(spacing: 12) {
                Image(systemName: "circle.dashed").foregroundColor(edSub(scheme)).font(.system(size: 14))
                Slider(value: $config.frameOpacity, in: 0.2...1.0, step: 0.05).tint(Color.h3Orange)
                Image(systemName: "circle").foregroundColor(Color.h3Orange).font(.system(size: 14))
            }
        }
    }

    // MARK: - Tab: Forma

    private var shapeTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            EditorSectionTitle("Forma del avatar", scheme: scheme)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 14) {
                ForEach(AvatarShape.allCases, id: \.self) { shape in
                    Button {
                        withAnimation(.spring(response: 0.35)) { config.shape = shape }
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                AvatarShapeClip(shape: shape)
                                    .fill(config.shape == shape
                                          ? Color.h3Orange.opacity(0.15) : edCard2(scheme))
                                    .frame(width: 60, height: 60)
                                    .overlay(AvatarShapeClip(shape: shape)
                                        .stroke(config.shape == shape
                                                ? Color.h3Orange : edSep(scheme), lineWidth: 2))
                                Image(systemName: "person.fill").font(.system(size: 22))
                                    .foregroundColor(config.shape == shape ? Color.h3Orange : edSub(scheme))
                            }
                            Text(shape.rawValue).font(.system(size: 12, weight: .medium))
                                .foregroundColor(config.shape == shape ? Color.h3Orange : edSub(scheme))
                        }
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func dismissEditor() { withAnimation(.spring(response: 0.4)) { isShowing = false } }

    private func randomize() {
        config.background   = Bool.random() ? .gradient(Int.random(in: 0..<12)) : .solidColor(Int.random(in: 0..<12))
        config.frame        = AvatarFrame.allCases.filter { $0 != .none }.randomElement()!
        config.shape        = AvatarShape.allCases.randomElement()!
        config.fontStyle    = Int.random(in: 0..<4)
        config.frameOpacity = Double.random(in: 0.6...1.0)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - AvatarFullView — 3 capas correctas

struct AvatarFullView: View {
    let config: ProfilePhotoConfig
    let size: CGFloat

    private let solidHexes = ["#F05A28","#FF3B30","#FF2D55","#AF52DE","#007AFF","#32ADE6",
                               "#34C759","#00C7BE","#FFCC00","#A2845E","#636366","#1C1C1E"]
    private let gradientPairs: [(String, String)] = [
        ("#F05A28","#FF9A3C"),("#FF3B30","#FF9500"),("#AF52DE","#FF2D55"),("#007AFF","#5856D6"),
        ("#34C759","#00C7BE"),("#FFCC00","#FF9500"),("#1C1C1E","#636366"),("#5856D6","#007AFF"),
        ("#FF2D55","#FF6B9D"),("#00C7BE","#34C759"),("#A2845E","#FF9500"),("#BF5AF2","#5856D6"),
    ]

    private var bgColors: [Color] {
        switch config.background {
        case .gradient(let i):
            let p = gradientPairs[min(i, gradientPairs.count-1)]
            return [Color(hex: p.0), Color(hex: p.1)]
        case .solidColor(let i):
            let h = solidHexes[min(i, solidHexes.count-1)]
            return [Color(hex: h), Color(hex: h)]
        }
    }

    var body: some View {
        ZStack {
            // CAPA 1 — Fondo con forma
            AvatarShapeClip(shape: config.shape)
                .fill(LinearGradient(colors: bgColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)

            // CAPA 2 — Contenido clippeado
            Group {
                if config.mode == .photo, let img = config.photo {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    let designs: [Font.Design] = [.default, .rounded, .serif, .monospaced]
                    Text(config.initials.uppercased())
                        .font(.system(size: size * 0.32, weight: .black,
                                      design: designs[min(config.fontStyle, 3)]))
                        .foregroundColor(.white)
                }
            }
            .frame(width: size, height: size)
            .clipShape(AvatarShapeClip(shape: config.shape))

            // CAPA 3 — Marco animado encima de todo
            AnimatedFrameView(frame: config.frame, shape: config.shape,
                              size: size + 12, opacity: config.frameOpacity)
        }
        .frame(width: size + 12, height: size + 12)
    }
}

// Para compatibilidad con ProfileView y HomeHeader (no cambian)
struct AvatarShapeView: View {
    let config: ProfilePhotoConfig
    let size: CGFloat
    var body: some View { AvatarFullView(config: config, size: size) }
}
struct AvatarFrameView: View {
    let config: ProfilePhotoConfig
    let size: CGFloat
    var body: some View { EmptyView() }
}

// MARK: - AnimatedFrameView — marcos animados en tiempo real

struct AnimatedFrameView: View {
    let frame: AvatarFrame
    let shape: AvatarShape
    let size: CGFloat
    let opacity: Double

    // Animaciones
    @State private var rotation: Double = 0
    @State private var phase: CGFloat   = 0
    @State private var pulse: CGFloat   = 1.0
    @State private var glowRadius: CGFloat = 6

    var body: some View {
        ZStack {
            switch frame {
            case .none:
                EmptyView()

            case .classic:
                // Borde limpio con brillo sutil giratorio
                AvatarShapeClip(shape: shape)
                    .stroke(
                        AngularGradient(colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(opacity),
                            Color.white.opacity(0.4),
                            Color.white.opacity(opacity * 0.7),
                            Color.white.opacity(0.4),
                        ], center: .center, startAngle: .degrees(rotation),
                           endAngle: .degrees(rotation + 360)),
                        lineWidth: 3)
                    .frame(width: size - 4, height: size - 4)
                    .onAppear {
                        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }

            case .rainbow:
                // Arcoíris rotando suavemente
                AvatarShapeClip(shape: shape)
                    .stroke(
                        AngularGradient(colors: [
                            Color.red, Color.orange, Color.yellow,
                            Color.green, Color.cyan, Color.blue,
                            Color.purple, Color.red
                        ], center: .center,
                           startAngle: .degrees(rotation),
                           endAngle: .degrees(rotation + 360)),
                        lineWidth: 4)
                    .frame(width: size - 4, height: size - 4)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }

            case .glow:
                // Glow pulsante
                AvatarShapeClip(shape: shape)
                    .stroke(Color.h3Orange.opacity(opacity * 0.3), lineWidth: 12)
                    .blur(radius: glowRadius)
                    .frame(width: size - 4, height: size - 4)
                AvatarShapeClip(shape: shape)
                    .stroke(Color.h3Orange.opacity(opacity * 0.6), lineWidth: 6)
                    .blur(radius: 3)
                    .frame(width: size - 4, height: size - 4)
                AvatarShapeClip(shape: shape)
                    .stroke(Color.h3Orange.opacity(opacity), lineWidth: 2.5)
                    .frame(width: size - 4, height: size - 4)
                    .scaleEffect(pulse)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulse = 1.03; glowRadius = 14
                        }
                    }

            case .dots:
                // Puntos rotando
                DotsAnimatedFrame(shape: shape, size: size - 4, opacity: opacity, rotation: rotation)
                    .onAppear {
                        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }

            case .dashes:
                // Guiones corriendo (snake dash)
                AvatarShapeClip(shape: shape)
                    .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round,
                                               dash: [8, 6], dashPhase: phase))
                    .foregroundColor(Color.white.opacity(opacity))
                    .frame(width: size - 4, height: size - 4)
                    .onAppear {
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            phase = -28
                        }
                    }

            case .double_:
                // Doble borde con rotación opuesta
                AvatarShapeClip(shape: shape)
                    .stroke(
                        AngularGradient(colors: [
                            Color.white.opacity(opacity * 0.2),
                            Color.white.opacity(opacity * 0.5),
                            Color.white.opacity(opacity * 0.2),
                        ], center: .center,
                           startAngle: .degrees(rotation),
                           endAngle: .degrees(rotation + 360)),
                        lineWidth: 7)
                    .frame(width: size - 2, height: size - 2)
                AvatarShapeClip(shape: shape)
                    .stroke(
                        AngularGradient(colors: [
                            Color.white.opacity(opacity),
                            Color.white.opacity(opacity * 0.6),
                            Color.white.opacity(opacity),
                        ], center: .center,
                           startAngle: .degrees(-rotation),
                           endAngle: .degrees(-rotation + 360)),
                        lineWidth: 2)
                    .frame(width: size - 6, height: size - 6)
                    .onAppear {
                        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }

            case .pride:
                // Orgullo: arcoíris extendido con rotación lenta y brillo
                AvatarShapeClip(shape: shape)
                    .stroke(
                        AngularGradient(colors: [
                            Color.red, Color.orange, Color.yellow, Color.green,
                            Color.cyan, Color.blue, Color.indigo, Color.purple, Color.red
                        ], center: .center,
                           startAngle: .degrees(rotation),
                           endAngle: .degrees(rotation + 360)),
                        lineWidth: 5)
                    .frame(width: size - 3, height: size - 3)
                    .opacity(opacity)
                    .shadow(color: Color.purple.opacity(0.4 * opacity), radius: 6)
                    .scaleEffect(pulse)
                    .onAppear {
                        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            pulse = 1.02
                        }
                    }
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

// MARK: - Puntos animados siguiendo la forma

struct DotsAnimatedFrame: View {
    let shape: AvatarShape
    let size: CGFloat
    let opacity: Double
    let rotation: Double

    private let dotCount = 22

    var body: some View {
        Canvas { ctx, canvasSize in
            let rect   = CGRect(origin: .zero, size: canvasSize).insetBy(dx: 4, dy: 4)
            let path   = AvatarShapeClip(shape: shape).path(in: rect)
            let points = samplePath(path, count: dotCount)

            for (i, pt) in points.enumerated() {
                let progress: Double = Double(i) / Double(dotCount)
                let angle: Double    = (progress * Double.pi * 2.0) + (rotation * Double.pi / 180.0)
                let wave: Double     = sin(angle) * 0.5 + 0.5
                let dSize: CGFloat   = CGFloat(4.0 + wave * 3.0)
                let dRect = CGRect(x: pt.x - dSize/2, y: pt.y - dSize/2, width: dSize, height: dSize)
                ctx.fill(Path(ellipseIn: dRect),
                         with: .color(Color.white.opacity(opacity * (0.5 + wave * 0.5))))
            }
        }
        .frame(width: size, height: size)
    }

    private func samplePath(_ path: Path, count: Int) -> [CGPoint] {
        var pts: [CGPoint] = []
        var cur = CGPoint.zero
        path.cgPath.applyWithBlock { el in
            switch el.pointee.type {
            case .moveToPoint:
                cur = el.pointee.points[0]; pts.append(cur)
            case .addLineToPoint:
                let end = el.pointee.points[0]
                for j in 1...8 {
                    let t = CGFloat(j) / 8
                    pts.append(CGPoint(x: cur.x + (end.x - cur.x)*t, y: cur.y + (end.y - cur.y)*t))
                }
                cur = end
            case .addCurveToPoint:
                let cp1 = el.pointee.points[0], cp2 = el.pointee.points[1], end = el.pointee.points[2]
                for j in 1...16 {
                    let t = CGFloat(j)/16
                    let u = 1-t
                    
                    let term1 = u*u*u
                    let term2 = 3*u*u*t
                    let term3 = 3*u*t*t
                    let term4 = t*t*t
                    
                    let x = term1*cur.x + term2*cp1.x + term3*cp2.x + term4*end.x
                    let y = term1*cur.y + term2*cp1.y + term3*cp2.y + term4*end.y
                    pts.append(CGPoint(x: x, y: y))
                }
                cur = end
            case .addQuadCurveToPoint:
                let cp = el.pointee.points[0], end = el.pointee.points[1]
                for j in 1...12 {
                    let t = CGFloat(j)/12; let u = 1-t
                    
                    let term1 = u*u
                    let term2 = 2*u*t
                    let term3 = t*t
                    
                    pts.append(CGPoint(x: term1*cur.x + term2*cp.x + term3*end.x,
                                       y: term1*cur.y + term2*cp.y + term3*end.y))
                }
                cur = end
            case .closeSubpath: pts.append(pts.first ?? cur)
            @unknown default: break
            }
        }
        guard pts.count > count else { return pts }
        let step = max(1, pts.count / count)
        return stride(from: 0, to: pts.count, by: step).prefix(count).map { pts[$0] }
    }
}

// MARK: - Preview animado en el grid de selección

struct AnimatedFramePreview: View {
    let frame: AvatarFrame
    let shape: AvatarShape
    let selected: Bool
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            AvatarShapeClip(shape: shape)
                .fill(selected ? Color.h3Orange.opacity(0.12) : edCard2(scheme))
                .frame(width: 54, height: 54)

            if frame != .none {
                AnimatedFrameView(frame: frame, shape: shape, size: 52, opacity: 0.9)
            } else {
                Image(systemName: "xmark").font(.system(size: 16)).foregroundColor(.gray)
            }

            AvatarShapeClip(shape: shape)
                .stroke(selected ? Color.h3Orange : Color.clear, lineWidth: 2)
                .frame(width: 54, height: 54)
        }
    }
}

// MARK: - AvatarShapeClip — forma flor rediseñada con curvas suaves orgánicas

struct AvatarShapeClip: Shape {
    let shape: AvatarShape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .circle:
            return Path(ellipseIn: rect)

        case .rounded:
            return Path(roundedRect: rect, cornerRadius: rect.width * 0.22)

        case .squircle:
            return Path(roundedRect: rect, cornerRadius: rect.width * 0.35)

        case .hexagon:
            var p = Path()
            let cx = rect.midX, cy = rect.midY
            let r  = min(rect.width, rect.height) / 2 * 0.96
            for i in 0..<6 {
                let a  = Double(i) * .pi / 3 - .pi / 6
                let pt = CGPoint(x: cx + r * cos(a), y: cy + r * sin(a))
                i == 0 ? p.move(to: pt) : p.addLine(to: pt)
            }
            p.closeSubpath()
            return p

        case .flower:
            return flowerPath(in: rect)
        }
    }

    // Flor orgánica con curvas Bézier cúbicas — suave, redondeada, como iOS
    private func flowerPath(in rect: CGRect) -> Path {
        let cx   = rect.midX
        let cy   = rect.midY
        let r    = min(rect.width, rect.height) / 2
        let petals = 5          // 5 pétalos = flor más natural que 6
        let outerR = r * 0.96
        let innerR = r * 0.44   // valle bien cerrado para que se vea flor, no estrella
        let ctrlRatio: CGFloat = 0.82  // suavidad de las curvas

        var path = Path()

        // Generamos 2*petals puntos alternando pico/valle
        func point(_ index: Int) -> CGPoint {
            let angle  = Double(index) * .pi / Double(petals) - .pi / 2
            let radius = index % 2 == 0 ? outerR : innerR
            return CGPoint(x: cx + radius * cos(angle), y: cy + radius * sin(angle))
        }

        let totalPts = petals * 2
        let p0 = point(0)
        path.move(to: p0)

        for i in 0..<totalPts {
            let next    = point((i + 1) % totalPts)

            // El ángulo del punto actual y siguiente
            let angleA = Double(i) * .pi / Double(petals) - .pi / 2
            let angleB = Double(i + 1) * .pi / Double(petals) - .pi / 2

            // Control points tangenciales para curvas suaves
            let rA = i % 2 == 0 ? outerR * ctrlRatio : innerR / ctrlRatio
            let rB = (i + 1) % 2 == 0 ? outerR * ctrlRatio : innerR / ctrlRatio

            let ctrl1 = CGPoint(
                x: cx + rA * cos(angleA + (angleB - angleA) * 0.35),
                y: cy + rA * sin(angleA + (angleB - angleA) * 0.35)
            )
            let ctrl2 = CGPoint(
                x: cx + rB * cos(angleB - (angleB - angleA) * 0.35),
                y: cy + rB * sin(angleB - (angleB - angleA) * 0.35)
            )

            path.addCurve(to: next, control1: ctrl1, control2: ctrl2)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Subcomponentes

struct EditorSectionTitle: View {
    let text: String
    let scheme: ColorScheme
    init(_ text: String, scheme: ColorScheme) { self.text = text; self.scheme = scheme }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(edSub(scheme)).kerning(0.5)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ProfilePhotoEditorView(isShowing: .constant(true)) { _ in }
    }.preferredColorScheme(.dark)
}
