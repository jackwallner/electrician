import SwiftUI

/// A `ScrollView` that CENTERS its content when the content is shorter than
/// the viewport, and scrolls exactly like a plain one when it is taller.
///
/// Drills are scroll views because a graded question with its coaching note can
/// outgrow an iPhone. On an iPad that same question fills a third of the screen
/// and a bare `ScrollView` pins it to the top, leaving a field of empty cream
/// under it — which is what the 1.2 iPad screenshots showed.
///
/// The mechanic is `minHeight`, not `height`: content taller than the viewport
/// keeps its natural size and scrolls, so nothing about the iPhone layout, the
/// answer-glow headroom, or `scrollTo` changes.
struct CenteringScrollView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                content()
                    // maxWidth as well as minHeight. A plain ScrollView centres
                    // narrow content across the scroll axis for you; once the
                    // content carries an explicit frame it stops doing that and
                    // the whole question slides to the leading edge.
                    .frame(
                        maxWidth: .infinity,
                        minHeight: viewport.size.height,
                        alignment: .center
                    )
            }
        }
    }
}

/// Exclude partially clipped elements until scrolling reveals them fully.
struct ScrollAccessibilityVisibility: ViewModifier {
    let viewport: CGRect
    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
            .accessibilityHidden(isClipped)
    }

    private var isClipped: Bool {
        guard !viewport.isEmpty, !frame.isEmpty, frame.height <= viewport.height else { return false }
        return frame.intersects(viewport) && (frame.minY < viewport.minY || frame.maxY > viewport.maxY)
    }
}
