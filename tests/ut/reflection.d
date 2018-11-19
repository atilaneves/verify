module ut.reflection;


import ut;


@("number of unittests")
@safe unittest {
    auto tests = unitTests(
        Code(
             q{
                 unittest {}
                 unittest {}
                 unittest {}
             }
        )
    );

    tests.length.should == 3;
}
