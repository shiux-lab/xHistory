//
//  main.swift
//  xhistory
//
//  Created by apple on 2024/11/6.
//
import ArgumentParser
import Foundation

struct xhistory: ParsableCommand {
    static var configuration = CommandConfiguration(version: "0.1.0")
    
    @Flag(name: .shortAndLong, help: "Read the history file for the current session")
    var session: Bool = false
    
    @Option(name: .shortAndLong, help: ArgumentHelp("Get custom shell configuration", valueName: "bash|zsh"))
    var config: String? = nil

    @Option(name: .shortAndLong, help: "Read the specified history file")
    var file: String? = nil
    
    mutating func validate() throws {
        if session == true && file != nil {
            throw ValidationError("Options -c and -f cannot be used together!")
        }
    }

    mutating func run() throws {
        if session {
            openCustomURLWithActiveWindowGeometry(file: ProcessInfo.processInfo.environment["HISTFILE"])
            return
        }
        if let shell = config {
            guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
            let plistPath = appSupportDir.appendingPathComponent("xHistory/shellConfig.plist").path
            if let config = readPlistValue(filePath: plistPath, key: "customShellConfig") as? Bool, config {
                if let value = readPlistValue(filePath: plistPath, key: "historyLimit") { print("export HISTSIZE=\(value)") }
                if let value = readPlistValue(filePath: plistPath, key: "realtimeSave") as? Bool, value {
                    if shell == "bash" { print("export PROMPT_COMMAND=\"history -a\"") }
                    if shell == "zsh" { print("setopt INC_APPEND_HISTORY") }
                }
                if let value = readPlistValue(filePath: plistPath, key: "noDuplicates") as? Bool, value {
                    if shell == "bash" { print("export HISTCONTROL=ignoredups") }
                    if shell == "zsh" { print("setopt HIST_IGNORE_DUPS") }
                }
            }
            return
        }
        openCustomURLWithActiveWindowGeometry(file: file)
    }
}

xhistory.main()
