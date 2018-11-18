module verify.exception;


class TestFailure: Exception {
    import std.exception: basicExceptionCtors;
    mixin basicExceptionCtors;
}
