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

    Log.log(title: "Generator", message: "Existing item count is \(counter!.value)")
    Log.log(title: "Generator", message: "Required new item to generate count is \(answer.count)")
    Log.log(title: "Generator", message: "Possible factorial count for current set is \(possibleStr) items")
  }

}

public extension Generator {

  private func generateRunGroup () {
    do {
      let group = DispatchGroup()
      let _     = DispatchQueue.global(qos: .userInitiated)

      DispatchQueue.concurrentPerform(iterations: self.count) { index in
        group.enter()

        let item = String.randomString(length: self.length, allowed: self.allowedSet)
        if (self.trie.exists(element: item)) {
          return
        }

        self.generated.append(item)
        self.trie.insert(element: item)
        self.remaining.increment()

        group.leave()
      }

      group.notify(queue: DispatchQueue.main) {
        // Do nothing, just here to end group
      }

      group.wait()
    }
  }

  public func generate () {
    // TODO: Add a way to listen/unlisten with SIGKILL here

    self.elapsed.reset()
    let timer = DispatchSource.makeTimerSource()
    do {
      timer.setEventHandler { [weak self] in
        let generator = self!
        let count     = generator.generated.count
        let elapsed   = generator.elapsed.end()
        let (h, m, s) = Int(Double(generator.count) * elapsed / Double(count)).secondsToHMS()

        let hh = String(format: "%02d", h)
        let mm = String(format: "%02d", m)
        let ss = String(format: "%02d", s)

        Log.log(title: "Generator", message: "Computed \(count) items, elapsed \(elapsed) second(s), remains \(hh):\(mm):\(ss) second(s)")
      }
      timer.schedule(deadline: .now(), repeating: 5, leeway: .seconds(0))
      timer.resume()
    }

    self.generateRunGroup()

    timer.cancel()
    do {
      let count   = self.generated.count
      let elapsed = self.elapsed.end()
      Log.log(title: "Generator", message: "Computed \(count) items, elapsed \(elapsed) second(s)")
    }

    // TODO: Dump to output file
  }

}

private extension Generator {

  private static func maxLoopCount (limit: Int) -> Int {
    var loop = 10

    switch limit {
      case 0 ..< 1000:            // 1.000
        loop = 1
        break
      case 1000 ..< 10000:        // 10.000
        loop = 10
        break
      case 10000 ..< 1000000:     // 1.000.000
        loop = 100
        break
      case 1000000 ..< 10000000:  // 10.000.000
        loop = 10000
        break
      case 10000000 ..< 100000000:  // 100.000.000
        loop = 100000
        break
      default:
        loop = 100000
        break
    }

    return loop
  }

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
