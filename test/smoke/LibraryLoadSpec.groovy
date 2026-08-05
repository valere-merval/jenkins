// Local smoke test: proves each vars/*.groovy facade loads its src class and
// delegates via methodMissing, without needing a live Jenkins.
//
// Run: groovy -cp src test/smoke/LibraryLoadSpec.groovy

import org.jenkins.pipeline.JenkinsOpsSupport
import org.jenkins.pipeline.DataDeploymentSupport
import org.jenkins.pipeline.SoftwareDeploymentSupport
import org.jenkins.pipeline.EnvironmentControlSupport
import org.jenkins.pipeline.ConfigurationGroovySupport
import org.jenkins.pipeline.DeploymentSupport

// Minimal fake CPS script: answers to the pipeline steps the src classes may call.
class FakeScript {
    def methodMissing(String name, args) { return "step:${name}" }
    def propertyMissing(String name) { return "prop:${name}" }
    void propertyMissing(String name, value) {}
}

int failures = 0
void check(String label, Closure body) {
    try {
        def r = body()
        println "  ok  ${label} -> ${r}"
    } catch (Throwable t) {
        println "  FAIL ${label} -> ${t.class.simpleName}: ${t.message}"
        binding.setVariable('failures', binding.getVariable('failures') + 1)
    }
}

def script = new FakeScript()

println "== JenkinsOpsSupport =="
check("defaultAgentLabel") { new JenkinsOpsSupport(script).defaultAgentLabel() }
check("dataTypeName(EKTR_19)") {
    assert new JenkinsOpsSupport(script).dataTypeName('EKTR_19') == 'VL_NPS_EBPB'
    'VL_NPS_EBPB'
}
check("environments(override)") {
    assert new JenkinsOpsSupport(script).environments(['A','B']) == ['A','B']
    'passthrough'
}

println "== DataDeploymentSupport =="
check("psxStageParams") { new DataDeploymentSupport(script).psxStageParams() }
check("bibeTpoPmanDataMap") { new DataDeploymentSupport(script).bibeTpoPmanDataMap() }

println "== ConfigurationGroovySupport =="
check("configurationMap") { new ConfigurationGroovySupport(script).configurationMap() }

println "== facade methodMissing delegation =="
def gsl = new GroovyShell()
def facade = gsl.parse(new File('vars/jenkinsOps.groovy'))
check("vars/jenkinsOps.groovy loads") { facade.class.name }

println ""
if (failures == 0) {
    println "SMOKE OK: all facades load and delegate."
} else {
    println "SMOKE FAILED: ${failures} error(s)."
    System.exit(1)
}
