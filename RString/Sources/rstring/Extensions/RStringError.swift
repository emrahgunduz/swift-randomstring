import Foundation

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public enum RStringError: Error {
  case missingArgument
  case fileReadError
}