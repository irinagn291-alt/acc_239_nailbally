import SwiftUI

/// Role: Felt. Catalog names and chrome surfaces for tent art. Views do not hard-code hex or fonts.
enum TentStage {
    static let emptyHome = "nbl_EmptyHome"
    static let emptyList = "nbl_EmptyList"
    static let card = "nbl_CardBackdrop"
    static let control = "nbl_ControlFace"
    static let twist = "nbl_TwistHero"
    static let success = "nbl_SuccessMark"
    static let header = "nbl_HeaderDecor"
    static let splash = "nbl_Splash"
}

/// Role: Felt. Wide banner accent above the arena. Decorative; VoiceOver skips it.
struct TentHeaderBand: View {
    var body: some View {
        Group {
            if let art = TentArt.image(TentStage.header) {
                art.resizable().scaledToFill()
            } else {
                TentInk.Palette.surface
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: TentInk.space(5))
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Role: Felt. Brief success stamp after a nail seats.
struct TentFlash: View {
    var visible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let art = TentArt.image(TentStage.success) {
                art.resizable().scaledToFit()
            } else {
                Circle().stroke(TentInk.Palette.accent, lineWidth: 3)
            }
        }
        .frame(width: 128, height: 128)
        .opacity(visible ? 1 : 0)
        .animation(reduceMotion ? nil : TentInk.motion, value: visible)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Role: Felt. Low-contrast canvas behind a primary card so ink stays readable.
struct TentCardBackdrop: View {
    var body: some View {
        Group {
            if let art = TentArt.image(TentStage.card) {
                art.resizable().scaledToFill().opacity(0.28)
            } else {
                TentInk.Palette.surface
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
