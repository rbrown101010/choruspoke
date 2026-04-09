import UIKit

enum Haptics {
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private static let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func tap() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }

    static func lightTap() {
        lightImpact.prepare()
        lightImpact.impactOccurred()
    }

    static func heavyTap() {
        heavyImpact.prepare()
        heavyImpact.impactOccurred()
    }

    static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    static func carouselSnap() {
        rigidImpact.prepare()
        rigidImpact.impactOccurred(intensity: 0.94)
    }

    static func success() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }

    static func sheetOpen() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred(intensity: 0.72)
    }

    static func buttonPress() {
        rigidImpact.prepare()
        rigidImpact.impactOccurred(intensity: 0.66)
    }

    static func mainButton() {
        heavyImpact.prepare()
        heavyImpact.impactOccurred(intensity: 0.92)
    }

    static func navigate() {
        softImpact.prepare()
        softImpact.impactOccurred(intensity: 0.8)
    }
}
