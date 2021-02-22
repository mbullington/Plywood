import SwiftWLR

import Logging

LoggingSystem.bootstrap(WLRLogHandler.init)

let server = WaylandServer()
let state = PlywoodState(for: server)

state.logger.info("Running Wayland compositor on WAYLAND_DISPLAY=\(server.socket)")

// let _ = try! Process.run(
//     URL(fileURLWithPath: "/bin/sh", isDirectory: false),
//     arguments: ["-c", "alacritty"]
// )

server.run()
