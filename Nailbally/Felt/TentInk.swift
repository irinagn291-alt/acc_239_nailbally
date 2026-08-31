import SwiftUI
import UIKit

/// Role: Felt. Typed tent tokens. SF Pro via `.system` only; hex lives in the catalog.
enum TentInk {
    static let face = "SF Pro"
    static let space: CGFloat = 8
    static let tap: CGFloat = 44
    static let radius: CGFloat = 4
    static let motion: Animation = .easeInOut(duration: 0.28)

    enum Palette {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let accent = Color("accent")
        static let muted = Color("muted")
    }

    enum Canvas {
        static let background = UIColor(named: "background") ?? UIColor(white: 0.06, alpha: 1)
        static let surface = UIColor(named: "surface") ?? UIColor(white: 0.12, alpha: 1)
        static let ink = UIColor(named: "ink") ?? UIColor(white: 0.92, alpha: 1)
        static let accent = UIColor(named: "accent") ?? UIColor(white: 0.7, alpha: 1)
        static let muted = UIColor(named: "muted") ?? UIColor(white: 0.55, alpha: 1)
    }

    enum Step: CaseIterable {
        case display
        case title
        case body
        case caption
        case figure
        case footnote

        var font: Font {
            switch self {
            case .display: .system(.largeTitle).weight(.semibold)
            case .title: .system(.title2).weight(.semibold)
            case .body: .system(.body)
            case .caption: .system(.caption)
            case .figure: .system(.title3).weight(.semibold)
            case .footnote: .system(.footnote)
            }
        }
    }

    static func space(_ units: Int) -> CGFloat {
        space * CGFloat(units)
    }
}

enum TentFigures {
    private static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let keyDigits: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    static func count(_ value: Int) -> String {
        whole.string(from: NSNumber(value: value)) ?? "0"
    }

    static func nightKey(_ key: NightKey) -> String {
        keyDigits.string(from: NSNumber(value: key.rawValue)) ?? "—"
    }

    static func nightTitle(_ key: NightKey, calendar: Calendar = .current) -> String {
        guard let date = key.startOfDay(calendar: calendar) else {
            return nightKey(key)
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

enum TentArt {
    @MainActor
    static func image(_ name: String) -> Image? {
        if UIImage(named: name) != nil {
            return Image(name)
        }
        return nil
    }
}

extension View {
    func tentText(_ step: TentInk.Step) -> some View {
        font(step.font)
            .foregroundStyle(TentInk.Palette.ink)
    }

    func tentHit() -> some View {
        frame(minWidth: TentInk.tap, minHeight: TentInk.tap)
            .contentShape(Rectangle())
    }

    func tentPanel() -> some View {
        background(TentInk.Palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: TentInk.radius)
                    .stroke(TentInk.Palette.ink.opacity(0.22), lineWidth: 1)
            )
    }
}
