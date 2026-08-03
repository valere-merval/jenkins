import org.jenkins.pipeline.QualitySupport

private QualitySupport support() {
    new QualitySupport(this)
}

def methodMissing(String name, Object args) {
    support().invokeMethod(name, args)
}
