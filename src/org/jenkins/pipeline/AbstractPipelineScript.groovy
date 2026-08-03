package org.jenkins.pipeline

/**
 * Base class for shared-library logic that still needs Jenkins Pipeline steps.
 *
 * Classes under src/ are easier to test and reuse than vars scripts, but Jenkins
 * steps live on the CPS script object. This bridge keeps the src classes small
 * while preserving the existing Jenkinsfile-facing API.
 */
abstract class AbstractPipelineScript implements Serializable {
    protected final def script

    AbstractPipelineScript(def script) {
        this.script = script
    }

    protected def step(String name, Object args) {
        script.invokeMethod(name, args)
    }

    def methodMissing(String name, Object args) {
        script.invokeMethod(name, args)
    }

    def propertyMissing(String name) {
        script.getProperty(name)
    }

    void propertyMissing(String name, Object value) {
        script.setProperty(name, value)
    }
}
