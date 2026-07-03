/**
 * Domain-specific helpers for deployment pipelines.
 * This file keeps naming/business conventions out of Jenkinsfiles.
 */

def bibeImageMaster(String release) {
    String releaseSuffix = release.drop(2).take(4)
    return "nvs-psx-bibe-imageMasterAl23-${releaseSuffix}"
}

def releaseShortVersion(String release) {
    return release.drop(2).take(2) + "." + release.drop(4).take(2)
}

def deploymentComment(Map values) {
    List<String> parts = []
    if (values.PE) {
        parts << "PE AL23 ${releaseShortVersion(values.RELEASE)}.${values.PE_Subversion}"
    }
    if (values.SERVER) {
        parts << "SERVER ${values.SERVER_VERSION}"
    }
    if (values.COMMENT) {
        parts << "- ${values.COMMENT}"
    }
    return parts.join(" ").trim()
}

def compareDescription(String category, Map values) {
    List selected = values.findAll { key, value -> key.startsWith("env_") && (value == true || value == "enable") }
        .collect { key, value -> key - "env_" }
        .sort()
    String envs = selected ? selected.join("") : "none"
    return "${category}: environments=${envs}"
}
