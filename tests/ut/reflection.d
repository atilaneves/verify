module ut.reflection;


import ut;


@("number of unittests")
@safe unittest {
    with(const TestModule(
             q{
                 unittest {}
                 unittest {}
                 unittest {}
             }))
    {
        unitTests.length.should == 3;
    }
}
