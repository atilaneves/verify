module ut.reflection;


import ut;
import std.file: chdir;


@("number of unittests")
@safe unittest {
    with(immutable Sandbox()) {
        writeFile("mod0.d",
                  q{
                      module mod0;
                      unittest {}
                      unittest {}
                      unittest {}
                  });
        chdir(testPath);
        "mod0.d".unitTests.length.should == 3;
    }
}


@("assert.literal.bool")
@safe unittest {
    with(immutable Sandbox()) {
        writeFile("mod1.d",
                  q{
                      module mod1;
                      unittest {}
                      unittest {
                          assert(false);
                      }
                      unittest {}
                  });
        chdir(testPath);

        auto tests = "mod1.d".unitTests;
        tests[0].run;
        tests[1].run.shouldThrowWithMessage!TestFailure("Failure: `false`");
        tests[2].run;
    }
}


@("assert.literal.bool")
@safe unittest {
    with(immutable Sandbox()) {
        writeFile("mod2.d",
                  q{
                      module mod2;
                      unittest {
                          assert(42);
                      }
                      unittest {
                          assert(0);
                      }
                  });
        chdir(testPath);

        auto tests = "mod2.d".unitTests;
        tests[0].run;
        tests[1].run.shouldThrowWithMessage!TestFailure("Failure: `0`");
    }
}
