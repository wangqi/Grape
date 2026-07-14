import SwiftUI

public struct _GraphRenderingContext<NodeID: Hashable> {
    @usableFromInline
    enum ViewResolvingState<V> where V: View {
        case pending(V)
        case resolved(V, CGImage?)
    }

    @usableFromInline
    internal var resolvedTexts: [GraphRenderingStates<NodeID>.StateID: String] = [:]

    @usableFromInline
    internal var resolvedViews:
        [GraphRenderingStates<NodeID>.StateID: ViewResolvingState<AnyView>] = [:]

    @usableFromInline
    internal var textOffsets:
        [GraphRenderingStates<NodeID>.StateID: (alignment: Alignment, offset: SIMD2<Double>)] = [:]

    @usableFromInline
    internal var symbols: [String: ViewResolvingState<Text>] = [:]

    @usableFromInline
    internal var nodeOperations: [RenderOperation<NodeID>.Node] = []

    /// A lookup table for the hit area of each node (width * height).
    @usableFromInline
    internal var nodeHitSizeAreaLookup: [NodeID: Double] = [:]

    @usableFromInline
    internal var linkOperations: [RenderOperation<NodeID>.Link] = []

    @inlinable
    internal init() {

    }

    @usableFromInline
    internal var states = GraphRenderingStates<NodeID>()

    @inlinable
    func updateEnvironment(with newEnvironment: EnvironmentValues) {

    }
}

extension _GraphRenderingContext.ViewResolvingState {
    @MainActor
    @inlinable
    func resolve(in environment: EnvironmentValues) -> CGImage? {
        switch self {
        case .pending(let view):
            let cgImage = view.environment(\.self, environment).toCGImage(with: environment)
            // debugPrint("[RESOLVE VIEW]")
            return cgImage
        case .resolved(_, let cgImage):
            return cgImage
        }
    }
}

extension _GraphRenderingContext: Equatable {
    // Also compare the annotation KEY sets (which nodes/links carry a label), not just
    // node/link operations, so a label-set change that keeps the same nodes/edges is no
    // longer considered equal. That lets a consumer drive a zoom-reactive label set through
    // conditional `.annotation` attachment and have Grape revive (re-render labels) on it.
    // Keys only (StateID is Hashable) — cheap; the resolved CGImages/texts are NOT compared.
    // wangqi modified 2026-07-13
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.nodeOperations == rhs.nodeOperations
            && lhs.linkOperations == rhs.linkOperations
            && Set(lhs.resolvedViews.keys) == Set(rhs.resolvedViews.keys)
            && Set(lhs.resolvedTexts.keys) == Set(rhs.resolvedTexts.keys)
    }
}

extension _GraphRenderingContext {
    @inlinable
    internal var nodes: [NodeMark<NodeID>] {
        nodeOperations.map(\.mark)
    }

    @inlinable
    internal var edges: [LinkMark<NodeID>] {
        linkOperations.map(\.mark)
    }
}
