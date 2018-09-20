import Foundation
import Trie
import Log

#if os(macOS) || os(iOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public class Generator {
  private let length:     Int
  private let count:      Int
  private let allowedSet: String
  private let outputFile: String

  private let trie: Trie = Trie()
  private let elapsed    = Elapsed()
  private var existing   = Counter(0)
  private var generated  = Counter(0)

  private var timer: DispatchSourceTimer?

  private var observer:       NSObjectProtocol?
  private let notificationName     = Notification.Name(rawValue: "com.markakod.signalRecevied")
  private var signalReceived: Bool = false

  public init (answer: LoadedAnswer) {
    self.length = answer.length
    self.count = answer.count
    self.allowedSet = answer.set.uniqueCharacters
    self.outputFile = answer.outputFile

    if (answer.inputFile != nil) {
      do {
        let lines = try self.readInputFile(inputFile: answer.inputFile!)
        self.writeToTrie(lines: lines)
      } catch {
        Log.end(message: "Could not read the input file.")
        return
      }
    }

    do {
      var a = String(self.existing.value)
      a.insert(separator: ".", every: 3, fromEnd: true)

      var b = String(answer.count)
      b.insert(separator: ".", every: 3, fromEnd: true)

      var c = String(self.existing.value + answer.count)
      c.insert(separator: ".", every: 3, fromEnd: true)

      Log.log(title: "Generator", message: "Loaded item count is \(a)")
      Log.log(title: "Generator", message: "New item to generate count is \(b)")
      Log.log(title: "Generator", message: "Total item count will be \(c)")
    }
  }

  public func startListeningNotifications () {
    let signalReceived: (Notification) -> Void = { notification in
      self.signalReceived = true
      NotificationCenter.default.removeObserver(self.observer!)

      guard let signal = notification.object as? Int32 else {
        return
      }

      print("\n")
      Log.warning(title: "SIGNAL", message: "OS release signal (\(signal)) received. Please wait...")
    }

    self.observer = NotificationCenter.default.addObserver(forName: self.notificationName, object: nil, queue: OperationQueue.main, using: signalReceived)
  }

  public func generate () {
    self.elapsed.reset()

    self.startTimer { [weak self] in
      let generator = self!

      if (generator.generated.value == 0) {
        return
      }

      let elapsed = generator.elapsed.end()

      var countStr = String(generator.generated.value)
      countStr.insert(separator: ".", every: 3, fromEnd: true)

      let remainsHMS: String = {
        let total     = Double(generator.count)
        let count     = Double(generator.generated.value)
        let remaining = (total * elapsed / count) - elapsed
        let (h, m, s) = Int(remaining).secondsToHMS()
        let hh        = String(format: "%02d", h)
        let mm        = String(format: "%02d", m)
        let ss        = String(format: "%02d", s)
        return "\(hh):\(mm):\(ss)"
      }()

      let elapsedHMS: String = {
        let (h, m, s) = Int(elapsed).secondsToHMS()
        let hh        = String(format: "%02d", h)
        let mm        = String(format: "%02d", m)
        let ss        = String(format: "%02d", s)
        return "\(hh):\(mm):\(ss)"
      }()

      Log.log(title: elapsedHMS, message: "(\(remainsHMS)) Computed \(countStr) items, \(generator.getMemory()) Mb(s) memory remains")
    }

    self.generateRunGroup()
    self.stopTimer()

    do {
      var count = String(self.generated.value)
      count.insert(separator: ".", every: 3, fromEnd: true)

      let elapsed = self.elapsed.end()
      Log.log(title: "Computing", message: "Computed \(count) items, elapsed \(elapsed) second(s)")
    }

    do {
      try self.writeToOutput()
    } catch {
      Log.error(title: "Output", message: "Could not write to \"\(self.outputFile)\" file. Do you have enough permissions?")
    }
  }
}

private extension Generator {

  private func getMemory () -> String {
    let mem = memory()
    guard let available = mem["MemAvailable"] else {
      return "undefined"
    }

    return "\(available) MB(s)"
  }

  private func startTimer (handler: @escaping () -> Void) {
    self.timer = DispatchSource.makeTimerSource()
    self.timer?.setEventHandler(handler: handler)
    self.timer?.schedule(deadline: .now() + .seconds(3), repeating: 5, leeway: .seconds(0))
    self.timer?.resume()
  }

  private func stopTimer () {
    self.timer?.cancel()
    self.timer = nil
  }

  private func readInputFile (inputFile: String) throws -> [String] {
    let fileUrl = URL(fileURLWithPath: inputFile)

    var rawContent: Data
    var lines:      [String]

    do {
      Log.log(title: "Input", message: "Reading input file. \(inputFile)")

      rawContent = try Data(contentsOf: fileUrl, options: .alwaysMapped)
      let content = String(data: rawContent, encoding: .utf8)!
      lines = content.lines

      var countStr = "\(lines.count)"
      countStr.insert(separator: ".", every: 3, fromEnd: true)

      Log.log(title: "Input", message: "Completed reading a total of \(countStr) lines")
    } catch {
      throw(RStringError.fileReadError)
    }

    return lines
  }

  private func writeToTrie (lines: [String]) {
    Log.log(title: "Trie", message: "Generating trie database")
    self.elapsed.reset()
    self.stopTimer()

    self.startTimer { [weak self] in
      let generator = self!

      let elapsedHMS: String = {
        let elapsed   = generator.elapsed.end()
        let (h, m, s) = Int(elapsed).secondsToHMS()
        let hh        = String(format: "%02d", h)
        let mm        = String(format: "%02d", m)
        let ss        = String(format: "%02d", s)
        return "\(hh):\(mm):\(ss)"
      }()

      var countStr = String(generator.existing.value)
      countStr.insert(separator: ".", every: 3, fromEnd: true)

      Log.log(title: elapsedHMS, message: "Added \(countStr) items, \(generator.getMemory()) memory remains")
    }

    do {
      let group = DispatchGroup()
      let _     = DispatchQueue.global(qos: .userInitiated)

      DispatchQueue.concurrentPerform(iterations: lines.count) { index in
        group.enter()

        let line    = lines[index]
        var trimmed = line.trim()

        if (trimmed.count == 0) {
          group.leave()
          return
        }

        if (trimmed.count < self.length) {
          Log.warning(title: "Trie", message: "A line in given file has less characters than anticipated. Passing (Line #\(index))")
          group.leave()
          return
        }

        if (trimmed.count > self.length) {
          Log.warning(title: "Trie", message: "A line in given file has more characters than anticipated. Dropping extensive characters. (Line #\(index))")
          let diff = trimmed.count - Int(self.length)
          trimmed = String(trimmed.dropLast(diff))
        }

        self.trie.insert(element: trimmed)
        self.existing += 1

        group.leave()
      }

      group.notify(queue: DispatchQueue.main) {
        // Do nothing, just here to end group
      }

      group.wait()
    }

    self.stopTimer()
    Log.log(title: "Trie", message: "Trie database is ready, \(elapsed.end()) seconds elapsed")
  }

  private func writeToOutput () throws {
    Log.log(title: "Output", message: "Writing to output file")
    self.elapsed.reset()
    self.stopTimer()

    self.startTimer { [weak self] in
      let generator = self!

      let elapsedHMS: String = {
        let elapsed   = generator.elapsed.end()
        let (h, m, s) = Int(elapsed).secondsToHMS()
        let hh        = String(format: "%02d", h)
        let mm        = String(format: "%02d", m)
        let ss        = String(format: "%02d", s)
        return "\(hh):\(mm):\(ss)"
      }()

      Log.log(title: elapsedHMS, message: "Still writing, please wait")
    }

    var content = ""
    self.trie.contents { item in
      content += item + "\n"
    }

    do {
      let fileHandle = try FileHandle(forWritingTo: URL(string: self.outputFile)!)
      fileHandle.truncateFile(atOffset: 0) // Clear file -- disable this line to append the content
      fileHandle.seekToEndOfFile()
      fileHandle.write(content.data(using: .utf8)!)
      fileHandle.closeFile()
    } catch {
      do {
        try content.write(toFile: self.outputFile, atomically: false, encoding: .utf8)
      } catch {
        throw(RStringError.fileReadError)
      }
    }

    self.stopTimer()
    Log.log(title: "Output", message: "Completed writing, \(elapsed.end()) seconds elapsed")
  }

  private func generateRunGroup () {
    let group = DispatchGroup()
    let _     = DispatchQueue.global(qos: .userInitiated)

    DispatchQueue.concurrentPerform(iterations: self.count) { index in
      group.enter()

      if (self.signalReceived) {
        group.leave()
        return
      }

      let item = String.randomString(length: self.length, allowed: self.allowedSet)
      self.trie.insert(element: item)
      self.generated.increment()

      group.leave()
    }

    group.notify(queue: DispatchQueue.main) {
      // Do nothing, just here to end group
    }

    group.wait()
  }

}
