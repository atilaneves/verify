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
    Expression result;

    final Expression eval(Expression expression) {
        expression.accept(this);
        return result;
    }

    final Expression eval(Statement statement) {
        statement.accept(this);
        return result;
    }

    override void visit(Expression expression) {
        import std.conv: text;
        throw new Exception(text("Dunno how to handle expression '", expression.tostring, "'"));
    }

    override void visit(Statement statement) {
        import std.conv: text;
        throw new Exception(text("Dunno how to handle statement '", statement.tostring, "'"));
    }

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
        import verify.exception: TestFailure;
        import std.conv: text;

        assert(_scope !is null);

        log("            AssertExp @ ", assertion.loc.tostring, ": '", assertion.tostring, "'");
        log("            AssertExp e1: '", assertion.e1.tostring, "'");

        assertion.e1.accept(this);

        if(result is null)
            throw new Exception("No result to check");

        if(!result.toInteger)
             throw new TestFailure(text("Failure: `", result.tostring, "`"));
    }

    // booleans are included here
    override void visit(IntegerExp expression) {
        log("            IntegerExp: '", expression.tostring, "'");
        result = expression;
    }

    override void visit(EqualExp expression) {
        import verify.exception: TestFailure;
        import std.conv: text;

        // TODO: need to handle both expression.op == TOK.equal and TOK.notEqual
        log("            EqualExp: '", expression.tostring, "' op: ", expression.op);
        log("                e1: '", expression.e1.tostring, "'  op: ", expression.e1.op);
        log("                e2: '", expression.e2.tostring, "'  op: ", expression.e2.op);

        auto lhs = eval(expression.e1);
        auto rhs = eval(expression.e2);

        if(lhs != rhs)
            throw new TestFailure(text("Expected: ", lhs, "  Got: ", rhs));
    }

    override void visit(CallExp expression) {
        // TODO: function arguments
        result = eval(expression.f.fbody);
    }

    override void visit(ReturnStatement statement) {
        log("            Return statement: '", statement.tostring, "'");
        result = eval(statement.exp);
    }
}


private auto tostring(T)(auto ref T obj) {
    import std.string: fromStringz, strip;
    static if(__traits(compiles, obj is null))
        return obj is null ? "null" : obj.toChars.fromStringz.strip;
    else
        return obj.toChars.fromStringz.strip;
}
