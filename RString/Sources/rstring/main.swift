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

let elapsed = Elapsed()

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

  elapsed.reset()
  let generator = Generator(answer: answer)

  Signals.trap(signals: [.hup, .int, .quit, .abrt, .kill, .alrm, .term, .pipe], action: signalHandler)
  generator.startListeningNotifications()
  generator.generate()
}

let elapsedHMS: String = {
  let total     = elapsed.end()
  let (h, m, s) = Int(total).secondsToHMS()
  let hh        = String(format: "%02d", h)
  let mm        = String(format: "%02d", m)
  let ss        = String(format: "%02d", s)
  return "\(hh):\(mm):\(ss)"
}()

print("\n")
Log.log(title: "RString", message: "All jobs completed in \(elapsedHMS) second(s)")
print("\n\n")