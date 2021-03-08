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
        case .launchFailed(let err):
            if let err = err as? CommandError {
                return err
            }
            return .otherLaunchFailed(err)
        case let .returned(code: code, stdout: _, stderr: errData):
            if code == 0 {
                return nil
            }
            return .returnedErrorCode(errorCode: code, stderr: errData ?? Data(), command: commandDescription())
        }
    }
    
    /// The terminated status of the command
    public private(set) lazy var exitCode: Int32 = {
        switch raw {
        case .launchFailed(_):
            return 256
        case let .returned(code: code, stdout: _, stderr: _):
            return code
        }
    }()
    
    // Whether command executed successfully and exit code 0
    public var succeeded: Bool {
        exitCode == 0
    }
    
    // Standard output in string
    public private(set) lazy var stdout: String = {
        switch raw {
        case .launchFailed(_):
            return ""
        case .returned(code: _, stdout: let data, stderr: _):
            return stringOutput(data)
        }
    }()

    // Standard error in string
    public private(set) lazy var stderror: String = {
        switch raw {
        case .launchFailed(_):
            return ""
        case .returned(code: _, stdout: _, stderr: let data):
            return stringOutput(data)
        }
    }()
    
    /// Standard output, trimmed whitespace and newline
    public var stdoutTrimmed: String {
        stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Standard error, trimmed whitespace and newline
    public var stderrTrimmed: String {
        stderror.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MAKR: -
    
    enum RawResult {
        case launchFailed(Error)
        case returned(code: Int32, stdout: Data?, stderr: Data?)
    }
    
    private let raw: RawResult
    private let commandDescription: ()->String?
    
    init(raw: RawResult, commandDescription: @escaping @autoclosure ()->String? = nil) {
        self.raw = raw
        self.commandDescription = commandDescription
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
