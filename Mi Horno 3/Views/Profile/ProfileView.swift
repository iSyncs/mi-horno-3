// ProfileView.swift
import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme
    @StateObject private var vm = ProfileViewModel()

    @State private var appeared         = false
    @State private var infoExpanded     = false
    @State private var showAvatarPicker = false
    @State private var showDeleteAlert  = false
    @State private var showLogoutAlert  = false
    @State private var showWrapped          = false
    @State private var showSurvey           = false

    var body: some View {
        ZStack {
            Color.h3BG(scheme).ignoresSafeArea()
            Circle()
                .fill(Color.h3Orange.opacity(scheme == .dark ? 0.08 : 0.05))
                .frame(width: 300).offset(x: 120, y: -100)
                .blur(radius: 80).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    avatarHeader.staggered(appeared, delay: 0.05)
                    profileExpandable.staggered(appeared, delay: 0.12)
                    ProfileSectionCard(title: lm.s(L.badgeSectionTitle), icon: "sparkles") {
                        VStack(spacing: 16) {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 20
                            ) {
                                ForEach(vm.getGamificationBadges(newlyClaimed: router.newlyClaimedBadge, lm: lm)) { badge in
                                    GamificationBadgeView(badge: badge)
                                }
                            }
                            Text(lm.s(L.badgeSectionHint))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                    .staggered(appeared, delay: 0.18)
                    
                    surveySection.staggered(appeared, delay: 0.20)
                    summarySection.staggered(appeared, delay: 0.22)
                    Spacer(minLength: 110)
                }
            }

            // Editor de foto de perfil — abre con las iniciales del perfil ya cargadas
            if showAvatarPicker {
                ProfilePhotoEditorView(
                    isShowing: $showAvatarPicker,
                    initialConfig: currentEditorConfig
                ) { config in
                    vm.applyPhotoConfig(config)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showAvatarPicker)
        .onAppear { appeared = true; vm.onAppear(router: router) }
        .onDisappear {
            if router.newlyClaimedBadge != nil {
                router.newlyClaimedBadge = nil
            }
        }
        .alert(lm.s(L.profileDeleteConfirm), isPresented: $showDeleteAlert) {
            Button(lm.s(L.profileDeleteAccount), role: .destructive) {
                Task { await vm.deleteAccount(router: router) }
            }
            Button(lm.s(L.profileDeleteCancel), role: .cancel) {}
        } message: { Text(lm.s(L.profileDeleteMessage)) }
        .alert(lm.s(L.profileLogoutConfirm), isPresented: $showLogoutAlert) {
            Button(lm.s(L.profileLogout), role: .destructive) { vm.logout(router: router) }
            Button(lm.s(L.profileDeleteCancel), role: .cancel) {}
        } message: { Text(lm.s(L.profileLogoutMessage)) }
        .sheet(isPresented: $showWrapped) {
            WrappedView(
                answersCount: vm.answersCount,
                correctCount: vm.correctCount,
                unlockedMedals: vm.getGamificationBadges(newlyClaimed: nil).filter { $0.unlocked }.count,
                totalMedals: vm.getGamificationBadges(newlyClaimed: nil).count,
                badges: vm.getGamificationBadges(newlyClaimed: nil)
            )
        }
        .sheet(isPresented: $showSurvey, onDismiss: {
            vm.reloadBadges()
        }) {
            SurveyView()
        }
    }

    // Config que se pasa al editor: usa el config guardado pero siempre
    // sincroniza las iniciales con el nombre real del perfil
    private var currentEditorConfig: ProfilePhotoConfig {
        var cfg = router.hasCustomPhoto ? router.photoConfig : ProfilePhotoConfig()
        // Siempre derivar iniciales del nombre actual del perfil
        let first  = String(vm.firstName.prefix(1)).uppercased()
        let second = String(vm.lastName.prefix(1)).uppercased()
        let derived = (first + second).trimmingCharacters(in: .whitespaces)
        cfg.initials = derived.isEmpty ? vm.avatarInitials : derived
        return cfg
    }

    // MARK: - Header avatar

    private var avatarHeader: some View {
        VStack(spacing: 14) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.45)) { showAvatarPicker = true }
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    // Avatar — lee desde router.photoConfig
                    ZStack {
                        if router.hasCustomPhoto {
                            AvatarShapeView(config: router.photoConfig, size: 88)
                            AvatarFrameView(config: router.photoConfig, size: 98)
                        } else {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.h3OrangeLight, Color.h3Orange],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 88, height: 88)
                                .shadow(color: Color.h3Orange.opacity(0.4), radius: 16)
                            if let urlStr = vm.selectedAvatarURL, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { img in
                                    img.resizable().scaledToFill()
                                        .frame(width: 88, height: 88).clipShape(Circle())
                                } placeholder: {
                                    Text(vm.avatarInitials)
                                        .font(.system(size: 32, weight: .black)).foregroundColor(.white)
                                }
                            } else {
                                Text(vm.avatarInitials)
                                    .font(.system(size: 32, weight: .black)).foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: 88, height: 88)

                    // Botón editar
                    ZStack {
                        Circle().fill(Color.h3Orange).frame(width: 28, height: 28)
                            .shadow(color: Color.h3Orange.opacity(0.4), radius: 6)
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    }
                    .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                Text(vm.confirmedFullName.isEmpty ? lm.s(L.homeVisitor) : vm.confirmedFullName)
                    .font(.system(size: 22, weight: .black)).foregroundColor(Color.h3Text(scheme))
                Text(vm.loginEmail)
                    .font(.system(size: 13)).foregroundColor(Color.h3Sub(scheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60).padding(.bottom, 28)
    }

    // MARK: - Perfil expandible

    private var profileExpandable: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    infoExpanded.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(Color.h3Orange)
                        Text(lm.s(L.profileTitle))
                            .font(.system(size: 17, weight: .black)).foregroundColor(Color.h3Text(scheme))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(Color.h3Sub(scheme))
                        .rotationEffect(.degrees(infoExpanded ? 90 : 0))
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                .background(Color.h3Card(scheme))
            }
            .buttonStyle(.plain)

            if infoExpanded {
                VStack(spacing: 0) {
                    Divider().padding(.horizontal, 20)
                    VStack(spacing: 16) {
                        HStack(spacing: 10) {
                            ProfileField(icon: "person.fill",
                                         placeholder: lm.s(L.profileFirstName), text: $vm.firstName)
                            ProfileField(icon: "person.fill",
                                         placeholder: lm.s(L.profileLastName),  text: $vm.lastName)
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14)).foregroundColor(Color.h3Orange).frame(width: 20)
                            Text(vm.loginEmail.isEmpty ? "—" : vm.loginEmail)
                                .font(.system(size: 15)).foregroundColor(Color.h3Sub(scheme))
                            Spacer()
                            Text(lm.s(L.profileLoginInfo))
                                .font(.system(size: 11)).foregroundColor(Color.h3Sub(scheme).opacity(0.5))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(Color.h3Card2(scheme).opacity(0.5)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.h3Separator(scheme), lineWidth: 1))

                        ProfileField(icon: "globe", placeholder: lm.s(L.profileCountry), text: $vm.country)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar").font(.system(size: 14)).foregroundColor(Color.h3Orange)
                                Text(lm.s(L.profileAgeRange)).font(.system(size: 14)).foregroundColor(Color.h3Sub(scheme))
                                Spacer()
                                Text("\(Int(vm.ageRange)) \(lm.s(L.profileYears))")
                                    .font(.system(size: 14, weight: .bold)).foregroundColor(Color.h3Orange)
                            }
                            Slider(value: $vm.ageRange, in: 16...80, step: 1).tint(Color.h3Orange)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(Color.h3Card2(scheme)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.h3Separator(scheme), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 12) {
                            Text(lm.s(L.profileChangePassword))
                                .font(.system(size: 13, weight: .bold)).foregroundColor(Color.h3Sub(scheme))
                            H3TextField(placeholder: lm.s(L.profileCurrentPassword),
                                        icon: "lock.fill", text: $vm.currentPassword, isSecure: true)
                            H3TextField(placeholder: lm.s(L.profileNewPassword),
                                        icon: "lock.open.fill", text: $vm.newPassword, isSecure: true)
                            if let err = vm.passwordError {
                                Text(err).font(.system(size: 12)).foregroundColor(.red)
                            }
                            if vm.passwordSuccess {
                                Text(lm.s(L.profilePasswordUpdated))
                                    .font(.system(size: 12)).foregroundColor(Color(hex: "#30D158"))
                            }
                            Button { Task { await vm.changePassword() } } label: {
                                Text(lm.s(L.profileUpdatePassword))
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(Color.h3Orange)
                            }
                        }
                        .padding(16).background(Color.h3Card2(scheme)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.h3Separator(scheme), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(lm.s(L.profileMyInterests))
                                    .font(.system(size: 13, weight: .bold)).foregroundColor(Color.h3Sub(scheme))
                                Spacer()
                                Text("\(vm.selectedInterests.count)/5")
                                    .font(.system(size: 12, weight: .bold)).foregroundColor(Color.h3Orange)
                            }
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(vm.interests) { interest in
                                    let selected = vm.selectedInterests.contains(interest.id)
                                    let disabled = !selected && vm.selectedInterests.count >= 5
                                    Button { vm.toggleInterest(interest.id) } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: interest.icon)
                                                .font(.system(size: 13, weight: .semibold)).frame(width: 18)
                                            Text(interest.displayName)
                                                .font(.system(size: 12, weight: selected ? .bold : .regular))
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .foregroundColor(selected ? .white : (disabled
                                            ? Color.h3Sub(scheme).opacity(0.4) : Color.h3Text(scheme)))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 10).padding(.horizontal, 12)
                                        .background(selected ? Color.h3Orange : Color.h3Card2(scheme))
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .stroke(selected ? Color.h3Orange : Color.h3Separator(scheme), lineWidth: 1))
                                        .opacity(disabled ? 0.5 : 1)
                                    }
                                    .buttonStyle(.plain).disabled(disabled)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                                }
                            }
                        }

                        Divider().padding(.top, 4)

                        VStack(spacing: 12) {
                            if let err = vm.saveError {
                                HStack(spacing: 7) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text(err).font(.system(size: 13))
                                }.foregroundColor(.red)
                            }
                            HStack(spacing: 10) {
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    Task { await vm.saveProfile(router: router) }
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(vm.saveConfirmed ? Color(hex: "#30D158") : Color.h3Orange)
                                            .frame(height: 50)
                                            .animation(.spring(response: 0.3), value: vm.saveConfirmed)
                                        if vm.isSaving {
                                            ProgressView().tint(.white).scaleEffect(0.85)
                                        } else {
                                            Image(systemName: vm.saveConfirmed ? "checkmark" : "square.and.arrow.down.fill")
                                                .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .disabled(vm.isSaving).help(lm.s(L.profileSave))

                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    showLogoutAlert = true
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.h3Card2(scheme)).frame(height: 50)
                                            .overlay(RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.h3Separator(scheme), lineWidth: 1))
                                        Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                            .font(.system(size: 18, weight: .semibold)).foregroundColor(Color.h3Text(scheme))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .help(lm.s(L.profileLogout))

                                Button {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    showDeleteAlert = true
                                } label: {
                                    ZStack {
                                        Circle().fill(Color.red.opacity(0.1)).frame(width: 50, height: 50)
                                            .overlay(Circle().stroke(Color.red.opacity(0.3), lineWidth: 1))
                                        Image(systemName: "trash.fill").font(.system(size: 16)).foregroundColor(.red)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(20).background(Color.h3Card(scheme))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.h3Card(scheme))
        .cornerRadius(20)
        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.06), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20).padding(.bottom, 28)
    }

    // MARK: - Encuesta

    private var surveySection: some View {
        ProfileSectionCard(title: "Encuesta de visita", icon: "text.bubble.fill") {
            VStack(spacing: 20) {
                Text(vm.surveyCompleted
                     ? "Ya compartiste tu experiencia con nosotros. ¡Gracias por tu opinión!"
                     : "Ayúdanos a mejorar respondiendo 6 preguntas rápidas sobre tu visita de hoy.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.h3Sub(scheme))
                    .lineSpacing(4)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showSurvey = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: vm.surveyCompleted ? "checkmark.circle.fill" : "pencil.and.list.clipboard")
                            .font(.system(size: 15, weight: .semibold))
                        Text(vm.surveyCompleted ? "Encuesta contestada" : "Responder encuesta")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        vm.surveyCompleted
                        ? AnyShapeStyle(Color(hex: "#30D158"))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color.h3OrangeLight, Color.h3Orange],
                            startPoint: .leading, endPoint: .trailing))
                    )
                    .cornerRadius(18)
                    .shadow(color: (vm.surveyCompleted ? Color(hex: "#30D158") : Color.h3Orange).opacity(0.4),
                            radius: 12, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(vm.surveyCompleted)
            }
        }
    }

    // MARK: - Resumen

    private var summarySection: some View {
        ProfileSectionCard(title: lm.s(L.profileSummaryTitle), icon: "doc.text.magnifyingglass") {
            VStack(spacing: 20) {
                Text(lm.s(L.profileSummaryDesc))
                    .font(.system(size: 13)).foregroundColor(Color.h3Sub(scheme)).lineSpacing(4)
                SiriButton(label: lm.s(L.profileSummaryGenerate)) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showWrapped = true
                }
            }
        }
    }
}

// MARK: - Componentes

struct ProfileSectionCard<Content: View>: View {
    @Environment(\.colorScheme) var scheme
    let title: String; let icon: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundColor(Color.h3Orange)
                Text(title).font(.system(size: 18, weight: .black)).foregroundColor(Color.h3Text(scheme))
            }.padding(.horizontal, 24)
            content()
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.h3Card(scheme)).cornerRadius(20)
                .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.06), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 20)
        }.padding(.bottom, 28)
    }
}

struct ProfileField: View {
    let icon: String; let placeholder: String
    @Binding var text: String
    @Environment(\.colorScheme) var scheme
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color.h3Orange).frame(width: 20)
            TextField(placeholder, text: $text)
                .font(.system(size: 15)).foregroundColor(Color.h3Text(scheme)).autocorrectionDisabled()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color.h3Card2(scheme)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.h3Separator(scheme), lineWidth: 1))
    }
}

struct GamificationBadgeView: View {
    let badge: GamificationBadge
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    @State private var paintAnimation = false
    @State private var showDetail     = false
    @State private var tapScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if badge.unlocked {
                    Image(badge.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                        .grayscale(badge.isNewlyClaimed && !paintAnimation ? 1.0 : 0.0)
                        .opacity(badge.isNewlyClaimed && !paintAnimation ? 0.5 : 1.0)
                        .scaleEffect(badge.isNewlyClaimed && paintAnimation ? 1.15 : 1.0)
                        .animation(badge.isNewlyClaimed ? .spring(response: 0.6, dampingFraction: 0.5).delay(0.2) : .default, value: paintAnimation)
                } else {
                    Image(badge.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .grayscale(1.0)
                        .opacity(0.25)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
            }
            // Nombre localizado
            Text(badge.displayName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(badge.unlocked ? Color.h3Text(scheme) : Color.h3Sub(scheme).opacity(0.4))
                .multilineTextAlignment(.center).lineLimit(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .background(Color.clear)
        .scaleEffect(tapScale)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { tapScale = 0.88 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { tapScale = 1.0 }
                showDetail = true
            }
        }
        .fullScreenCover(isPresented: $showDetail) {
            BadgeDetailView(badge: badge) { showDetail = false }
                .environmentObject(lm)
        }
        .onAppear {
            if badge.isNewlyClaimed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { paintAnimation = true }
            }
        }
    }
}

// MARK: - Siri Button

struct SiriButton: View {
    let label: String
    let action: () -> Void
    @State private var isPressed = false
    @State private var animate   = false
    var body: some View {
        Button { action() } label: {
            ZStack {
                AppleIntelligenceBackground(animate: animate)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.18), .clear, .white.opacity(0.06)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").font(.system(size: 15, weight: .semibold))
                    Text(label).font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white).shadow(color: .black.opacity(0.18), radius: 4, y: 1)
            }
            .frame(maxWidth: .infinity).frame(height: 56)
            .shadow(color: Color(hex: "#FF6B9D").opacity(0.35), radius: 14, y: 6)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.58), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in isPressed = true }.onEnded { _ in isPressed = false })
        .onAppear { animate = true }
    }
}

struct AppleIntelligenceBackground: View {
    let animate: Bool
    private let c1 = Color(red: 1.00, green: 0.42, blue: 0.62)
    private let c2 = Color(red: 1.00, green: 0.70, blue: 0.25)
    private let c3 = Color(red: 0.40, green: 0.60, blue: 1.00)
    private let c4 = Color(red: 0.60, green: 0.30, blue: 1.00)
    private let c5 = Color(red: 0.20, green: 0.85, blue: 0.75)
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Ellipse().fill(c1).frame(width: w*0.75, height: h*2.2)
                    .offset(x: animate ? -w*0.05 : -w*0.20, y: animate ? h*0.10 : h*0.30)
                    .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: animate).blur(radius: 14)
                Ellipse().fill(c2).frame(width: w*0.70, height: h*2.0)
                    .offset(x: animate ? w*0.28 : w*0.08, y: animate ? -h*0.15 : -h*0.05)
                    .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(0.6), value: animate).blur(radius: 12)
                Ellipse().fill(c3).frame(width: w*0.55, height: h*1.8)
                    .offset(x: animate ? w*0.15 : -w*0.10, y: animate ? h*0.20 : h*0.00)
                    .animation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true).delay(1.2), value: animate).blur(radius: 16).opacity(0.85)
                Ellipse().fill(c4).frame(width: w*0.65, height: h*2.0)
                    .offset(x: animate ? -w*0.15 : w*0.10, y: animate ? -h*0.10 : h*0.15)
                    .animation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true).delay(0.3), value: animate).blur(radius: 18).opacity(0.70)
                Ellipse().fill(c5).frame(width: w*0.45, height: h*1.6)
                    .offset(x: animate ? w*0.22 : -w*0.05, y: animate ? -h*0.05 : h*0.20)
                    .animation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true).delay(1.8), value: animate).blur(radius: 14).opacity(0.75)
            }
        }
        .drawingGroup()
    }
}

// MARK: - Staggered animation helper

extension View {
    func staggered(_ appeared: Bool, delay: Double) -> some View {
        self.opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: appeared)
    }
}

#Preview {
    ProfileView()
        .environmentObject({
            let r = AppRouter(); r.userName = "Joel García"; r.userEmail = "joel@horno3.mx"; return r
        }())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
