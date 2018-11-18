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
