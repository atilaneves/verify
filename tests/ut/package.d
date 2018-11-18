module ut;


public import unit_threaded;
public import verify.reflection: unitTests;
public import verify.interpreter: run;
public import verify.exception: TestFailure;


string testModulePath(in string path) @safe {
    import std.file: thisExePath;
    import std.path: buildNormalizedPath, dirName;
    return buildNormalizedPath(thisExePath.dirName, "..", "tests", "test_modules", path);
}


struct TestModule {
    alias sandbox this;

    string moduleName;
    Sandbox sandbox;
    static int counter;

    this(in string code) @safe inout {
        import std.conv: text;

        this.moduleName = text("mod", counter++);
        sandbox = inout Sandbox();
        sandbox.writeFile(moduleName ~ ".d", "module " ~ moduleName ~ ";\n" ~ code);
    }

    auto unitTests() @safe const {
        import verify.reflection: unitTests_ = unitTests;
        import std.file: chdir;

        chdir(sandbox.testPath);
        return unitTests_(moduleName);
    }
}
