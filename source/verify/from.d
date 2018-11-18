module verify.from;


template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}
