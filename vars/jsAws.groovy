import org.jenkins.pipeline.AwsSupport

private AwsSupport support() {
    new AwsSupport(this)
}

def methodMissing(String name, Object args) {
    support().invokeMethod(name, args)
}
