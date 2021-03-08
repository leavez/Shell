//
//  File.swift
//  
//
//  Created by leave on 3/5/21.
//

import Foundation

/// - Parameters:
///   - executablePath: The absolute path to executable
///   - stdin: FileHandle or Pipe, if Pipe, it will automatically close
///   - stdout: FileHandle or Pipe
///   - stderr: FileHandle or Pipe
/// - Throws: CommandError
func runInner(_ executablePath: String, args: [String], stdin: Any?, stdout: Any?, stderr: Any?) throws -> (process: Process, waitGroup: DispatchGroup, waitFunc: ()->Void)
{
    let process = Process()
    process.arguments = args
    if #available(OSX 10.13, *) {
        process.executableURL = URL(fileURLWithPath: executablePath)
    } else {
        process.launchPath = executablePath
    }
    
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = stderr
    
    let group = DispatchGroup()
    process.terminationHandler = { _ in
        group.leave()
    }
    group.enter()
    if #available(OSX 10.13, *) {
        try process.run()
    } else {
        process.launch()
    }
    
    return (process: process, waitGroup: group, waitFunc: { group.wait() })
}

func lookupInPATH(file: String) -> String? {
    let PATH = String(utf8String: getenv("PATH")) ?? ""
    
    for dir in PATH.split(separator: ":") {
        let path = URL(fileURLWithPath: String(dir))
        let filePath = path.appendingPathComponent(file)
        let filePathString = filePath.path
        
        var directory: ObjCBool = ObjCBool(false)
        let exist = FileManager.default.fileExists(atPath: filePathString, isDirectory: &directory)
        if exist && !directory.boolValue {
            return filePathString
        }
    }
    return nil
}

extension Process {
    func visualization() -> String {
        let path: String
        if #available(OSX 10.13, *) {
            path = self.executableURL?.path ?? ""
        } else {
            path = self.launchPath ?? ""
        }
        return (self.arguments ?? []).reduce(path) { (acc: String, arg: String) in
            acc + " " + (arg.contains(" ") ? ("\"" + arg + "\"") : arg)
        }
    }
}
