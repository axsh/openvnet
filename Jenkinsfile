#!groovy

// http://stackoverflow.com/questions/37425064/how-to-use-environment-variables-in-a-groovy-function-using-a-jenkinsfile
import groovy.transform.Field

@Field buildParams = [
  "REBUILD": "false",
  "LEAVE_CONTAINER": "0",
  "STRIP_VENDOR": "1",
]
def ask_build_parameter = { ->
  return input(message: "Build Parameters", id: "build_params",
    parameters:[
      [$class: 'ChoiceParameterDefinition',
        choices: "0\n1", description: 'Leave container after build for debugging.', name: 'LEAVE_CONTAINER'],
      [$class: 'ChoiceParameterDefinition',
        choices: "1\n0", description: 'Switch to make vendor/bundle/* compact', name: 'STRIP_VENDOR'],
      [$class: 'ChoiceParameterDefinition',
        choices: "false\ntrue", description: 'Rebuild cache image', name: 'REBUILD'],
    ])
}

def write_build_env(label) {
  def build_env="""# These parameters are read from bash and docker --env-file.
# So do not use single or double quote for the value part.
LEAVE_CONTAINER=${buildParams.LEAVE_CONTAINER}
STRIP_VENDOR=${buildParams.STRIP_VENDOR}
REBUILD=${buildParams.REBUILD}
REPO_BASE_DIR=${env.REPO_BASE_DIR ?: ''}
BUILD_CACHE_DIR=${env.BUILD_CACHE_DIR ?: ''}
BUILD_OS=$label
RELEASE_SUFFIX=$RELEASE_SUFFIX
BRANCH=${env.BRANCH_NAME}
"""
  writeFile(file: "build.env", text: build_env)
}

def checkout_and_merge() {
    checkout scm
    sh "git -c \"user.name=Axsh Bot\" -c \"user.email=dev@axsh.net\" merge origin/develop"
}

@Field RELEASE_SUFFIX=null

def stage_rpmbuild(label) {
  node("ci-build") {
    stage("Build ${label}") {
      checkout_and_merge()
      write_build_env(label)
      sh "./deployment/docker/build.sh ./build.env"
    }
  }
}

def stage_test_rpm(label) {
  node(label) {
    stage("RPM Install Test ${label}") {
      checkout_and_merge()
      write_build_env(label)
      sh "./deployment/docker/test-rpm-install.sh ./build.env"
    }
  }
}

def stage_integration_test(label) {
  node("multibox") {
    stage("Integration test ${label}") {
      checkout_and_merge()
      write_build_env(label)
      sh "./ci/ci.${label}/integration_test/build_and_run_in_docker.sh ./build.env"
    }
  }
}

node() {
  stage("Checkout") {
    try {
      timeout(time: 10, unit :"SECONDS") {
        buildParams = ask_build_parameter()
      }
    }catch(org.jenkinsci.plugins.workflow.steps.FlowInterruptedException err) {
      // Only ignore errors for timeout.
    }
    checkout scm
    // http://stackoverflow.com/questions/36507410/is-it-possible-to-capture-the-stdout-from-the-sh-dsl-command-in-the-pipeline
    // https://issues.jenkins-ci.org/browse/JENKINS-26133
    RELEASE_SUFFIX=sh(returnStdout: true, script: "./deployment/packagebuild/gen-dev-build-tag.sh").trim()
  }
}

def jobName = "${env.JOB_NAME}".tokenize("/")[0]

stage_rpmbuild("${jobName}")
stage_test_rpm("${jobName}")
stage_integration_test("${jobName}")
