import Foundation
import ProjectDescription

extension TargetScript {
    /// Removes the executable from a resource bundle target as a post-build action.
    public static var removeBundleExecutable: TargetScript {
        return .post(
            script: """
              FILE="${BUILT_PRODUCTS_DIR}/${TARGET_NAME}.bundle/${TARGET_NAME}"
              if [[ -f $FILE ]];then
                  rm "$FILE"
              fi
              """,
            name: "Remove Embedded Executable"
        )
    }
}
