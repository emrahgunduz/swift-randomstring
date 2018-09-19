import Foundation
import Information
import Signals
import Log

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

#if os(Linux)
srandom(UInt32(time(nil)))

public func arc4random_uniform (_ max: UInt32) -> UInt32 {
  return UInt32(SwiftGlibc.rand() % Int32(max))
}
#endif

func signalHandler (signal: Int32) {
  NotificationCenter.default.post(name: Notification.Name(rawValue: "com.markakod.signalRecevied"), object: signal)
}

Signals.trap(signals: [.hup, .int, .quit, .abrt, .kill, .alrm, .term, .pipe], action: signalHandler)

do {
  let release = "1.0"
  let build   = "100"

  Information.printLogo(release: release, build: build)

  let runner = Loader()
  let answer = runner.checkArguments()
  if (answer.helpRequested) {
    Information.printHelp()
    exit(0)
  }

  let generator = Generator(answer: answer)
  generator.startListeningNotifications()
  generator.generate()
}