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

infix operator **: MultiplicationPrecedence

public extension Int {
  func secondsToHMS () -> (Int, Int, Int) {
    return (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
  }

  static func ** (left: Int, right: Int) -> Int {
    return Int(pow(CGFloat(left), CGFloat(right)))
  }
}

// Common vars
public extension String {
  public var lines: [String] {
    return self.components(separatedBy: "\n")
  }
}

// Common functions
public extension String {
  public func trim () -> String {
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

  public var uniqueCharacters: String {
    var characterCounts = [Character: Int]()
    self.forEach { char in
      if characterCounts[char] != nil {
        characterCounts[char]! += 1
      } else {
        characterCounts[char] = 1
      }
    }

    let uniqueList = self.filter { characterCounts[$0]! == 1 }
    return uniqueList.map { String($0) }.joined()
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


public extension String {
  public static let szSTR = 4096

  public var asFile: String? {
    guard let f = fopen(self, "r") else {
      return nil
    }

    var content = [Int8]()
    let buf     = UnsafeMutablePointer<Int8>.allocate(capacity: String.szSTR)
    memset(buf, 0, String.szSTR)

    var count = 0
    repeat {
      count = fread(buf, 1, String.szSTR, f)
      if (count > 0) {
        let buffer = UnsafeBufferPointer(start: buf, count: count)
        content += Array(buffer)
      }
    } while (count > 0)

    fclose(f)
    buf.deallocate()

    let ret = String(cString: content)
    return ret
  }

  public var trimmed: String {
    var buf      = [UInt8]()
    var trimming = true

    for c in self.utf8 {
      if (trimming && c < 33) {
        continue
      }

      trimming = false
      buf.append(c)
    }

    while let last = buf.last, last < 33 {
      buf.removeLast()
    }

    buf.append(0)
    return String(cString: buf)
  }
}

public func memory () -> [String: Int] {
#if os(Linux)
  guard let content = "/proc/meminfo".asFile else { return [:] }
  var stat: [String: Int] = [:]
  content.split(separator: Character("\n")).forEach { line in
    let lines: [String] = line.split(separator: Character(":")).map(String.init)
    let key             = lines[0]
    guard lines.count > 1, let str = strdup(lines[1]) else { return }
    if let kb = strstr(str, "kB") {
      kb.pointee = 0
    }//end if
    let value = String(cString: str).trimmed
    stat[key] = (Int(value) ?? 0) / 1024
    free(str)
  }
  return stat
#else
  let size                = MemoryLayout<vm_statistics>.size / MemoryLayout<integer_t>.size
  let pStat               = UnsafeMutablePointer<integer_t>.allocate(capacity: size)
  var stat: [String: Int] = [:]
  var count               = mach_msg_type_number_t(size)
  if 0 == host_statistics(mach_host_self(), HOST_VM_INFO, pStat, &count) {
    let array = Array(UnsafeBufferPointer(start: pStat, count: size))
    let tags  = ["free", "active", "inactive", "wired", "zero_filled", "reactivations", "pageins", "pageouts", "faults", "cow", "lookups", "hits"]
    let cnt   = min(tags.count, array.count)
    for i in 0 ... cnt - 1 {
      let key   = tags[i]
      let value = array[i]
      stat[key] = Int(value) / 256
    }//next i
  }//end if
  pStat.deallocate(capacity: size)
  return stat
#endif
}