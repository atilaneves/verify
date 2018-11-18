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


from!"dmd.func".UnitTestDeclaration[] unitTests(in string fileName) @trusted {
    import dmd.globals: global;
    import std.algorithm: map, filter;
    import std.array: array;

    assert(global.params.useUnitTests);

    auto module_ = parseModule(fileName);
    return module_
        .members
        .opSlice
        .filter!(a => a.isUnitTestDeclaration)
        .map!(a => a.isUnitTestDeclaration)
        .array;
}


from!"dmd.dmodule".Module parseModule(in string fileName) @trusted {
    import dmd.frontend: fullSemantic, parseModule_ = parseModule;

    auto ret = parseModule_(fileName);
    assert(!ret.diagnostics.hasErrors);
    assert(!ret.diagnostics.hasWarnings);

    ret.module_.fullSemantic;

    return ret.module_;
}
