//
//  File.swift
//  
//
//  Created by leave on 3/8/21.
//

import XCTest
@testable import Shell

final class RunnerTests: XCTestCase {
    
    func test_LookupInPATH() {
        XCTAssertNotNil(lookupInPATH(file: "bash"))
        XCTAssertNotNil(lookupInPATH(file: "cp"))
        XCTAssertNil(lookupInPATH(file: "cp11111"))
        XCTAssertEqual(lookupInPATH(file: "whoami"), "/usr/bin/whoami")
    }

    func test_runInner() throws {
        let p1 = Pipe()
        let p2 = Pipe()
        let (process, _ ,wait) = try runInner("/bin/bash", args: ["-c", "echo 123 >&1; echo 456 >&2"], stdin: nil, stdout: p1, stderr: p2)
        
        let outData = p1.fileHandleForReading.readDataToEndOfFile()
        let errData = p2.fileHandleForReading.readDataToEndOfFile()
        wait()

        XCTAssertEqual(process.executableURL?.path, "/bin/bash")
        XCTAssertEqual(process.isRunning, false)
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(String(data: outData, encoding: .utf8), "123\n")
        XCTAssertEqual(String(data: errData, encoding: .utf8), "456\n")
    }
    
    
    func test_runInner_longOutput() throws {
        let p2 = Pipe()
        let (_, _ ,wait) = try runInner("/bin/bash", args: ["-c", "for i in {1..100000};do echo 1 >&2; done"], stdin: nil, stdout: FileHandle.nullDevice, stderr: p2)
        let errData = p2.fileHandleForReading.readDataToEndOfFile()
        wait()
        let output = String(repeating: "1\n", count: 100000)
        XCTAssertEqual(String(data: errData, encoding: .utf8), output)
    }
    
    func test_runInner_error() throws {
        do {
            let (_, _ , _) = try runInner("/bin/bash1", args: ["1"], stdin: nil, stdout: FileHandle.nullDevice, stderr: nil)
            XCTAssertFalse(true)
        } catch let err {
            if let err = err as? CommandError, case let .launchFailed(innerError) = err {
                XCTAssertEqual(innerError.localizedDescription, "The file “bash1” doesn’t exist.")
            } else {
                XCTAssertFalse(true)
            }
        }
    }
    
    func test_CommandError() {
        let err: Error = CommandError.returnedErrorCode(errorCode: 11, stderr: Data(), command: nil)
        XCTAssertEqual(err.localizedDescription, "Command exited with code 11: ")
    }
}
