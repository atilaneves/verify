module verify.reflection;


import verify.from;


shared static this() {
    import dmd.frontend: initDMD, findImportPaths, addImport;
    import std.algorithm: each;

    findImportPaths.each!addImport;
    initDMD;

    import dmd.globals: global;
    global.params.useUnitTests = true;
}

struct Code {
    string value;
}

struct FileName {
    string value;
}

from!"dmd.func".UnitTestDeclaration[] unitTests(T)(in T arg) @trusted {
    import dmd.globals: global;
    import std.algorithm: map, filter;
    import std.array: array;

    assert(global.params.useUnitTests);

    auto module_ = parseModule(arg);
    return module_
        .members
        .opSlice
        .map!(a => a.isUnitTestDeclaration)
        .filter!(a => a !is null)
        .array;
}


from!"dmd.dmodule".Module parseModule(T)(in T arg) @trusted {
    import dmd.frontend: fullSemantic, parseModule_ = parseModule;

    static if(is(T == FileName))
        auto ret = parseModule_(arg.value);
    else static if(is(T == Code))
        auto ret = parseModule_(string.init, arg.value);
    else
        static assert(false, "Unknown argument type " ~ T.stringof);

    assert(!ret.diagnostics.hasErrors);
    assert(!ret.diagnostics.hasWarnings);

    ret.module_.fullSemantic;

    return ret.module_;
}
