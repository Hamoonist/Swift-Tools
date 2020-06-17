//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

extension Color {
    private func toUIColor0() -> UIColor? {
        switch self {
            case .clear:
                return .clear
            case .black:
                return .black
            case .white:
                return .white
            case .gray:
                return .systemGray
            case .red:
                return .systemRed
            case .green:
                return .systemGreen
            case .blue:
                return .systemBlue
            case .orange:
                return .systemOrange
            case .yellow:
                return .systemYellow
            case .pink:
                return .systemPink
            case .primary:
                return .label // FIXME?
            case .secondary:
                return .secondaryLabel // FIXME?
            default:
                return nil
        }
    }
    
    private func toUIColor1() -> UIColor? {
        switch self {
            case .clear:
                return UIColor.clear
            case .black:
                return UIColor.black
            case .white:
                return UIColor.white
            case .gray:
                return UIColor.systemGray
            case .red:
                return UIColor.systemRed
            case .green:
                return UIColor.systemGreen
            case .blue:
                return UIColor.systemBlue
            case .orange:
                return UIColor.systemOrange
            case .yellow:
                return UIColor.systemYellow
            case .pink:
                return UIColor.systemPink
            case .purple:
                return UIColor.systemPurple
            case .primary:
                return UIColor.label
            case .secondary:
                return UIColor.secondaryLabel
            default:
                return nil
        }
    }
    
    private func toUIColor2() -> UIColor? {
        let children = Mirror(reflecting: self).children
        let _provider = children.filter { $0.label == "provider" }.first
        
        guard let provider = _provider?.value else {
            return nil
        }
        
        let providerChildren = Mirror(reflecting: provider).children
        let _base = providerChildren.filter { $0.label == "base" }.first
        
        guard let base = _base?.value else {
            return nil
        }
        
        if String(describing: type(of: base)) == "NamedColor" {
            let baseMirror = Mirror(reflecting: base)
            
            if let name = baseMirror.descendant("name") as? String {
                let bundle = baseMirror.descendant("bundle") as? Bundle
                if let color = UIColor(named: name, in: bundle, compatibleWith: nil) {
                    return color
                }
            }
        }
        
        var baseValue: String = ""
        
        dump(base, to: &baseValue)
        
        guard let firstLine = baseValue.split(separator: "\n").first, let hexString = firstLine.split(separator: " ")[1] as Substring? else {
            return nil
        }
        
        return UIColor(hexadecimal: hexString.trimmingCharacters(in: .newlines))
    }
    
    public func toUIColor3() -> UIColor? {
        switch description {
            case "clear":
                return UIColor.clear
            case "black":
                return UIColor.black
            case "white":
                return UIColor.white
            case "gray":
                return UIColor.systemGray
            case "red":
                return UIColor.systemRed
            case "green":
                return UIColor.systemGreen
            case "blue":
                return UIColor.systemBlue
            case "orange":
                return UIColor.systemOrange
            case "yellow":
                return UIColor.systemYellow
            case "pink":
                return UIColor.systemPink
            case "purple":
                return UIColor.systemPurple
            case "primary":
                return UIColor.label
            case "secondary":
                return UIColor.secondaryLabel
            default:
                return nil
        }
    }
    
    public func toUIColor() -> UIColor? {
        nil
            ?? toUIColor0()
            ?? toUIColor1()
            ?? toUIColor2()
            ?? toUIColor3()
    }
}

#endif
