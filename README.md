# Shell

Simple framework to run shell commands, fast.

```
// -- run and get result --
let output = Shell.run("ls")
if let err = output.error() {
    // including launch error or return non-zero code (with stderr as error message)
    throw err 
}
// output.exitCode
// output.stdout
// output.stderror

// -- run and print to stdout/stderr --
try Shell.runAndPrint("ls", "./")

// -- run bash script --
let output = Shell.run(bash: "ls")
try Shell.runAndPrint(bash: "ls ./")
```

## Why another shell framework?

`Shell` is highly inspired by [SwiftShell](https://github.com/kareman/SwiftShell) and copied a lot of code from it. So why another lib? The main reason is SwiftShell use `Process.waitUntilExit` and it [cause slow execution](https://github.com/kareman/SwiftShell/issues/101) for simple commands. SwiftShell is full featured and has a clear API. But when I fixing this problem, I feel its implementation a little bit complex for basic shell calls.  So `Shell` comes, with simple implementations and is easy to modify. It also provides a new error checking API, convenient for programs with a lot of shell interactions.

## License

MIT
