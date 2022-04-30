import Foundation
import ProjectDescription

extension Array where Element == TargetDependency {
    /// Removes the duplicates that have the same name in an array of `TargetDependency`. This is similar behavior to
    /// a `Set<TargetDependency>` were `TargetDependency` also `Hashable`.
    ///
    /// - Returns: An updated array of `TargetDependency`
    func removingDuplicates() -> [Element] {
        var filteredItems = [TargetDependency]()
        for dep in self {
            if filteredItems.contains(dep) == false {
                filteredItems.append(dep)
            }
        }

        return filteredItems
    }
}
