// LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var lm: LocalizationManager
    @StateObject private var vm = LoginViewModel()
    @Environment(\.colorScheme) var scheme
    @FocusState private var focused: LoginField?
    @State private var appeared = false

    enum LoginField { case name, lastName, email, password }

    var body: some View {
        ZStack {
            Color.h3BG(scheme).ignoresSafeArea()

            Circle()
                .fill(Color.h3Orange.opacity(scheme == .dark ? 0.13 : 0.07))
                .frame(width: 340).offset(x: 160, y: -200)
                .blur(radius: 70).ignoresSafeArea()
            Circle()
                .fill(Color.h3Orange.opacity(scheme == .dark ? 0.05 : 0.03))
                .frame(width: 280).offset(x: -130, y: 320)
                .blur(radius: 90).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Logo ──────────────────────────────────────
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.h3Orange.opacity(0.15))
                                .frame(width: 90, height: 90)
                            Image("horno3")
                                .resizable().scaledToFit()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        }
                        .shadow(color: Color.h3Orange.opacity(0.35), radius: 20)

                        Text("horno³")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(Color.h3Text(scheme))
                            .tracking(1.5)

                        Text(lm.s(L.appSubtitle))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.h3Orange)
                            .tracking(5)
                    }
                    .padding(.top, 60)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05), value: appeared)

                    // ── Card ──────────────────────────────────────
                    VStack(spacing: 0) {

                        // Título
                        VStack(spacing: 6) {
                            Text(vm.mode == .register ? lm.s(L.loginTabRegister) : lm.s(L.loginTabSignin))
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(Color.h3Text(scheme))
                            Text(vm.mode == .register ? lm.s(L.loginSubtitleRegister) : lm.s(L.loginSubtitleSignin))
                                .font(.system(size: 13))
                                .foregroundColor(Color.h3Sub(scheme))
                        }
                        .padding(.bottom, 24)

                        // ── Campos ────────────────────────────────
                        VStack(spacing: 12) {
                            if vm.mode == .register {
                                HStack(spacing: 10) {
                                    H3TextField(placeholder: lm.s(L.loginFieldName),
                                                icon: "person.fill", text: $vm.name, isSecure: false)
                                    .focused($focused, equals: .name)

                                    H3TextField(placeholder: lm.s(L.loginFieldLastName),
                                                icon: "person.fill", text: $vm.lastName, isSecure: false)
                                    .focused($focused, equals: .lastName)
                                }
                                .transition(.push(from: .top).combined(with: .opacity))
                            }

                            H3TextField(placeholder: lm.s(L.loginFieldEmail),
                                        icon: "envelope.fill", text: $vm.email, isSecure: false)
                            .focused($focused, equals: .email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)

                            H3TextField(placeholder: lm.s(L.loginFieldPassword),
                                        icon: "lock.fill", text: $vm.password, isSecure: true)
                            .focused($focused, equals: .password)
                        }
                        .animation(.spring(response: 0.35), value: vm.mode)

                        // ── Error ─────────────────────────────────
                        if let err = vm.errorMessage {
                            HStack(spacing: 7) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 13))
                                Text(err).font(.system(size: 13))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // ── Botón principal ───────────────────────
                        Button {
                            focused = nil
                            vm.authenticate(router: router, lm: lm)
                        } label: {
                            ZStack {
                                if vm.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(vm.mode == .register ? lm.s(L.loginCtaRegister) : lm.s(L.loginCtaSignin))
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(
                                LinearGradient(colors: [Color.h3OrangeLight, Color.h3Orange],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.h3Orange.opacity(0.35), radius: 10, y: 4)
                        }
                        .disabled(vm.isLoading)
                        .padding(.top, 20)

                        // ── Cambiar modo ──────────────────────────
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                vm.mode = vm.mode == .register ? .login : .register
                                vm.errorMessage = nil
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text(vm.mode == .register ? lm.s(L.loginAlreadyHaveAccount) : lm.s(L.loginNoAccount))
                                    .foregroundColor(Color.h3Sub(scheme))
                                Text(vm.mode == .register ? lm.s(L.loginTabSignin) : lm.s(L.loginTabRegister))
                                    .foregroundColor(Color.h3Orange)
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 14))
                        }
                        .padding(.top, 20)
                    }
                    .padding(24)
                    .background(Color.h3Card(scheme))
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.07), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.12), value: appeared)

                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .onTapGesture { focused = nil }
        .animation(.easeInOut(duration: 0.2), value: vm.errorMessage)
    }
}

#Preview {
    LoginView()
        .environmentObject(AppRouter())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
