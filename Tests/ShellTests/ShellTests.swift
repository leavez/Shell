import XCTest
@testable import Shell

final class ShellTests: XCTestCase {
    
    // --- test run ---
    
    func testShellRun_succeeded() {
        // -- absolute path --
        let r = Shell.run("/usr/bin/whoami")
        XCTAssertNil(r.error())
        XCTAssertEqual(r.exitCode, 0)
        XCTAssertEqual(r.stdout, NSUserName()+"\n")
        XCTAssertEqual(r.stderror, "")
        
        // -- just name --
        let r2 = Shell.run("whoami")
        XCTAssertNil(r2.error())
        XCTAssertEqual(r2.exitCode, 0)
        XCTAssertEqual(r2.stdout, NSUserName()+"\n")
        XCTAssertEqual(r2.stderror, "")
    }
    
    func testShellRun_multi_parameters() {
        let r = Shell.run("bash", "-c", "echo 123 >&1; echo 456 >&2")
        XCTAssertNil(r.error())
        XCTAssertEqual(r.exitCode, 0)
        XCTAssertEqual(r.stdout, "123\n")
        XCTAssertEqual(r.stderror, "456\n")
    }
    
    func testShellRun_not_found() {
        let r = Shell.run("thereShouldNotBeThisTool")
        if let err = r.error(), case let .launchFailed(innerErr) = err {
            XCTAssertTrue(innerErr.localizedDescription.contains("doesn’t exist"))
        } else {
            XCTAssertFalse(true)
        }
        XCTAssertEqual(r.exitCode, 127)
        XCTAssertEqual(r.stdout, "")
        XCTAssertEqual(r.stderror, "")
    }
    
    func testShellRun_return_non_zero() {
        #if os(macOS)
        let r = Shell.run("tar", "-c")
        XCTAssertEqual(r.exitCode, 1)
        XCTAssertEqual(r.stdout, "")
        XCTAssertTrue(r.stderror.contains("tar"))
        #endif
    }
    
    // --- test run and print ---
    
    func testRunAndPrint_succeed() throws {
        try Shell.runAndPrint("bash", "-c", "echo 123 >&1; echo 456 >&2")
    }
    
    func testRunAndPrint_not_found() throws {
        do {
            try Shell.runAndPrint("thereShouldNotBeThisTool", "1", "2")
            XCTAssertFalse(true)
        } catch let err  {
            if let err = err as? CommandError,
               case let .launchFailed(innerErr) = err {
                XCTAssertTrue(innerErr.localizedDescription.contains("doesn’t exist"), innerErr.localizedDescription)
            } else {
                XCTAssertFalse(true)
            }
        }
    }
    
    func testRunAndPrint_return_non_zero() throws {
        do {
            try Shell.runAndPrint("tar", "-c")
            XCTAssertFalse(true)
        } catch let err  {
            if let err = err as? CommandError,
               case let .returnedErrorCode(errorCode: code, stderr: data, command: command) = err {
                XCTAssertEqual(code, 1)
                XCTAssertEqual(command, "/usr/bin/tar -c")
                XCTAssertEqual(data.count, 0)
            } else {
                XCTAssertFalse(true)
            }
        }
    }
    
    // --- test run bash ---
 
    func testRunBash() throws {
        let r = Shell.run(bash: "echo 1 2")
        XCTAssertEqual(r.succeeded, true)
        XCTAssertEqual(r.stdout, "1 2\n")
        XCTAssertEqual(r.stdoutTrimmed, "1 2")
        XCTAssertEqual(r.stderror, "")
    }
    
    func testRunBash_parameters_position() throws {
        let r = Shell.run(bash: "echo $0 $1", "1", "2")
        XCTAssertEqual(r.succeeded, true)
        XCTAssertEqual(r.stdout, "1 2\n")
        XCTAssertEqual(r.stderror, "")
    }
    
    func testRunBash_not_fount() throws {
        let r = Shell.run(bash: "thereShouldNotBeThisTool 1")
        XCTAssertEqual(r.succeeded, false)
        XCTAssertEqual(r.stdout, "")
        XCTAssertTrue(r.stderror.contains("thereShouldNotBeThisTool: command not found"))
    }
    
    // --- test run bash and print ---

    func testRunBashAndPrint() throws {
        try Shell.runAndPrint(bash: "echo 1 2")
    }
    
    func testRunBashAndPrint_parameters_position() throws {
        try Shell.runAndPrint(bash: "echo $0 $1", "1", "2")
    }
    
    func testRunBashAndPrint_not_fount() throws {
        do {
            try Shell.runAndPrint(bash: "thereShouldNotBeThisTool 1")
            XCTAssertFalse(true)
        } catch let err  {
            if let err = err as? CommandError,
               case let .returnedErrorCode(errorCode: code, stderr: data, command: _) = err {
                XCTAssertEqual(code, 127)
                XCTAssertEqual(data.count, 0)
            } else {
                XCTAssertFalse(true)
            }
        }
    }
    
    func testRunBashAndPrint_non_zero() throws {
        do {
            try Shell.runAndPrint(bash: "exit 11")
            XCTAssertFalse(true)
        } catch let err  {
            if let err = err as? CommandError,
               case let .returnedErrorCode(errorCode: code, stderr: data, command: _) = err {
                XCTAssertEqual(code, 11)
                XCTAssertEqual(data.count, 0)
            } else {
                XCTAssertFalse(true)
            }
        }
    }
}
