.PHONY: validate validate-layout validate-canonical-paths validate-v2 validate-trailing-space docs-list

validate: validate-layout validate-canonical-paths validate-v2 validate-trailing-space
	@echo "Repository validation passed."

validate-layout:
	@test -d vars
	@test -d src/org/jenkins
	@test -d resources/org/jenkins
	@test -d pipelines/v2/deployment
	@test -d pipelines/v2/configuration
	@test -d pipelines/legacy/deployment
	@test -d pipelines/legacy/configuration
	@test -d scripts/deployment
	@test -d scripts/ops
	@test -d infrastructure/ansible
	@test -d data/pman
	@test -d config/update-stack
	@test -d legacy/obsolete
	@test -d docs
	@test -f docs/ARCHITECTURE.md
	@test -f docs/REFACTORING.md
	@test -f docs/ALT_NEU_VERGLEICH.md
	@echo "Layout validation passed."

validate-canonical-paths:
	@test -f pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
	@test -f pipelines/v2/deployment/BIBE_TPO_DataDeployment.Jenkinsfile
	@test -f pipelines/v2/deployment/TPO_SWEinsatz.Jenkinsfile
	@test -f pipelines/v2/configuration/modifyConfigurationGroovy.Jenkinsfile
	@test -f pipelines/legacy/deployment/BIBE_SWEinsatz.Jenkinsfile
	@test -f pipelines/legacy/deployment/BIBE_TPO_DataDeployment.Jenkinsfile
	@test -f pipelines/legacy/deployment/TPO_SWEinsatz.Jenkinsfile
	@test -f scripts/deployment/BIBE_createSnapshot.sh
	@test -f pipelines/legacy/configuration/modifyConfigurationGroovy.Jenkinsfile
	@test -f infrastructure/ansible/local.yml
	@test -f data/pman/pman.py
	@test -f config/update-stack/update-stack.py
	@test -f scripts/ops/create-snapshot.py
	@test -z "$$(find . -type l -print -quit)"
	@echo "Canonical path validation passed."

validate-v2:
	@test "$$(find pipelines/legacy -type f | wc -l)" = "$$(find pipelines/v2 -type f | wc -l)"
	@cd pipelines/legacy && find . -type f | sort > /tmp/jenkins-legacy-files.$$$$; \
	cd ../../pipelines/v2 && find . -type f | sort > /tmp/jenkins-v2-files.$$$$; \
	diff /tmp/jenkins-legacy-files.$$$$ /tmp/jenkins-v2-files.$$$$; \
	rm -f /tmp/jenkins-legacy-files.$$$$ /tmp/jenkins-v2-files.$$$$
	@grep -R "@Library('jenkins') _" pipelines/v2 >/dev/null
	@! grep -R "Delegate to legacy\|triggerJob('BIBE_SWDeployment\|triggerJob('DataDeployment\|triggerJob('TPO_SWDeployment\|triggerJob('onOffEnvinroment" pipelines/v2
	@! grep -R "sshagent(\|7f075ad2\|dir(\"scripts/deployment\")\|dir(\"data/pman\")\|dir(\"config/update-stack\")" pipelines/v2
	@echo "V2 pipeline validation passed."

validate-trailing-space:
	@git diff --check
	@echo "Whitespace validation passed."

docs-list:
	@find docs -maxdepth 1 -type f | sort
