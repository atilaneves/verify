module ut.assertions;

import ut;


@("assert.literal.bool")
@safe unittest {
    with(const TestModule(
             q{
                 unittest {}
                 unittest { assert(false); }
                 unittest {}
             }))
    {
        auto tests = unitTests;
        tests[0].run;
        tests[1].run.shouldThrowWithMessage!TestFailure("Failure: `false`");
        tests[2].run;
    }
}


@("assert.literal.int")
@safe unittest {
    with(const TestModule(
             q{
                 unittest { assert(0); }
                 unittest { assert(42); }
             }))
    {
        auto tests = unitTests;
        tests[0].run.shouldThrowWithMessage!TestFailure("Failure: `0`");
        tests[1].run;
    }
}


@("assert.literal.sum")
@safe unittest {
    with(const TestModule(
             q{
                 unittest { assert(1 + 1); }
                 unittest { assert(1 - 1); }
             }))
    {
        auto tests = unitTests;
        tests[0].run;
        tests[1].run.shouldThrowWithMessage!TestFailure("Failure: `0`");
    }
}
