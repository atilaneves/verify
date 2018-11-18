module verify.interpreter;


import verify.from;


void run(from!"dmd.func".UnitTestDeclaration test) @safe {
    scope auto interpreter = new UnitTestInterpreter();
    () @trusted { test.accept(interpreter); }();
}


void log(A...)(auto ref A args) {
    import unit_threaded: writelnUt;
    import std.functional: forward;
    writelnUt(forward!args);
}


private extern (C++) final class UnitTestInterpreter: from!"dmd.visitor".Visitor
{
    import dmd.visitor: Visitor;
    import dmd.statement;
    import dmd.expression;
    import dmd.func;
    import dmd.dscope: Scope;

    alias visit = Visitor.visit;

    Scope* _scope;

    override void visit(UnitTestDeclaration test) {
        log("\n");
        log("Unit test decl ", test.ident);
        _scope = test._scope;
        test.fbody.accept(this);
    }

    override void visit(CompoundStatement compound) {
        log("    Compound statement of ", compound.statements is null ? 0 : compound.statements.dim);
        if(compound.statements is null) return;
        foreach(statement; compound.statements.opSlice)
            statement.accept(this);
    }

    override void visit(ExpStatement statement) {
        log("        ExpStatement @ ", statement.loc.tostring, ": '", statement.tostring, "'");
        if(statement.exp is null) return;
        statement.exp.accept(this);
    }

    override void visit(AssertExp assertion) {
        assert(_scope !is null);

        log("            AssertExp @ ", assertion.loc.tostring, ": '", assertion.tostring, "'");
        log("            AssertExp e1: '", assertion.e1.tostring, "'");

        assertion.e1.accept(this);
    }

    // booleans are included here
    override void visit(IntegerExp expression) {
        import verify.exception: TestFailure;
        import std.conv: text;

        log("            IntegerExp: '", expression.tostring, "'");

        if(!expression.toInteger)
            throw new TestFailure(text("Failure: `", expression.tostring, "`"));
    }
}


private auto tostring(T)(auto ref T obj) {
    import std.string: fromStringz, strip;
    return obj.toChars.fromStringz.strip;
}
