//
// Created by emrah on 18.09.2018.
//

import Foundation

class Elapsed {
  var start = DispatchTime.now()

  public init () {

  }

  public func reset () {
    self.start = DispatchTime.now()
  }

  public func end () -> Double {
    let end          = DispatchTime.now()
    let passed       = end.uptimeNanoseconds - self.start.uptimeNanoseconds
    let timeInterval = Double(passed) / 1_000_000_000.00
    return timeInterval
  }
}
