module verify.interpreter;


import verify.from;


void run(from!"dmd.func".UnitTestDeclaration test) @safe {
    scope auto interpreter = new UnitTestInterpreter();
    () @trusted { test.accept(interpreter); }();
}

void log(A...)(UnitTestInterpreter self, auto ref A args) {
    import unit_threaded: writelnUt;
    import std.functional: forward;
    writelnUt(self._indentation, forward!args);
}


private extern (C++) final class UnitTestInterpreter: from!"dmd.visitor".Visitor
{
    import dmd.visitor: Visitor;
    import dmd.statement;
    import dmd.expression;
    import dmd.func;
    import dmd.dscope: Scope;

    alias visit = Visitor.visit;

    private Scope* _scope;
    Expression result;
    private string _indentation;
    private Expression[string] _bindings;

    void indent() {
        _indentation = _indentation ~ "    ";
    }

    void deindent() {
        if(_indentation.length >= 4)
            _indentation.length -= 4;
    }

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
        _indentation = "";
        this.log("\n");
        this.log("Unit test decl ", test.ident);
        _scope = test._scope;
        test.fbody.accept(this);
    }

    override void visit(CompoundStatement compound) {
        // indent; scope(exit) deindent;
        // this.log("Compound statement of ", compound.statements is null ? 0 : compound.statements.dim);
        if(compound.statements is null) return;
        foreach(statement; compound.statements.opSlice)
            statement.accept(this);
    }

    override void visit(ExpStatement statement) {
        indent; scope(exit) deindent;
        this.log("ExpStatement @ ", statement.loc.tostring, ": '", statement.tostring, "'");
        if(statement.exp is null) return;
        statement.exp.accept(this);
    }

    override void visit(AssertExp assertion) {
        import verify.exception: TestFailure;
        import std.conv: text;

        assert(_scope !is null);
        indent; scope(exit) deindent;

        this.log("AssertExp @ ", assertion.loc.tostring, ": '", assertion.tostring, "'");
        this.log("AssertExp e1: '", assertion.e1.tostring, "'");

        assertion.e1.accept(this);

        if(result is null)
            throw new Exception("No result to check");

        if(!result.toInteger)
             throw new TestFailure(text("Failure: `", result.tostring, "`"));
    }

    // booleans are included here
    override void visit(IntegerExp expression) {
        this.log("IntegerExp: '", expression.tostring, "'");
        result = expression;
    }

    override void visit(EqualExp expression) {
        import verify.exception: TestFailure;
        import dmd.tokens: TOK;
        import std.conv: text;

        indent; scope(exit) deindent;

        this.log("EqualExp: '", expression.tostring, "' op: ", expression.op);
        this.log("    e1: '", expression.e1.tostring, "'  op: ", expression.e1.op);
        this.log("    e2: '", expression.e2.tostring, "'  op: ", expression.e2.op);

        auto lhs = eval(expression.e1);
        auto rhs = eval(expression.e2);

        this.log("EqualExp lhs: ", lhs);
        this.log("EqualExp rhs: ", rhs);
        this.log("EqualExp lhs == rhs ? ", lhs == rhs);

        if(expression.op == TOK.equal && !lhs.equals(rhs))
            throw new TestFailure(text("Expected: ", rhs, "  Got: ", lhs));

        if(expression.op == TOK.notEqual && lhs.equals(rhs))
            throw new TestFailure(text("Failure: ", lhs, " == ", rhs));

    }

    override void visit(CallExp expression) {
        // TODO: function arguments
        indent; scope(exit) deindent;
        const numArgs = expression.arguments ? expression.arguments.dim : 0;
        this.log("CallExp: '", expression, "'  # args: ", numArgs);
        this.log("  FunctionDecl: ", expression.f, "  params: ", expression.f.parameters ? expression.f.parameters.tostring : "");
        if(numArgs > 0) {
            foreach(i, arg; expression.arguments.opSlice) {
                this.log("  arg", i, ": ", arg);
                // FIXME must support same names in different stack frames
                _bindings[(*expression.f.parameters)[i].ident.toString] = arg;
            }
        }

        scope(exit)  {
            if(numArgs > 0) {
                foreach(param; expression.f.parameters.opSlice) {
                    // FIXME must support same names in different stack frames
                    _bindings.remove(param.toString.idup);
                }
            }
        }

        this.log("  bindings: ", _bindings);
        result = eval(expression.f.fbody);
    }

    override void visit(ReturnStatement statement) {
        indent; scope(exit) deindent;
        this.log("Return statement: '", statement.tostring, "'");
        result = eval(statement.exp);
    }

    override void visit(AddExp expression) {
        import dmd.mtype: Type;

        indent; scope(exit) deindent;
        this.log("AddExp: '", expression, "' op: ", expression.op);
        this.log("  e1: '", expression.e1, "'");
        this.log("  e2: '", expression.e2, "'");

        auto lhs = eval(expression.e1); assert(lhs, "Could not evaluate lhs");
        auto rhs = eval(expression.e2); assert(rhs, "Could not evaluate rhs");
        this.log("  lhs: ", lhs);
        this.log("  rhs: ", rhs);

        assert(lhs.type.isintegral && rhs.type.isintegral,
               "Only integer addition is supported for now");

        // FIXME - tint32?
        result = new IntegerExp(expression.loc, lhs.toInteger + rhs.toInteger, Type.tint32);
    }

    override void visit(VarExp expression) {
        import dmd.mtype: Type;

        indent; scope(exit) deindent;
        this.log("VarExp: '", expression, "'");

        // FIXME - call stack frames
        result = _bindings[expression.var.ident.toString];
    }
}


private auto tostring(T)(auto ref T obj) {
    import std.string: fromStringz, strip;
    static if(__traits(compiles, obj is null))
        return obj is null ? "null" : obj.toChars.fromStringz.strip;
    else
        return obj.toChars.fromStringz.strip;
}
