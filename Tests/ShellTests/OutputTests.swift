//
//  File.swift
//  
//
//  Created by leave on 3/8/21.
//

import XCTest
@testable import Shell

extension String: LocalizedError {
    public var errorDescription: String? {
        return self
    }
}

final class OutputTests: XCTestCase {
    
    func test_RunOutput_errored() {
        let r = RunOutput(raw: .throwError("dd"))
        if let err = r.error(), case let .launchFailed(innerErr) = err {
            XCTAssertEqual(innerErr.localizedDescription, "dd")
        } else {
            XCTAssertFalse(true)
        }
        XCTAssertEqual(r.exitCode, 256)
        XCTAssertFalse(r.succeeded)
        XCTAssertEqual(r.stdout, "")
        XCTAssertEqual(r.stderror, "")
        XCTAssertEqual(r.stdoutTrimmed, "")
        XCTAssertEqual(r.stderrTrimmed, "")
    }
    
    func test_RunOutput_succeeded() {
        let r = RunOutput(raw: .finished(code: 0, stdout: "123\n".data(using: .utf8), stderr: "456\n".data(using: .utf8)))
        XCTAssertNil(r.error())
        XCTAssertEqual(r.exitCode, 0)
        XCTAssertTrue(r.succeeded)
        XCTAssertEqual(r.stdout, "123\n")
        XCTAssertEqual(r.stderror, "456\n")
        XCTAssertEqual(r.stdoutTrimmed, "123")
        XCTAssertEqual(r.stderrTrimmed, "456")
    }
    
    func test_RunOutput_failed() {
        let r = RunOutput(raw: .finished(code: 10, stdout: "123\n".data(using: .utf8), stderr: "456\n".data(using: .utf8)), commandDescription: "i'm the king")
        if let err = r.error(), case let .returnedErrorCode(errorCode: code, stderr: errData, command: command) = err {
            XCTAssertEqual(r.exitCode, code)
            XCTAssertEqual(command, "i'm the king")
            XCTAssertEqual(String(data: errData, encoding: .utf8), "456\n")
        } else {
            XCTAssertFalse(true)
        }
        XCTAssertEqual(r.exitCode, 10)
        XCTAssertTrue(!r.succeeded)
        XCTAssertEqual(r.stdout, "123\n")
        XCTAssertEqual(r.stderror, "456\n")
        XCTAssertEqual(r.stdoutTrimmed, "123")
        XCTAssertEqual(r.stderrTrimmed, "456")
    }
    
    func test_CommandError() {
        let err: Error = CommandError.returnedErrorCode(errorCode: 11, stderr: Data(), command: nil)
        XCTAssertEqual(err.localizedDescription, "Command exited with code 11: ")
    }
}
