@preconcurrency import AppKit
@preconcurrency import SpriteKit
@preconcurrency import PHPCore
import CSwiftPHP

struct ArgInfoBox: @unchecked Sendable {
    let info: [zend_internal_arg_info]
}

// MARK: - Runtime (MainActor)

@MainActor
final class SpriteRuntime {
    static let shared = SpriteRuntime()

    var app: NSApplication?
    var window: NSWindow?
    var view: SKView?
    var scene: SKScene?

    // Entities
    private var nextID: Int = 1
    private var nodes: [Int: SKShapeNode] = [:]
    private var velocities: [Int: CGVector] = [:]

    // Accept a Swift String (Sendable) instead of a C pointer
    func start(_ w: Int32, _ h: Int32, _ title: String?) {
        if app == nil { app = NSApplication.shared }
        app?.setActivationPolicy(.regular)
        let sz = NSSize(width: Int(w), height: Int(h))

        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: sz),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window?.title = title ?? "SpriteKit"
        view = SKView(frame: NSRect(origin: .zero, size: sz))
        scene = SKScene(size: sz)
        scene?.scaleMode = .resizeFill
        window?.contentView = view
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        view?.presentScene(scene)
        app?.activate(ignoringOtherApps: true)
    }

    func bg(_ r: Float, _ g: Float, _ b: Float) {
        scene?.backgroundColor = NSColor(
            calibratedRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1
        )
    }

    // Returns an ID so PHP can refer to the node later
    func rect(_ x: Float, _ y: Float, _ w: Float, _ h: Float) -> Int {
        let n = SKShapeNode(rectOf: CGSize(width: CGFloat(w), height: CGFloat(h)))
        n.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
        n.lineWidth = 0
        n.fillColor = .white
        scene?.addChild(n)

        let id = nextID; nextID += 1
        nodes[id] = n
        velocities[id] = .zero
        return id
    }

    func setVelocity(_ id: Int, vx: Float, vy: Float) {
        velocities[id] = CGVector(dx: CGFloat(vx), dy: CGFloat(vy))
    }

    func moveBy(_ id: Int, dx: Float, dy: Float) {
        guard let n = nodes[id] else { return }
        n.position.x += CGFloat(dx)
        n.position.y += CGFloat(dy)
    }

    func pump() {
        guard let app else { return }

        // Basic event pump (single slice)
        let until = Date(timeIntervalSinceNow: 0.016)
        while let e = app.nextEvent(matching: .any, until: until, inMode: .default, dequeue: true) {
            app.sendEvent(e)
        }

        // Integrate velocities and bounce inside the view bounds
        if let view {
            let bounds = view.bounds
            for (id, v) in velocities {
                guard let n = nodes[id] else { continue }
                n.position.x += v.dx
                n.position.y += v.dy

                // Bounce logic
                let halfW = n.frame.width * 0.5
                let halfH = n.frame.height * 0.5
                var newV = v

                if n.position.x - halfW < bounds.minX {
                    n.position.x = bounds.minX + halfW
                    newV.dx = abs(newV.dx)
                } else if n.position.x + halfW > bounds.maxX {
                    n.position.x = bounds.maxX - halfW
                    newV.dx = -abs(newV.dx)
                }

                if n.position.y - halfH < bounds.minY {
                    n.position.y = bounds.minY + halfH
                    newV.dy = abs(newV.dy)
                } else if n.position.y + halfH > bounds.maxY {
                    n.position.y = bounds.maxY - halfH
                    newV.dy = -abs(newV.dy)
                }

                velocities[id] = newV
            }

            view.setNeedsDisplay(view.bounds)
        }
    }

    func close() {
        view?.presentScene(nil)
        window?.orderOut(nil)
        window = nil
        view = nil
        scene = nil
        nodes.removeAll()
        velocities.removeAll()
        nextID = 1
    }
}

// MARK: - Arginfo

public let arginfo_sprite_start = ArgInfoBox(info: [
    ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(name: "sprite_start", return_reference: false, required_num_args: 0, type: UInt32(_IS_BOOL), allow_null: false),
    ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(pass_by_ref: false, name: "width",  type_hint: UInt32(IS_LONG),   allow_null: true, default_value: "800"),
    ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(pass_by_ref: false, name: "height", type_hint: UInt32(IS_LONG),   allow_null: true, default_value: "600"),
    ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(pass_by_ref: false, name: "title",  type_hint: UInt32(IS_STRING), allow_null: true, default_value: "\"SpriteKit\"")
]).info

public let arginfo_sprite_bg = ArgInfoBox(info: [
    ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(name: "sprite_bg", return_reference: false, required_num_args: 3, type: UInt32(_IS_BOOL), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "r", type_hint: UInt32(IS_DOUBLE), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "g", type_hint: UInt32(IS_DOUBLE), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "b", type_hint: UInt32(IS_DOUBLE), allow_null: false)
]).info

// Return the new rect's ID (int)
public let arginfo_sprite_rect = ArgInfoBox(info: [
    ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(name: "sprite_rect", return_reference: false, required_num_args: 4, type: UInt32(IS_LONG), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "x", type_hint: UInt32(IS_DOUBLE), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "y", type_hint: UInt32(IS_DOUBLE), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "w", type_hint: UInt32(IS_DOUBLE), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "h", type_hint: UInt32(IS_DOUBLE), allow_null: false)
]).info

public let arginfo_sprite_set_velocity = ArgInfoBox(info: [
    ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(name: "sprite_set_velocity", return_reference: false, required_num_args: 3, type: UInt32(_IS_BOOL), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "id", type_hint: UInt32(IS_LONG), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "vx", type_hint: UInt32(IS_DOUBLE), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "vy", type_hint: UInt32(IS_DOUBLE), allow_null: false)
]).info

public let arginfo_sprite_move_by = ArgInfoBox(info: [
    ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(name: "sprite_move_by", return_reference: false, required_num_args: 3, type: UInt32(_IS_BOOL), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "id", type_hint: UInt32(IS_LONG), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "dx", type_hint: UInt32(IS_DOUBLE), allow_null: false),
    ZEND_ARG_TYPE_INFO(pass_by_ref: false, name: "dy", type_hint: UInt32(IS_DOUBLE), allow_null: false)
]).info

public let arginfo_sprite_pump = ArgInfoBox(info: [
    ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(name: "sprite_pump", return_reference: false, required_num_args: 0, type: UInt32(_IS_BOOL), allow_null: false)
]).info

public let arginfo_sprite_close = ArgInfoBox(info: [
    ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(name: "sprite_close", return_reference: false, required_num_args: 0, type: UInt32(_IS_BOOL), allow_null: false)
]).info

// MARK: - C entrypoints (nonisolated) – hop to MainActor inside

@_cdecl("zif_sprite_start")
public nonisolated func zif_sprite_start(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?,
    _ return_value: UnsafeMutablePointer<zval>?
) {
    var width: zend_long = 800
    var height: zend_long = 600
    var title_cstr: UnsafeMutablePointer<CChar>? = nil
    var title_len: Int = 0

    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 0, max: 3, execute_data: execute_data) else {
            if let return_value { ZVAL_FALSE(return_value) }
            return
        }
        Z_PARAM_OPTIONAL(state: &state)
        try Z_PARAM_LONG(state: &state, dest: &width)
        try Z_PARAM_LONG(state: &state, dest: &height)
        try Z_PARAM_STRING_OR_NULL(state: &state, dest: &title_cstr, destLen: &title_len)
        try ZEND_PARSE_PARAMETERS_END(state: state)
    } catch {
        if let return_value { ZVAL_FALSE(return_value) }
        return
    }

    let titleSwift: String? = title_cstr.map { String(cString: $0) } ?? "SpriteKit"
    MainActor.assumeIsolated {
        SpriteRuntime.shared.start(Int32(width), Int32(height), titleSwift)
    }
    if let return_value { ZVAL_TRUE(return_value) }
}

@_cdecl("zif_sprite_bg")
public nonisolated func zif_sprite_bg(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?,
    _ return_value: UnsafeMutablePointer<zval>?
) {
    var r: CDouble = 0.1, g: CDouble = 0.12, b: CDouble = 0.15
    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 3, max: 3, execute_data: execute_data) else { if let return_value { ZVAL_FALSE(return_value) }; return }
        try Z_PARAM_DOUBLE(state: &state, dest: &r)
        try Z_PARAM_DOUBLE(state: &state, dest: &g)
        try Z_PARAM_DOUBLE(state: &state, dest: &b)
        try ZEND_PARSE_PARAMETERS_END(state: state)
    } catch { if let return_value { ZVAL_FALSE(return_value) }; return }

    MainActor.assumeIsolated {
        SpriteRuntime.shared.bg(Float(r), Float(g), Float(b))
    }
    if let return_value { ZVAL_TRUE(return_value) }
}

@_cdecl("zif_sprite_rect")
public nonisolated func zif_sprite_rect(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?,
    _ return_value: UnsafeMutablePointer<zval>?
) {
    var x: CDouble = 100, y: CDouble = 100, w: CDouble = 80, h: CDouble = 80
    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 4, max: 4, execute_data: execute_data) else { if let return_value { ZVAL_FALSE(return_value) }; return }
        try Z_PARAM_DOUBLE(state: &state, dest: &x)
        try Z_PARAM_DOUBLE(state: &state, dest: &y)
        try Z_PARAM_DOUBLE(state: &state, dest: &w)
        try Z_PARAM_DOUBLE(state: &state, dest: &h)
        try ZEND_PARSE_PARAMETERS_END(state: state)
    } catch { if let return_value { ZVAL_FALSE(return_value) }; return }

    var idOut: Int = 0
    MainActor.assumeIsolated {
        idOut = SpriteRuntime.shared.rect(Float(x), Float(y), Float(w), Float(h))
    }
    if let return_value { ZVAL_LONG(return_value, zend_long(idOut)) }
}

@_cdecl("zif_sprite_set_velocity")
public nonisolated func zif_sprite_set_velocity(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?,
    _ return_value: UnsafeMutablePointer<zval>?
) {
    var id: zend_long = 0
    var vx: CDouble = 0, vy: CDouble = 0
    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 3, max: 3, execute_data: execute_data) else { if let return_value { ZVAL_FALSE(return_value) }; return }
        try Z_PARAM_LONG(state: &state, dest: &id)
        try Z_PARAM_DOUBLE(state: &state, dest: &vx)
        try Z_PARAM_DOUBLE(state: &state, dest: &vy)
        try ZEND_PARSE_PARAMETERS_END(state: state)
    } catch { if let return_value { ZVAL_FALSE(return_value) }; return }

    MainActor.assumeIsolated {
        SpriteRuntime.shared.setVelocity(Int(id), vx: Float(vx), vy: Float(vy))
    }
    if let return_value { ZVAL_TRUE(return_value) }
}

@_cdecl("zif_sprite_move_by")
public nonisolated func zif_sprite_move_by(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?,
    _ return_value: UnsafeMutablePointer<zval>?
) {
    var id: zend_long = 0
    var dx: CDouble = 0, dy: CDouble = 0
    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 3, max: 3, execute_data: execute_data) else { if let return_value { ZVAL_FALSE(return_value) }; return }
        try Z_PARAM_LONG(state: &state, dest: &id)
        try Z_PARAM_DOUBLE(state: &state, dest: &dx)
        try Z_PARAM_DOUBLE(state: &state, dest: &dy)
        try ZEND_PARSE_PARAMETERS_END(state: state)
    } catch { if let return_value { ZVAL_FALSE(return_value) }; return }

    MainActor.assumeIsolated {
        SpriteRuntime.shared.moveBy(Int(id), dx: Float(dx), dy: Float(dy))
    }
    if let return_value { ZVAL_TRUE(return_value) }
}

@_cdecl("zif_sprite_pump")
public nonisolated func zif_sprite_pump(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?,
    _ return_value: UnsafeMutablePointer<zval>?
) {
    MainActor.assumeIsolated { SpriteRuntime.shared.pump() }
    if let return_value { ZVAL_TRUE(return_value) }
}

@_cdecl("zif_sprite_close")
public nonisolated func zif_sprite_close(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?,
    _ return_value: UnsafeMutablePointer<zval>?
) {
    MainActor.assumeIsolated { SpriteRuntime.shared.close() }
    if let return_value { ZVAL_TRUE(return_value) }
}

// MARK: - Registration

public func spritekit_add_entries(builder: inout FunctionListBuilder) {
    builder.add(name: "sprite_start",        handler: zif_sprite_start,        arg_info: arginfo_sprite_start)
    builder.add(name: "sprite_bg",           handler: zif_sprite_bg,           arg_info: arginfo_sprite_bg)
    builder.add(name: "sprite_rect",         handler: zif_sprite_rect,         arg_info: arginfo_sprite_rect)
    builder.add(name: "sprite_set_velocity", handler: zif_sprite_set_velocity, arg_info: arginfo_sprite_set_velocity)
    builder.add(name: "sprite_move_by",      handler: zif_sprite_move_by,      arg_info: arginfo_sprite_move_by)
    builder.add(name: "sprite_pump",         handler: zif_sprite_pump,         arg_info: arginfo_sprite_pump)
    builder.add(name: "sprite_close",        handler: zif_sprite_close,        arg_info: arginfo_sprite_close)
}