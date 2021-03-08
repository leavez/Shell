
import Foundation

public func run(_ executable: String, _ args: String ...) -> RunOutput {
    return run(executable, args: args)
}

public func run(_ executable: String, args: [String] ) -> RunOutput {
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
        run = try runInner(path, args: args, stdin: nil, stdout: outPipe, stderr: errPipe)
    } catch let err {
        return RunOutput(raw: .launchFailed(err))
    }
    let (process, group, waitFunc) = run
    
    let stdoutData = outPipe.fileHandleForReading.readDataToEndOfFile()
    var stderrData: Data!
    DispatchQueue.global().async(group: group) {
        stderrData = errPipe.fileHandleForReading.readDataToEndOfFile()
    }
    
    waitFunc()
    
    return RunOutput(
        raw: .returned(code: process.terminationStatus, stdout: stdoutData, stderr: stderrData),
        commandDescription: process.visualization()
    )
}

/// - Throws: CommandError
public func runAndPrint(_ executable: String, _ args: String ...) throws {
    try runAndPrint(executable, args: args)
}

/// - Throws: CommandError
public func runAndPrint(_ executable: String, args: [String]) throws {
    // convert to absolute path
    var path = executable
    if !path.contains("/"), let found = lookupInPATH(file: executable) {
        path = found
    }
    
    // run
    var run: (process: Process, waitGroup: DispatchGroup, waitFunc: ()->Void)!
    do {
        run = try runInner(path, args: args, stdin: nil, stdout: FileHandle.standardOutput, stderr: FileHandle.standardError)
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

public func run(bash script: String, _ args: String ...) -> RunOutput {
    return run(bash: script, args: args)
}

public func run(bash script: String, args: [String]) -> RunOutput {
    return run("/bin/bash", args: ["-c", script] + args)
}

/// - Throws: CommandError
public func runAndPrint(bash script: String, _ args: String ...) throws {
    try runAndPrint(bash: script, args: args)
}

public func runAndPrint(bash script: String, args: [String]) throws {
    try runAndPrint("/bin/bash", args: ["-c", script] + args)
}

