import Observation

// public typealias ForceDirectedGraphState = ForceDirectedGraphMixedState<Void>

// extension ForceDirectedGraphMixedState where Mixin == Void {
//     @inlinable
//     convenience init(
//         initialIsRunning: Bool = true,
//         initialModelTransform: ViewportTransform = .identity
//     ) {
//         self.init(
//             initialMixin: (),
//             initialIsRunning: initialIsRunning,
//             initialModelTransform: initialModelTransform
//         )
//     }
// }

public enum Ticks: Sendable {
    case untilReachingAlpha(Double?)
    case iteration(Int)
    
    @inlinable
    public static var zero: Self {
        .iteration(0)
    }
    
    @inlinable
    public static var untilStable: Self {
        .untilReachingAlpha(nil)
    }
}

public class ForceDirectedGraphState: Observation.Observable {

    @usableFromInline
    internal var ticksOnAppear: Ticks

    @usableFromInline
    internal var _$modelTransform: ViewportTransform

    @usableFromInline
    internal var _$isRunning: Bool

    // scale contents with zoom // wangqi modified 2026-07-09
    // Opt-in: when true, the render loop multiplies node symbols and their annotations by the
    // viewport zoom scale so labels shrink/grow with the layout (Knowledge Wiki graph). Defaults
    // false so every other Grape graph (e.g. the Writer character web) is byte-identical. Read
    // every frame in the render loop; a plain stored property (no observation registrar needed).
    public var scaleContentsWithZoom: Bool = false

    @inlinable
    public var modelTransform: ViewportTransform {
        get {
            _reg.access(self, keyPath: \.modelTransform)
            return _$modelTransform
        }
        set {
            _reg.withMutation(of: self, keyPath: \.modelTransform) {
                _$modelTransform = newValue
            }
        }
    }

    @inlinable
    public var isRunning: Bool {
        get {
            _reg.access(self, keyPath: \.isRunning)
            return _$isRunning
        }
        set {
            _reg.withMutation(of: self, keyPath: \.isRunning) {
                _$isRunning = newValue
            }
        }
    }

    @inlinable
    public init(
        initialIsRunning: Bool = true,
        initialModelTransform: ViewportTransform = .identity,
        ticksOnAppear: Ticks = .iteration(0)
    ) {
        self._reg = Observation.ObservationRegistrar()
        self._$modelTransform = initialModelTransform
        self._$isRunning = initialIsRunning
        self.ticksOnAppear = ticksOnAppear
    }

    // MARK: - Observation

    @usableFromInline
    let _reg: Observation.ObservationRegistrar
}
