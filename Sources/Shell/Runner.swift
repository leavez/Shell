//
//  File.swift
//  
//
//  Created by leave on 3/5/21.
//

import Foundation

public struct RunParams {
    /// Override the environment variables, or it will inherit current process's by default.
    public var environment: [String : String]?
    /// Set the working directory
    public var currentDirectory: String?
    /// TerminationHandler will call before sync run finished, in another thread.
    public var terminationHandler: ((Process) -> Void)?
    
    public init() {}
}



/// - Parameters:
///   - executablePath: The absolute path to executable
///   - stdin: FileHandle or Pipe, if Pipe, it will automatically close
///   - stdout: FileHandle or Pipe
///   - stderr: FileHandle or Pipe
/// - Throws: CommandError
func runInner(_ executablePath: String, args: [String], stdin: Any?, stdout: Any?, stderr: Any?, otherParams: RunParams?) throws -> (process: Process, waitGroup: DispatchGroup, waitFunc: ()->Void)
{
    let process = Process()
    process.arguments = args
    process.executableURL = URL(fileURLWithPath: executablePath)
    
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = stderr
    
    if let otherParams = otherParams {
        if let environment = otherParams.environment {
            process.environment = environment
        }
        if let currentDirectory = otherParams.currentDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)
        }
    }
    
    let group = DispatchGroup()
    process.terminationHandler = { _ in
        if let otherParams = otherParams, let handler = otherParams.terminationHandler {
            handler(process)
        }
        group.leave()
    }
    group.enter()
    try process.run()
    
    return (process: process, waitGroup: group, waitFunc: { group.wait() })
}

func lookupInPATH(file: String) -> String? {
    let PATH = ProcessInfo.processInfo.environment["PATH"] ?? ""
    
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
