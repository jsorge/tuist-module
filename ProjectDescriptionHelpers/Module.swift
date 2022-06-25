import Foundation
import ProjectDescription

/// A type that represents a code module, which can compose into Xcode targets and tests.
public struct Module: Hashable {
    /// The name of the module
    let name: ModuleName
    /// Configuration options used when generating the module's main target
    let config: Config

    public init(name: ModuleName, config: Config = Config()) {
        self.name = name
        self.config = config
    }

    var targetReference: TargetReference {
        return TargetReference(projectPath: nil, target: name.name)
    }

    var testableTarget: TestableTarget {
        let reference = TargetReference(projectPath: nil, target: name.tests.name)
        return TestableTarget(target: reference)
    }

    var isPackageWrapper: Bool {
        return wrappedPackgeDependency != nil
    }

    var wrappedPackgeDependency: [TargetDependency]? {
        if case Config.Product.wrapper(let dependency) = config.product {
            return dependency
        }

        return nil
    }

    /// A complete list of the target dependencies of this module, including transitive ones.
    var resolvedDependencies: [TargetDependency] {
        if isPackageWrapper {
            return []
        }

        let moduleDeps = config.dependencies.compactMap({ dep -> Module? in
            switch dep {
            case .module(let module):
                return module
            default:
                return nil
            }
        })

        let moduleTargetDeps = moduleDeps
            .map({ TargetDependency.moduleName($0.name) })

        let transitiveDeps = moduleDeps
            .filter({ $0.isPackageWrapper == false })
            .flatMap({ $0.resolvedDependencies })

        let targetDeps = config.dependencies.compactMap({ dep -> TargetDependency? in
            switch dep {
            case .target(let targetDep):
                return targetDep
            default:
                return nil
            }
        })

        var allDeps = moduleTargetDeps + transitiveDeps + targetDeps
        if config.hasResources {
            allDeps.append(.moduleName(self.name.resources))
        }

        let filteredDeps = allDeps.removingDuplicates()
        return filteredDeps
    }

    /// Makes the targets needed for a module
    /// - Returns: The array of targets to be used in an Xcode project
    func makeTargets() -> [Target] {
        var targets: [Target?] = [
            Target.target(forModule: self),
        ]

        if config.hasResources {
            targets.append(Target.resourceTarget(for: self))
        }

        if config.testsConfig != nil {
            targets.append(Target.testTarget(for: self))
        }

        return targets.compactMap { $0 }
    }

    func makeScheme() -> [Scheme] {
        let scheme = Scheme(
            name: name.name,
            shared: true,
            hidden: true,
            buildAction: BuildAction(
                targets: [
                    targetReference,
                ],
                preActions: [],
                postActions: []
            ),
            testAction: .targets([
                testableTarget,
            ])
        )

        var resourceScheme: Scheme?
        if config.hasResources {
            resourceScheme = Scheme(
                name: "\(name.name)Resources",
                hidden: true
            )
        }

        return [scheme, resourceScheme].compactMap { $0 }
    }

    public static func == (lhs: Module, rhs: Module) -> Bool {
        return lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

private extension Module.Config.Product {
    var xcodeProduct: Product {
        switch self {
        case .dynamic, .wrapper:
            return ProjectDescription.Product.framework
        case .static:
            return ProjectDescription.Product.staticFramework
        case .custom(let product):
            return product
        }
    }

    var isStatic: Bool {
        switch self {
        case .dynamic, .wrapper:
            return false
        case .static:
            return true
        case .custom(let product):
            return product == .staticLibrary || product == .staticFramework
        }
    }
}

private extension Target {
    static func target(forModule module: Module) -> Target
    {
        if let deps = module.wrappedPackgeDependency {
            return Target(
                name: module.name.name,
                platform: .iOS,
                product: .framework,
                bundleId: .bundleID(from: module.name),
                infoPlist: .default,
                scripts: module.config.actions,
                dependencies: deps,
                settings: .settings(base: frameworkWrapperSettings)
            )
        }

        let config = module.config
        let resources: ResourceFileElements?
        if module.config.product.isStatic == false {
            resources = ResourceFileElements(resources: [
                .glob(pattern: Path.resourcesPath(for: module.name).globbing),
            ])
        } else {
            resources = nil
        }

        return Target(
            name: module.name.name,
            platform: .iOS,
            product: config.product.xcodeProduct,
            bundleId: .bundleID(from: module.name),
            infoPlist: .default,
            sources: SourceFilesList(globs: [
                SourceFileGlob.glob(Path.sourcesPath(for: module.name).globbing),
            ]),
            resources: resources,
            headers: config.headers,
            scripts: config.actions,
            dependencies: module.resolvedDependencies,
            settings: config.settings,
            additionalFiles: [
                .glob(pattern: .modulePath(for: module.name).appending("README.md"))
            ]
        )
    }

    static func testTarget(for module: Module) -> Target? {
        guard module.isPackageWrapper == false else {
            return nil
        }

        let moduleName = module.name

        guard let config = module.config.testsConfig else { return nil }

        var dependencies = config.dependencies
        dependencies.append(.moduleName(moduleName))

        var resources: [ResourceFileElement] = []
        if config.hasResources {
            resources = [
                .glob(pattern: Path.modulePath(for: moduleName).appending("TestResources").globbing)
            ]
        }

        let sourceGlobs = config.additionalSources + [
            SourceFileGlob.glob(Path.testsPath(for: moduleName).globbing),
        ]

        if module.config.product.isStatic {
            dependencies.append(contentsOf: module.resolvedDependencies)
        }

        if module.config.hasResources {
            dependencies.append(.moduleName(module.name.resources))
        }

        dependencies = dependencies.removingDuplicates()

        let additionalPlistProperties: [String: InfoPlist.Value] = config.additionalInfoPlistProperties

        return Target(
            name: moduleName.tests.name,
            platform: .iOS,
            product: .unitTests,
            bundleId: .bundleID(from: moduleName.tests),
            infoPlist: InfoPlist.extendingDefault(with: additionalPlistProperties),
            sources: SourceFilesList(globs: sourceGlobs),
            resources: ResourceFileElements(resources: resources),
            dependencies: dependencies,
            settings: config.buildSettings
        )
    }

    static func resourceTarget(for module: Module) -> Target? {
        guard module.isPackageWrapper == false else {
            return nil
        }

        guard
            module.config.product.isStatic,
            module.config.hasResources
        else { return nil }

        let additionalFiles = module.config.additionalFiles
        let moduleName = module.name

        var allResources = additionalFiles
        allResources.append(.glob(pattern: Path.resourcesPath(for: moduleName).globbing))

        return Target(
            name: moduleName.resources.name,
            platform: .iOS,
            product: .bundle,
            bundleId: .bundleID(from: moduleName.resources),
            resources: ResourceFileElements(resources: allResources),
            scripts: [
                .removeBundleExecutable,
            ]
        )
    }
}

private let frameworkWrapperSettings: SettingsDictionary = [
    "SKIP_INSTALL": .string("YES")
]
