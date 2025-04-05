import Foundation
import SwiftUI

struct InfoPlistTest {
    static func checkCameraPermissionValue() -> String? {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            print("ERROR: Could not access Info.plist dictionary")
            return nil
        }
        
        let cameraPermissionKey = "NSCameraUsageDescription"
        if let cameraPermission = infoDictionary[cameraPermissionKey] as? String {
            print("SUCCESS: Found camera permission string: \(cameraPermission)")
            return cameraPermission
        } else {
            print("ERROR: NSCameraUsageDescription not found in Info.plist")
            return nil
        }
    }
    
    static func printAllInfoPlistValues() {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            print("ERROR: Could not access Info.plist dictionary")
            return
        }
        
        print("INFO PLIST CONTENTS:")
        for (key, value) in infoDictionary {
            print("  \(key): \(value)")
        }
    }
} 