//
//  ModuleConfig.swift
//  
//
//  Created by Jared Sorge on 4/30/22.
//

import Foundation
import ProjectDescription

extension Module {
    /// Configuration options used when generating the target for the module
    struct Config {
        enum Product {
            /// Produces a dynamic framework product
            case `dynamic`
            /// Produces a static framework product
            case `static`
            /// Allows us to use any of the valid product types. This should be used very rarely.
            case custom(ProjectDescription.Product)
            /// Defines the module as one that just wraps a Swift package. This will allow us to link a Swift package
            /// with multiple of our targets and not get duplicate symbol errors. The associated value should be the
            /// package target for the module to depend on.
            case wrapper([ProjectDescription.TargetDependency])
        }

        /// Objective-C headers.
        var headers: Headers?
        /// Any build phases that may need to be executed.
        var actions: [TargetScript] = []
        /// The dependencies of the module.
        var dependencies: [Dependency] = []
        /// Any additional resource files to be included (these will be in a module's resource bundle)
        var additionalFiles: [ResourceFileElement] = []
        /// The kind of product that should be produced by the module. Defaults to `static`. This should almost never be
        /// changed.
        var product: Product = .static
        /// Determines if there should be a resource bundle created for it. Only applies to static product
        /// types. Defaults to `true`.
        var hasResources: Bool = true
        /// Settings for the tests of a module. If a module has no tests then this should be nil. Tests are always
        /// assumed to be present.
        var testsConfig: TestConfig? = TestConfig()
        /// Any build settings to be applied to the module's resulting Xcode target.
        var settings: Settings = .settings()
    }
}
