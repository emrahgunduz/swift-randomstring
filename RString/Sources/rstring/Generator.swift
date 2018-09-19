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

  private let trie:      Trie                      = Trie()
  private var generated: SynchronizedArray<String> = SynchronizedArray<String>()

  private let elapsed   = Elapsed()
  private var remaining = Counter(0)

  private var observer:       NSObjectProtocol?
  private let notificationName     = Notification.Name(rawValue: "com.markakod.signalRecevied")
  private var signalReceived: Bool = false

  public init (answer: LoadedAnswer) {
    self.length = answer.length
    self.count = answer.count
    self.allowedSet = answer.set
    self.outputFile = answer.outputFile

    var counter: Counter?

    if (answer.inputFile != nil) {
      Log.log(title: "Generator", message: "Reading input file. " + answer.inputFile!)

      do {
        let lines = try Generator.readInputFile(inputFile: answer.inputFile!)
        counter = Generator.writeToTrie(lines: lines, requiredLength: self.length, trie: self.trie)
      } catch {
        Log.end(message: "Could not load the dictionary file content.")
        return
      }
    }

    Log.log(title: "Generator", message: "Trie database is ready.")

    var possibleStr = String.factorial(length: answer.set.count)
    possibleStr.insert(separator: ".", every: 3, fromEnd: true)

    do {
      var a = String(counter!.value)
      var b = String(answer.count)
      a.insert(separator: ".", every: 3, fromEnd: true)
      b.insert(separator: ".", every: 3, fromEnd: true)

      Log.log(title: "Generator", message: "Existing item count is \(a)")
      Log.log(title: "Generator", message: "Required new item to generate count is \(b)")
      Log.log(title: "Generator", message: "Possible factorial count for current set is \(possibleStr) items")
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
      Log.warning(title: "Generator", message: "OS release signal (\(signal)) received. Please wait...")
    }

    self.observer = NotificationCenter.default.addObserver(forName: self.notificationName, object: nil, queue: OperationQueue.main, using: signalReceived)
  }
}

public extension Generator {

  private func generateRunGroup () {
    do {
      let group = DispatchGroup()
      let _     = DispatchQueue.global(qos: .userInitiated)

      DispatchQueue.concurrentPerform(iterations: self.count) { index in
        group.enter()

        if (self.signalReceived) {
          group.leave()
          return
        }

        let item = String.randomString(length: self.length, allowed: self.allowedSet)
        if (self.trie.exists(element: item)) {
          group.leave()
          return
        }

        self.generated.append(item)
        self.trie.insert(element: item)
        self.remaining.increment()

        group.leave()
      }

      group.notify(queue: DispatchQueue.main) {
        // Do nothing, just here to end group
        Log.log(title: "Generator Group", message: "Notified")
      }

      group.wait()
    }
  }

  public func generate () {
    self.elapsed.reset()
    let timer = DispatchSource.makeTimerSource()
    do {
      timer.setEventHandler { [weak self] in
        let generator = self!

        if (generator.generated.count == 0) {
          Log.warning(title: "Generator", message: "No item is generated yet, are you sure there is enough possibility to generate any?")
        }

        let total     = Double(generator.count)
        let count     = Double(generator.generated.count)
        let elapsed   = generator.elapsed.end()
        let remaining = (total * elapsed / count) - elapsed

        let (h, m, s) = Int(remaining).secondsToHMS()

        let hh = String(format: "%02d", h)
        let mm = String(format: "%02d", m)
        let ss = String(format: "%02d", s)

        var a = String(generator.generated.count)
        a.insert(separator: ".", every: 3, fromEnd: true)
        Log.log(title: "Generator", message: "Computed \(a) items, elapsed \(elapsed) second(s), remains \(hh):\(mm):\(ss) second(s)")
      }
      timer.schedule(deadline: .now() + .seconds(2), repeating: 5, leeway: .seconds(0))
      timer.resume()
    }

    self.generateRunGroup()

    timer.cancel()
    do {
      var count = String(self.generated.count)
      count.insert(separator: ".", every: 3, fromEnd: true)

      let elapsed = self.elapsed.end()
      Log.log(title: "Generator", message: "Computed \(count) items, elapsed \(elapsed) second(s)")
    }

    self.writeToOutput()
  }

}

private extension Generator {

  private func writeToOutput () {
    if (self.generated.count == 0) {
      Log.log(title: "Generator", message: "No random items were generated.")
      return
    }

    Log.log(title: "Generator", message: "Writing generated items to \"\(self.outputFile)\" file")
  }

}

private extension Generator {
  
  private static func readInputFile (inputFile: String) throws -> [String] {
    let fileUrl = URL(fileURLWithPath: inputFile)

    var rawContent: Data
    var lines:      [String]

    do {
      rawContent = try Data(contentsOf: fileUrl, options: .alwaysMapped)
      let content = String(data: rawContent, encoding: .utf8)!
      lines = content.lines
    } catch {
      throw(RStringError.missingArgument)
    }

    return lines
  }

  private static func writeToTrie (lines: [String], requiredLength: Int, trie: Trie) -> Counter {
    var counter = Counter(0)

    for (index, line) in lines.enumerated() {
      var trimmed = line.trim()
      if (trimmed.count == 0) {
        continue
      }

      if (trimmed.count < requiredLength) {
        Log.warning(title: "Generator", message: "A line in given file has less characters than anticipated. Passing (Line #\(index))")
        continue
      }

      if (trimmed.count > requiredLength) {
        Log.warning(title: "Generator", message: "A line in given file has more characters than anticipated. Dropping extensive characters. (Line #\(index))")
        let diff = trimmed.count - Int(requiredLength)
        trimmed = String(trimmed.dropLast(diff))
      }

      trie.exists(element: trimmed) { exists in
        if (!exists) {
          trie.insert(element: trimmed)
          counter += 1
        }
      }
    }

    return counter
  }

}
