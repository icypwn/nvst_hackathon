import SwiftUI

public enum GlassMaterial {
    case clear
    case thin
    case regular
    case thick
    case ultra
    
    var blurRadius: CGFloat {
        switch self {
        case .clear: return 0
        case .thin: return 10
        case .regular: return 25
        case .thick: return 45
        case .ultra: return 70
        }
    }
    
    var opacity: Double {
        switch self {
        case .clear: return 0
        case .thin: return 0.3
        case .regular: return 0.55
        case .thick: return 0.75
        case .ultra: return 0.9
        }
    }
}

public struct GlassEffectConfiguration {
    public var material: GlassMaterial
    public var tint: Color?
    public var isInteractive: Bool
    
    public static let standard = GlassEffectConfiguration(material: .regular, tint: nil, isInteractive: false)
    public static let clear = GlassEffectConfiguration(material: .clear, tint: nil, isInteractive: false)
    
    public func tint(_ color: Color) -> GlassEffectConfiguration {
        var copy = self
        copy.tint = color
        return copy
    }
    
    public func interactive() -> GlassEffectConfiguration {
        var copy = self
        copy.isInteractive = true
        return copy
    }
}

public struct GlassEffectContainer<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
    }
}

struct GlassEffectModifier<S: Shape>: ViewModifier {
    let config: GlassEffectConfiguration
    let shape: S
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if config.material != .clear {
                        shape
                            .fill(config.tint?.opacity(0.2) ?? Color(white: 0.1).opacity(config.material.opacity))
                            .background(
                                shape
                                    .fill(.ultraThinMaterial)
                                    .blur(radius: config.material.blurRadius)
                            )
                            .overlay(
                                shape
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.15),
                                                .white.opacity(0.05),
                                                .black.opacity(0.05),
                                                .white.opacity(0.08)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
                    }
                }
            )
    }
}

public extension View {
    func glassEffect<S: Shape>(_ material: GlassMaterial = .regular, in shape: S) -> some View {
        self.modifier(GlassEffectModifier(config: .init(material: material, tint: nil, isInteractive: false), shape: shape))
    }
    
    func glassEffect<S: Shape>(_ config: GlassEffectConfiguration, in shape: S) -> some View {
        self.modifier(GlassEffectModifier(config: config, shape: shape))
    }
    
    func glassEffectID<ID: Hashable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }
}
