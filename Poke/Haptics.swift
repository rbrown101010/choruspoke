import UIKit

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    static func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func heavyTap() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func sheetOpen() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
    }
    
    static func buttonPress() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
    }
    
    static func navigate() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
    }
}
