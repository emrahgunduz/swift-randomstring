import Foundation

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public struct LoadedAnswer {
  var helpRequested: Bool = false

  var length:     Int    = 8
  var count:      Int    = 100
  var set:        String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  var outputFile: String = "/tmp/random-\(String.randomString(length: 6)).txt"
  var inputFile:  String?
}