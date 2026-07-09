package org.jenkins

/**
 * Central constants for Jenkins pipelines.
 *
 * Keep environment names, credential ids and generated configuration locations here
 * instead of scattering hard-coded values across every Jenkinsfile.
 */
class Defaults implements Serializable {
    static final List<String> PSX_ENVIRONMENTS = ["h", "i", "j", "k", "l", "m", "q"]
    static final String DEFAULT_AGENT_LABEL = "master"
    static final String DEFAULT_SSH_CREDENTIAL_ID = "7f075ad2-e78f-429d-8713-4a6acd5f7dc2"
    static final String CONFIG_FILE = "/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy"
    static final String GENERATED_CONFIG_DIR = "/var/jenkins_home/jenkinsDateneinsatzConfig/generated"
    static final String DEPLOYMENT_SCRIPTS_DIR = "scripts/deployment"
    static final String PMAN_DIR = "data/pman"
    static final String UPDATE_STACK_DIR = "config/update-stack"
    static final String ANSIBLE_DIR = "infrastructure/ansible"
    static final String SOFTWARE_SHARE = "/share/SOFTWARE"

    private Defaults() {}
}
