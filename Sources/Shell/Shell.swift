
import Foundation

/// Run an executable with args
/// - Parameters:
///   - executable: the file path, or simply the filename and lookup in $PATH
public func run(_ executable: String, _ args: String ...) -> RunOutput {
    return run(executable, args: args)
}

/// Run an executable with args
public func run(_ executable: String, args: [String], otherParams: RunParams? = nil) -> RunOutput {
    // convert to absolute path
    var path = executable
    if !path.contains("/"), let found = lookupInPATH(file: executable) {
        path = found
    }
    
    // run
    let outPipe = Pipe()
    let errPipe = Pipe()
    
    var run: (process: Process, waitGroup: DispatchGroup, waitFunc: ()->Void)!
    do {
        run = try runInner(path, args: args, stdin: nil, stdout: outPipe, stderr: errPipe, otherParams: otherParams)
    } catch let err {
        return RunOutput(raw: .throwError(err))
    }
    let (process, group, waitFunc) = run
    
    let stdoutData = outPipe.fileHandleForReading.readDataToEndOfFile()
    var stderrData: Data!
    DispatchQueue.global().async(group: group) {
        stderrData = errPipe.fileHandleForReading.readDataToEndOfFile()
    }
    
    waitFunc()
    
    return RunOutput(
        raw: .finished(code: process.terminationStatus, stdout: stdoutData, stderr: stderrData),
        commandDescription: process.visualization()
    )
}

/// Run an executable with args, and print output to stdout/stderr
/// - Parameters:
///   - executable: the file path, or simply the filename and lookup in $PATH
/// - Throws: CommandError
public func runAndPrint(_ executable: String, _ args: String ...) throws {
    try runAndPrint(executable, args: args)
}

/// Run an executable with args, and print output to stdout/stderr
/// - Throws: CommandError
public func runAndPrint(_ executable: String, args: [String], otherParams: RunParams? = nil) throws {
    // convert to absolute path
    var path = executable
    if !path.contains("/"), let found = lookupInPATH(file: executable) {
        path = found
    }
    
    // run
    var run: (process: Process, waitGroup: DispatchGroup, waitFunc: ()->Void)!
    do {
        run = try runInner(path, args: args, stdin: nil, stdout: FileHandle.standardOutput, stderr: FileHandle.standardError, otherParams: otherParams)
    } catch let err {
        throw CommandError.launchFailed(err)
    }
    let (process, _, waitFunc) = run
    
    waitFunc()
    
    let exitCode = process.terminationStatus
    if exitCode != 0 {
        throw CommandError.returnedErrorCode(errorCode: exitCode, stderr: Data(), command: process.visualization())
    }
}

// -- bash script --

/// Run a bash script
public func run(bash script: String, _ args: String ...) -> RunOutput {
    return run(bash: script, args: args)
}

/// Run a bash script
public func run(bash script: String, args: [String], otherParams: RunParams? = nil) -> RunOutput {
    return run("/bin/bash", args: ["-c", script] + args, otherParams: otherParams)
}

/// Run a bash script, and print output to stdout/stderr
/// - Throws: CommandError
public func runAndPrint(bash script: String, _ args: String ...) throws {
    try runAndPrint(bash: script, args: args)
}

/// Run a bash script, and print output to stdout/stderr
/// - Throws: CommandError
public func runAndPrint(bash script: String, args: [String], otherParams: RunParams? = nil) throws {
    try runAndPrint("/bin/bash", args: ["-c", script] + args, otherParams: otherParams)
}

