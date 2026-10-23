import SwiftUI

/// Pane frames for the unfolded iPhone Duo: Home and everything pushed over it
/// on the leading side of the fold, Your Progress on the trailing side, so no
/// card straddles the crease. `nil` keeps the single column (every ordinary
/// iPhone, the folded Duo, and the unfolded Duo held in portrait, where each
/// half would be too narrow).
struct UnfoldedSplit: Equatable, Sendable {
    var primaryWidth: CGFloat
    var secondaryX: CGFloat
    var secondaryWidth: CGFloat

    /// Narrowest pane that still fits the phone layouts of Home and a drill.
    static let minimumPaneWidth: CGFloat = 360

    /// - Parameters:
    ///   - width: the container's width.
    ///   - fold: the vertical fold's leading and trailing edge in the same
    ///     coordinate space, or `nil` when the system reports none.
    static func make(width: CGFloat, isRegularWidth: Bool, fold: ClosedRange<CGFloat>?) -> UnfoldedSplit? {
        guard isRegularWidth, width >= minimumPaneWidth * 2 else { return nil }
        if let fold,
           fold.lowerBound >= minimumPaneWidth,
           width - fold.upperBound >= minimumPaneWidth {
            return UnfoldedSplit(
                primaryWidth: fold.lowerBound,
                secondaryX: fold.upperBound,
                secondaryWidth: width - fold.upperBound
            )
        }
        let half = (width / 2).rounded(.down)
        return UnfoldedSplit(primaryWidth: half, secondaryX: half, secondaryWidth: width - half)
    }
}

/// What the split is measured from: the container's width and its fold.
struct PaneGeometry: Equatable, Sendable {
    var width: CGFloat
    var fold: ClosedRange<CGFloat>?
}

extension GeometryProxy {
    /// The vertical fold's horizontal extent in this proxy's space. Inactive
    /// folds count too, so the panes don't jump while the device opens.
    func verticalFold() -> ClosedRange<CGFloat>? {
        guard #available(iOS 27.1, *) else { return nil }
        let fold = reservedRegions(kind: .division, options: .includeInactive)
            .map(\.frame)
            .first { $0.height > $0.width && $0.minX > 0 && $0.maxX < size.width }
        guard let fold else { return nil }
        return fold.minX...fold.maxX
    }
}

extension View {
    /// iOS 27.1 can move a stack's back button and toolbar into a vertical bar
    /// on its trailing edge, which in the leading pane lands beside the fold
    /// with the title still leading. A pane keeps the phone's horizontal bar,
    /// back button leading. Folded, the system default is unchanged.
    @ViewBuilder
    func horizontalToolbarInPane(_ isPane: Bool) -> some View {
        if #available(iOS 27.1, *) {
            toolbarVerticalBehavior(isPane ? .disabled : .automatic)
        } else {
            self
        }
    }
}

/// Home's training tiles: one row on a phone, where the row scrolls and the
/// next tile peeks in from the screen edge, or equal columns in an unfolded
/// pane, where a peek would be a sliver cut off at the fold. The same layout
/// either way, so folding moves the tiles instead of rebuilding them (and
/// anything pushed from one stays pushed).
struct TrainingTileLayout: Layout {
    /// The width to wrap within, or `nil` for the single scrolling row.
    var wrapWidth: CGFloat?
    var spacing: CGFloat = 10

    /// Narrowest tile that still sets a two-line title like "Exam Warm-Up".
    static let minimumTileWidth: CGFloat = 120

    static func columns(for width: CGFloat, spacing: CGFloat = 10) -> Int {
        max(1, Int(((width + spacing) / (minimumTileWidth + spacing)).rounded(.down)))
    }

    /// Each tile's frame: a row of natural sizes, or columns that share
    /// `wrapWidth` exactly, row after row.
    static func frames(for sizes: [CGSize], wrapWidth: CGFloat?, spacing: CGFloat = 10) -> [CGRect] {
        guard let wrapWidth else {
            var x: CGFloat = 0
            return sizes.map { size in
                defer { x += size.width + spacing }
                return CGRect(origin: CGPoint(x: x, y: 0), size: size)
            }
        }
        let columns = columns(for: wrapWidth, spacing: spacing)
        let tileWidth = (wrapWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var frames: [CGRect] = []
        var y: CGFloat = 0
        for rowStart in stride(from: 0, to: sizes.count, by: columns) {
            let row = sizes[rowStart..<min(rowStart + columns, sizes.count)]
            let height = row.map(\.height).max() ?? 0
            for (column, _) in row.enumerated() {
                let x = CGFloat(column) * (tileWidth + spacing)
                frames.append(CGRect(x: x, y: y, width: tileWidth, height: height))
            }
            y += height + spacing
        }
        return frames
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let frames = Self.frames(for: subviews.map { $0.sizeThatFits(.unspecified) }, wrapWidth: wrapWidth, spacing: spacing)
        let bounds = frames.reduce(CGRect.null) { $0.union($1) }
        return bounds.isNull ? .zero : CGSize(width: bounds.maxX, height: bounds.maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = Self.frames(for: subviews.map { $0.sizeThatFits(.unspecified) }, wrapWidth: wrapWidth, spacing: spacing)
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
}
