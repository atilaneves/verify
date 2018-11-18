module ut.reflection;


import ut;
import std.file: chdir;


@Serial
@("mod0.number of unittests")
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


@Serial
@("mod0.results")
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
