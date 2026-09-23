import ForceSimulation
import SwiftUI

public enum GraphDragState<NodeID: Hashable> {
    case node(NodeID)
    case background(SIMD2<Double>)
}

#if !os(tvOS)

@usableFromInline
struct GraphDragModifier<NodeID: Hashable>: ViewModifier {

    @inlinable
    public var dragGesture: some Gesture {
        DragGesture(
            minimumDistance: Self.minimumDragDistance,
            coordinateSpace: .local
        )
        .onChanged(onChanged)
        .onEnded(onEnded)
    }

    @inlinable
    public func body(content: Content) -> some View {
        content.gesture(dragGesture)
    }

    // Xcode 27 / Swift 6.4 rejects @inlinable on a @State property: the macro-generated
    // storage `_dragState` is private and so cannot be touched from an inlinable accessor.
    // The enclosing struct is only @usableFromInline, so cross-module inlining buys nothing.
    // wangqi modified 2026-09-15
    @State
    public var dragState: GraphDragState<NodeID>?

    @usableFromInline
    let graphProxy: GraphProxy

    @usableFromInline
    let action: ((GraphDragState<NodeID>?) -> Void)?

    // Xcode 27 Release archive: an @inlinable init implicitly runs the @State macro's init
    // accessor for dragState, which has non-public linkage ("function has wrong linkage to be
    // called from init(graphProxy:action:)"). @usableFromInline keeps it callable from inlinable code.
    // wangqi modified 2026-09-22
    @usableFromInline
    init(
        graphProxy: GraphProxy,
        action: ((GraphDragState<NodeID>?) -> Void)? = nil
    ) {
        self.graphProxy = graphProxy
        self.action = action
    }

    @inlinable
    static var minimumDragDistance: CGFloat { 3.0 }

    @inlinable
    static var minimumAlphaAfterDrag: CGFloat { 0.5 }

    @inlinable
    public func onEnded(
        value: DragGesture.Value
    ) {
        if dragState != nil {
            switch dragState {
            case .node(let nodeID):
                graphProxy.setNodeFixation(nodeID: nodeID, fixation: nil)
            case .background(let start):
                let delta = value.location.simd - start
                graphProxy.modelTransform.translate += delta
                dragState = .background(value.location.simd)
            case .none:
                break
            }
            dragState = .none
        }

        if let action {
            action(dragState)
        }
    }

    @inlinable
    public func onChanged(
        value: DragGesture.Value
    ) {
        if dragState == nil {
            if let nodeID = graphProxy.node(of: NodeID.self, at: value.startLocation) {
                dragState = .node(nodeID)
                graphProxy.setNodeFixation(nodeID: nodeID, fixation: value.startLocation)
            } else {
                dragState = .background(value.location.simd)
            }
        } else {
            switch dragState {
            case .node(let nodeID):
                graphProxy.setNodeFixation(nodeID: nodeID, fixation: value.location)
            case .background(let start):
                let delta = value.location.simd - start
                graphProxy.modelTransform.translate += delta
                dragState = .background(value.location.simd)
            case .none:
                break
            }
        }

        if let action {
            action(dragState)
        }
    }
}

extension View {

    /// Attach a drag gesture to an overlay or a background view created with ``SwiftUICore/View/graphOverlay(alignment:content:)``.
    /// - Parameters:
    ///  - proxy: The graph proxy that provides the graph context.
    ///  - type: The type of the node ID. The drag gesture will look for the node ID of this type.
    ///  - action: The action to perform when the drag gesture changes.
    @inlinable
    public func withGraphDragGesture<NodeID>(
        _ proxy: GraphProxy,
        of type: NodeID.Type,
        action: ((GraphDragState<NodeID>?) -> Void)? = nil
    ) -> some View {
        self.modifier(GraphDragModifier(graphProxy: proxy, action: action))
    }
}

#endif