import Foundation
import ProjectDescription

extension Module {
    /// Configuration options for a module's test target
    struct TestConfig {
        /// Additional dependencies beyond the primary module itself and the testing resources module
        var dependencies: [TargetDependency] = []
        /// Additional sources that the module's test target may need (such as the shared mocks)
        var additionalSources: [SourceFileGlob] = []
        /// Determines if the test target should have resource bundle created for it.
        var hasResources: Bool = true
        /// Additional build settings to apply to the test target.
        var buildSettings: Settings = .settings()
        /// Additional properties to apply to the generated Info.plist file
        var additionalInfoPlistProperties: [String : ProjectDescription.InfoPlist.Value] = [:]
    }
}
