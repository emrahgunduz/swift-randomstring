import Foundation

public enum RStringError: Error {
  case missingArgument
  case fileReadError
}

public struct LoadedAnswer {
  var helpRequested: Bool = false

  var length:     Int    = 8
  var count:      Int    = 100
  var set:        String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  var outputFile: String = "/tmp/random-\(String.randomString(length: 6)).txt"
  var inputFile:  String?
}

// Common vars
public extension String {
  var lines: [String] {
    return self.components(separatedBy: "\n")
  }
}

// Common functions
public extension String {
  func trim () -> String {
    return self.trimmingCharacters(in: CharacterSet.whitespaces)
  }
}

// Random string
public extension String {
  static func randomString (length: Int, allowed: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {
    let allowedCharsCount = UInt32(allowed.count)
    var randomString      = ""

    for _ in 0 ..< length {
      let randomNum    = Int(arc4random_uniform(allowedCharsCount))
      let randomIndex  = allowed.index(allowed.startIndex, offsetBy: randomNum)
      let newCharacter = allowed[randomIndex]
      randomString += String(newCharacter)
    }

    return randomString
  }
}

// Factorial count
private func carryAll (_ arr: [Int]) -> [Int] {
  var result = [Int]()

  var carry = 0
  for val in arr.reversed() {
    let total = val + carry
    let digit = total % 10
    carry = total / 10
    result.append(digit)
  }

  while carry > 0 {
    let digit = carry % 10
    carry = carry / 10
    result.append(digit)
  }

  return result.reversed()
}

public extension String {
  static func factorial (length: Int) -> String {
    var result = [1]
    for i in 2 ... length {
      result = result.map { $0 * i }
      result = carryAll(result)
    }

    return result.map(String.init).joined()
  }
}

// Insert char
public extension String {
  private var pairs: [String] {
    var result: [String] = []
    let characters       = Array(self)
    stride(from: 0, to: count, by: 2).forEach {
      result.append(String(characters[$0 ..< min($0 + 2, count)]))
    }
    return result
  }

  private func inserting (separator: String, every n: Int) -> String {
    var result: String = ""
    let characters     = Array(self)
    stride(from: 0, to: count, by: n).forEach {
      result += String(characters[$0 ..< min($0 + n, count)])
      if $0 + n < count {
        result += separator
      }
    }
    return result
  }

  mutating func insert (separator: String, every n: Int, fromEnd: Bool = false) {
    if (fromEnd) {
      self = String(self.reversed())
    }

    self = inserting(separator: separator, every: n)

    if (fromEnd) {
      self = String(self.reversed())
    }
  }
}