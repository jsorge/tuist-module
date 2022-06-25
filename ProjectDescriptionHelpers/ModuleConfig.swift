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
    public struct Config {
        public enum Product {
            /// Produces a dynamic framework product
            case `dynamic`
            /// Produces a static framework product
            case `static`
            /// Allows us to use any of the valid product types.
            case custom(ProjectDescription.Product)
            /// Defines the module as one that just wraps a Swift package. This will allow us to link a Swift package
            /// with multiple of our targets and not get duplicate symbol errors. The associated value should be the
            /// package target for the module to depend on.
            case wrapper([ProjectDescription.TargetDependency])
        }

        /// The kind of product that should be produced by the module. Defaults to `static`.
        var product: Product = .static
        /// The dependencies of the module.
        var dependencies: [Dependency] = []
        /// Objective-C headers.
        var headers: Headers?
        /// Any build phases that may need to be executed.
        var actions: [TargetScript] = []
        /// Any additional resource files to be included (these will be in a module's resource bundle)
        var additionalFiles: [ResourceFileElement] = []
        /// Determines if there should be a resource bundle created for it. Only applies to static product
        /// types. Defaults to `true`.
        var hasResources: Bool = true
        /// Settings for the tests of a module. If a module has no tests then this should be nil. Tests are always
        /// assumed to be present.
        var testsConfig: TestConfig? = TestConfig()
        /// Any build settings to be applied to the module's resulting Xcode target.
        var settings: Settings = .settings()


        public init(
            product: Module.Config.Product = .static,
            dependencies: [Dependency] = [],
            headers: Headers? = nil,
            actions: [TargetScript] = [],
            additionalFiles: [ResourceFileElement] = [],
            hasResources: Bool = true,
            testsConfig: Module.TestConfig? = TestConfig(),
            settings: Settings = .settings()
        ) {
            self.product = product
            self.dependencies = dependencies
            self.headers = headers
            self.actions = actions
            self.additionalFiles = additionalFiles
            self.hasResources = hasResources
            self.testsConfig = testsConfig
            self.settings = settings
        }
    }
}
