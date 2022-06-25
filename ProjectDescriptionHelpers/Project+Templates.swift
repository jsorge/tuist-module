import ProjectDescription

extension Project {
    /// Makes a project from the given array of modules
    /// - Parameters:
    ///   - projectName: The name of the project to be generated.
    ///   - modules: The modules to include in the project (each module is converted into its array of targets)
    ///   - additionalTargets: Additional targets to be added to the project which are not directly tied to a module
    ///   - packages: The Swift packages to include
    ///   - schemes: Custom schemes
    ///   - additionalFiles: Extra files to be added to the project
    ///   - settings: Any build settings to apply at the project level. These cascade down to targets.
    /// - Returns: The finished Xcode project
    public init(projectName: String, modules: Set<Module>, additionalTargets: [Target], packages: [Package],
                schemes: [Scheme], additionalFiles: [FileElement], settings: Settings = .settings())
    {
        var targets = modules.flatMap { $0.makeTargets() }
        targets.append(contentsOf: additionalTargets)

        let moduleSchemes = modules.map({ $0.makeScheme() }).flatMap({ $0 })
        let allSchemes = schemes + moduleSchemes

        self.init(
            name: projectName,
            packages: packages,
            settings: settings,
            targets: targets,
            schemes: allSchemes,
            additionalFiles: additionalFiles
        )
    }
}
