import Foundation

extension Array where Element: AnyObject {
    // Remove element that works with classes, etc.
    public mutating func removeAnyObject(_ el: Element) -> Bool {
        let index = self.firstIndex(where: { $0 === el })

        if index != nil {
            self.remove(at: index!)
            return true
        }

        return false
    }
}