import SwiftWLR
import TweenKit

import Foundation

struct PointStruct: Tweenable {
    var value: Point

    public var x: Double {
        get { return self.value.x }
        set(val) { self.value.x = val }
    }

    public var y: Double {
        get { return self.value.y }
        set(val) { self.value.y = val }
    }

    public func lerp(t: Double, end: PointStruct) -> PointStruct {
        let xDiff = Double(end.value.x - self.value.x)
        let yDiff = Double(end.value.y - self.value.y)

        return PointStruct(value: (x: self.value.x + (xDiff * Double(t)), y: self.value.y + (yDiff * Double(t))))
    }
    
    public func distanceTo(other: PointStruct) -> Double {
        let xDiff = self.value.x - other.value.x
        let yDiff = self.value.y - other.value.y
        
        return sqrt(Double(xDiff * xDiff) + Double(yDiff * yDiff))
    }
}

func + (left: PointStruct, right: PointStruct) -> PointStruct {
    return PointStruct(value: (x: left.x + right.x, y: left.y + right.y))
}

func - (left: PointStruct, right: PointStruct) -> PointStruct {
    return PointStruct(value: (x: left.x - right.x, y: left.y - right.y))
}