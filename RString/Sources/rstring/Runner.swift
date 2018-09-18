import Foundation
import Log

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public class Loader {

  public func checkArguments () -> LoadedAnswer {
    let argCount = UInt(CommandLine.argc)

    var answer: LoadedAnswer = LoadedAnswer()

    var i: Int = 0
    do {
      while i < argCount {
        let argument = CommandLine.arguments[i]

        switch argument {
          case "-h", "--help":
            answer.helpRequested = true
            break
          case "-l", "--length":
            i += 1
            if (i >= argCount) {
              throw(RStringError.missingArgument)
            }
            let value = CommandLine.arguments[Int(i)]
            answer.length = Int(value)!
            break
          case "-c", "--count":
            i += 1
            if (i >= argCount) {
              throw(RStringError.missingArgument)
            }
            let value = CommandLine.arguments[Int(i)]
            answer.count = Int(value)!
            break
          case "-s", "--set":
            i += 1
            if (i >= argCount) {
              throw(RStringError.missingArgument)
            }
            let value = CommandLine.arguments[Int(i)]
            answer.set = value
            break
          case "-o", "--out":
            i += 1
            if (i >= argCount) {
              throw(RStringError.missingArgument)
            }
            let value = CommandLine.arguments[Int(i)]
            answer.outputFile = value
            break
          case "-f", "--file":
            i += 1
            if (i >= argCount) {
              throw(RStringError.missingArgument)
            }
            let value = CommandLine.arguments[Int(i)]
            answer.inputFile = value
            break
          default:
            break
        }

        i += 1
      }
    } catch {
      Log.end(message: "Not enough arguments specified.")
      exit(0)
    }

    return answer
  }

}