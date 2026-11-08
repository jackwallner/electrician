import SwiftUI
import UIKit
import XCTest
@testable import Electrician

/// Under Reduce Motion every `Theme.Motion` token is `.linear(duration: 0)`.
/// The flashcard fling only grades and advances the deck in its
/// `withAnimation` completion, so if a zero-length animation never completed,
/// a Reduce Motion user could not get past the first card.
@MainActor
final class ReducedMotionCompletionTests: XCTestCase {
    private final class Model: ObservableObject {
        @Published var offset: CGFloat = 0
        var completed = false
    }

    private struct Probe: View {
        @ObservedObject var model: Model
        var body: some View {
            Color.blue.frame(width: 40, height: 40).offset(x: model.offset)
        }
    }

    private var window: UIWindow?

    override func tearDown() async throws {
        window?.isHidden = true
        window = nil
        try await super.tearDown()
    }

    func testZeroLengthAnimationStillRunsItsCompletion() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let model = Model()
        let w = UIWindow(windowScene: scene)
        w.rootViewController = UIHostingController(rootView: Probe(model: model))
        w.makeKeyAndVisible()
        window = w
        try? await Task.sleep(nanoseconds: 300_000_000)

        withAnimation(.linear(duration: 0)) {
            model.offset = 300
        } completion: {
            model.completed = true
        }

        let deadline = Date().addingTimeInterval(3)
        while !model.completed, Date() < deadline {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertTrue(model.completed, "A zero-length animation never ran its completion, so the Reduce Motion fling would hang")
    }
}
