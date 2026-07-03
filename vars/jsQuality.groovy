/** Quality gates shared by repository and Jenkins validation jobs. */

def validateRepository() {
    sh "test -d vars && test -d src/org/jenkins && test -d resources/org/jenkins && test -d docs"
    sh "git diff --check"
}

def requireFiles(List<String> files) {
    files.each { file ->
        if (!fileExists(file)) {
            error("Required file not found: ${file}")
        }
    }
}
