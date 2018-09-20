import Foundation

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

fileprivate extension String {
  private static let byteSize = 4096

  fileprivate var asFile: String? {
    guard let f = fopen(self, "r") else {
      return nil
    }

    var content = [Int8]()
    let buf     = UnsafeMutablePointer<Int8>.allocate(capacity: String.byteSize)
    memset(buf, 0, String.byteSize)

    var count = 0
    repeat {
      count = fread(buf, 1, String.byteSize, f)
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

  fileprivate var trimmed: String {
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

    guard lines.count > 1, let str = strdup(lines[1]) else {
      return
    }

    if let kb = strstr(str, "kB") {
      kb.pointee = 0
    }

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
    }
  }

  pStat.deallocate()

  return stat
#endif
}