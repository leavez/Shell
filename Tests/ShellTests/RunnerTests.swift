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
        let (process, _ ,wait) = try runInner("/bin/bash", args: ["-c", "echo 123 >&1; echo 456 >&2"], stdin: nil, stdout: p1, stderr: p2, otherParams: nil)
        
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
        let (_, _ ,wait) = try runInner("/bin/bash", args: ["-c", "for i in {1..100000};do echo 1 >&2; done"], stdin: nil, stdout: FileHandle.nullDevice, stderr: p2, otherParams: nil)
        let errData = p2.fileHandleForReading.readDataToEndOfFile()
        wait()
        let output = String(repeating: "1\n", count: 100000)
        XCTAssertEqual(String(data: errData, encoding: .utf8), output)
    }
    
    func test_runInner_longTime() throws {
        let p2 = Pipe()
        let (_, _ ,wait) = try runInner("/bin/bash", args: ["-c", "echo 1; sleep 3; echo 2"], stdin: nil, stdout: p2, stderr: nil, otherParams: nil)
        let errData = p2.fileHandleForReading.readDataToEndOfFile()
        wait()
        XCTAssertEqual(String(data: errData, encoding: .utf8), "1\n2\n")
    }
    
    func test_runInner_error() throws {
        do {
            let (_, _ , _) = try runInner("/bin/bash1", args: ["1"], stdin: nil, stdout: FileHandle.nullDevice, stderr: nil, otherParams: nil)
            XCTAssertFalse(true)
        } catch let err {
            XCTAssertTrue(err is CocoaError)
            XCTAssertEqual(err.localizedDescription, "The file “bash1” doesn’t exist.")
        }
    }
    
    func test_runInner_moreParams() throws {
        var terminatedCalled = false
        var workspace = URL(fileURLWithPath: NSTemporaryDirectory()).path
        if !workspace.starts(with: "/private/") {
            workspace = "/private" + workspace
        }
        
        let params = RunParams(
            environment: ["PATH": "/bin"],
            currentDirectory: workspace,
            terminationHandler: { _ in
                terminatedCalled = true
            })
        
        let p1 = Pipe()
        let (_, _ , wait) = try runInner("/bin/bash", args: ["-c", "pwd; echo $PATH"], stdin: nil, stdout: p1, stderr: nil, otherParams: params)
        let outData = p1.fileHandleForReading.readDataToEndOfFile()
        wait()
        XCTAssertEqual(String(data: outData, encoding: .utf8), workspace + "\n/bin\n")
        XCTAssertEqual(terminatedCalled, true)
    }
}
