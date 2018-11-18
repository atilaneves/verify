module ut.reflection;


import ut;


@("mod0.number of unittests")
@safe unittest {
    testModulePath("mod0.d").unitTests.length.should == 3;
}
