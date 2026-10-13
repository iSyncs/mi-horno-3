// DesignSystem.swift — horno³ Brand Tokens

import SwiftUI

// MARK: - Brand Colors (Official horno3 palette)
extension Color {
    // Primary orange (horno3 brand)
    static let h3Orange      = Color(hex: "#F05A28")
    static let h3OrangeDark  = Color(hex: "#C03D10")
    static let h3OrangeLight = Color(hex: "#FF7A48")

    // Neutral backgrounds
    static let h3Black       = Color(hex: "#0A0A0A")
    static let h3Dark        = Color(hex: "#141414")
    static let h3DarkCard    = Color(hex: "#1E1E1E")
    static let h3DarkCard2   = Color(hex: "#282828")

    static let h3LightBG     = Color(hex: "#F5F4F2")
    static let h3LightCard   = Color(hex: "#FFFFFF")
    static let h3LightCard2  = Color(hex: "#F0EFED")

    // Text
    static let h3TextOnDark  = Color(hex: "#F7F4F0")
    static let h3TextOnLight = Color(hex: "#111111")
    static let h3SubDark     = Color(hex: "#888888")
    static let h3SubLight    = Color(hex: "#666666")

    // Semantic adaptive
    static func h3BG(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? h3Black : h3LightBG
    }
    static func h3Card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? h3DarkCard : h3LightCard
    }
    static func h3Card2(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? h3DarkCard2 : h3LightCard2
    }
    static func h3Text(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? h3TextOnDark : h3TextOnLight
    }
    static func h3Sub(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? h3SubDark : h3SubLight
    }
    static func h3Separator(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.07)
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6:
            (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8:
            (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default:
            (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Corner radius helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

// MARK: - Card Modifier
struct H3Card: ViewModifier {
    @Environment(\.colorScheme) var scheme
    func body(content: Content) -> some View {
        content
            .background(Color.h3Card(scheme))
            .cornerRadius(18)
            .shadow(
                color: scheme == .dark
                    ? Color.black.opacity(0.3)
                    : Color.black.opacity(0.06),
                radius: 12, x: 0, y: 4
            )
    }
}
extension View {
    func h3Card() -> some View { modifier(H3Card()) }
}

// MARK: - Orange Button
struct H3OrangeButton: ViewModifier {
    var fullWidth: Bool = true
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 54)
            .padding(.horizontal, fullWidth ? 0 : 28)
            .background(
                LinearGradient(
                    colors: [Color.h3OrangeLight, Color.h3Orange],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(16)
            .shadow(color: Color.h3Orange.opacity(0.35), radius: 10, y: 4)
    }
}
extension View {
    func h3OrangeButton(fullWidth: Bool = true) -> some View {
        modifier(H3OrangeButton(fullWidth: fullWidth))
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let title: String
    @Environment(\.colorScheme) var scheme
    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .black))
            .foregroundColor(Color.h3Text(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
    }
}
