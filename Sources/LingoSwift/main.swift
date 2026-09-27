import Foundation

// `main.swift` is the real entry point so that LingoSwift can run headless
// diagnostics (`--doctor`) without starting the SwiftUI app.

setvbuf(stdout, nil, _IOLBF, 0)

if Diagnostics.isRequested {
    await Diagnostics.performChecks()
    exit(0)
}

LingoSwiftApp.main()
