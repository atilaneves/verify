module ut.assertions;

import ut;


@("assert.literal.bool")
@safe unittest {
    auto tests = unitTests(
        Code(
             q{
                 unittest {}
                 unittest { assert(false); }
                 unittest {}
             }
        )
    );

    tests[0].run;
    tests[1].run.shouldThrowWithMessage!TestFailure("Failure: `false`");
    tests[2].run;
}


@("assert.literal.int")
@safe unittest {
    auto tests = unitTests(
        Code(
            q{
                unittest { assert(0); }
                unittest { assert(42); }
            }
        )
    );
    tests[0].run.shouldThrowWithMessage!TestFailure("Failure: `0`");
    tests[1].run;
}


@("assert.literal.sum")
@safe unittest {
    auto tests = unitTests(
        Code(
            q{
                unittest { assert(1 + 1); }
                unittest { assert(1 - 1); }
            }
        )
    );

    tests[0].run;
    tests[1].run.shouldThrowWithMessage!TestFailure("Failure: `0`");
}


@("assert.literal.equals")
@safe unittest {
    auto tests = unitTests(
        Code(
            q{
                 unittest { assert(1 == 3); }
            }
        )
    );

    tests[0].run.shouldThrowWithMessage!TestFailure("Failure: `false`");
}


@("assert.equals.function.constant")
@safe unittest {
    auto tests = unitTests(
        Code(
             q{
                 int five() { return 5; }
                 unittest { assert(five() == 3); }
                 unittest { assert(five() == 5); }
             }
        )
    );

    tests[0].run.shouldThrowWithMessage!TestFailure("Expected: 3  Got: 5");
    tests[1].run;
}


@("assert.not.equals.function.constant")
@safe unittest {
    auto tests = unitTests(
        Code(
             q{
                 int five() { return 5; }
                 unittest { assert(five() != 5); }
                 unittest { assert(five() != 3); }
             }
        )
    );

    tests[0].run.shouldThrowWithMessage!TestFailure("Failure: 5 == 5");
    tests[1].run;
}


@("assert.equals.function.expression.one")
@safe unittest {
    auto tests = unitTests(
        Code(
             q{
                 int add1(int i, int j) { return i + j + 1; }
                 unittest { assert(add1(2, 3) == 7); }
                 unittest { assert(add1(1, 1) == 3); }
             }
        )
    );

    tests[0].run.shouldThrowWithMessage!TestFailure("Expected: 7  Got: 6");
    tests[1].run;
}
