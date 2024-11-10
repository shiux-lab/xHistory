//
//  CommandLineTool.swift
//  xHistory
//
//  Created by apple on 2024/11/10.
//

import Foundation

class CommandLineTool {
    static func runAsRoot(_ command: String, completion: (() -> Void)? = nil) {
        let script = "do shell script \"\(command)\" with administrator privileges"
        var error: NSDictionary?
        
        if let scriptObject = NSAppleScript(source: script) {
            let _ = scriptObject.executeAndReturnError(&error)
            
            if error == nil {
                completion?()
            } else {
                print("Error executing command: \(String(describing: error))")
            }
        }
    }
    
    static func isInstalled() -> Bool {
        let attributes = try? fd.attributesOfItem(atPath: "/usr/local/bin/xhistory")
        return attributes?[.type] as? FileAttributeType == .typeSymbolicLink
    }
    
    static func install(action: (() -> Void)? = nil) {
        if let resourceURL = Bundle.main.resourceURL {
            let xhPath = resourceURL.appendingPathComponent("xh").path
            if !fd.fileExists(atPath: "/usr/local/bin") {
                runAsRoot("/bin/mkdir -p /usr/local/bin;/bin/ln -s '\(xhPath)' /usr/local/bin/xhistory") {
                    action?()
                }
            } else {
                runAsRoot("/bin/ln -s '\(xhPath)' /usr/local/bin/xhistory") {
                    action?()
                }
            }
        }
    }
    
    static func uninstall(action: (() -> Void)? = nil) {
        runAsRoot("/bin/rm /usr/local/bin/xhistory") { action?() }
    }
}
