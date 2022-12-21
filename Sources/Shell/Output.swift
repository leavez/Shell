//
//  File.swift
//
//
//  Created by leave on 3/5/21.
//

import Foundation

/// The output of an execution.
/// To be convenient, we consider every command having a result. If a command failed
/// at launch, it will result in a special RunOutput
public final class RunOutput {
    
    /// Recommended to check the error before calling other methods
    public func error() -> CommandError? {
        switch raw {
        case .throwError(let err):
            return .launchFailed(err)
        case let .finished(code: code, stdout: _, stderr: errData):
            if code == 0 {
                return nil
            }
            return .returnedErrorCode(errorCode: code, stderr: errData ?? Data(), command: command())
        }
    }
    
    /// The terminated status of the command
    public private(set) lazy var exitCode: Int32 = {
        switch raw {
        case let .throwError(err):
            if let err = err as? CocoaError, err.code == CocoaError.fileNoSuchFile {
                return 127 // bash convention
            } else {
                return 256 // actually not returned, we give a fake code
            }
        case let .finished(code: code, stdout: _, stderr: _):
            return code
        }
    }()
    
    // Whether command executed successfully and exit code 0
    public var succeeded: Bool {
        if case let .finished(code, _, _) = raw {
            return code == 0
        }
        return false
    }
    
    /// Standard output data
    public var rawStdout: Data? {
        switch raw {
        case .throwError(_):
            return nil
        case .finished(code: _, stdout: let data, stderr: _):
            return data
        }
    }

    /// Standard error data
    public var rawStderr: Data? {
        switch raw {
        case .throwError(_):
            return nil
        case .finished(code: _, stdout: _, stderr: let data):
            return data
        }
    }
    
    // Standard output in string
    public private(set) lazy var stdout: String = {
        rawStdout.map{ stringOutput($0) } ?? ""
    }()

    // Standard error in string
    public private(set) lazy var stderror: String = {
        rawStderr.map{ stringOutput($0) } ?? ""
    }()
    
    /// Standard output, trimmed whitespace and newline
    public var stdoutTrimmed: String {
        stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Standard error, trimmed whitespace and newline
    public var stderrTrimmed: String {
        stderror.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func throwIfError() throws -> Self {
        if let err = error() {
            throw err
        }
        return self
    }
    
    // MAKR: -
    
    enum Result {
        case throwError(Error)
        case finished(code: Int32, stdout: Data?, stderr: Data?)
    }
    
    private let raw: Result
    private let command: ()->String?
    
    init(raw: Result, commandDescription: @escaping @autoclosure ()->String? = nil) {
        self.raw = raw
        self.command = commandDescription
    }
}

public enum CommandError: Error, LocalizedError, CustomStringConvertible {
    
    /** Command could not be executed. */
    case launchFailed(Error)
    
    /** Exit code was not zero. */
    case returnedErrorCode(errorCode: Int32, stderr: Data, command: String?)
    
    
    // -- CustomStringConvertible --
    
    public var description: String {
        switch self {
        case let .returnedErrorCode(code, stderr, command):
            let errorOutput = String(data: stderr, encoding: .utf8) ?? ""
            let c = command.map({ " '\($0)'"}) ?? ""
            return "Command\(c) exited with code \(code): \(errorOutput)"
        case let .launchFailed(err):
            return "Command launch failed: \(err.localizedDescription)"
        }
    }
    public var errorDescription: String? {
        description
    }
}



// Convert stream to string, trimmed if text is single-line
private func stringOutput(_ data: Data?) -> String {
    guard let data = data else {
        return ""
    }
    guard let result = String(data: data, encoding: .utf8) else {
        fatalError("Could not convert binary output of stdout to text using UFT8.")
    }
    return result
}
