#!groovy

// http://stackoverflow.com/questions/37425064/how-to-use-environment-variables-in-a-groovy-function-using-a-jenkinsfile
import groovy.transform.Field
@Field final BUILD_OS_TARGETS=['el7', 'el6']

properties ([[$class: 'ParametersDefinitionProperty',
  parameterDefinitions: [
    [$class: 'ChoiceParameterDefinition',
      choices: "all\n" + BUILD_OS_TARGETS.join("\n"), description: 'Target OS name', name: 'BUILD_OS'],
    [$class: 'StringParameterDefinition',
      defaultValue: '0', description: 'Leave container after build for debugging.', name: 'LEAVE_CONTAINER'],
    [$class: 'StringParameterDefinition',
      defaultValue: env.REPO_BASE_DIR, description: 'Path to create yum repository', name: 'REPO_BASE_DIR'],
    [$class: 'StringParameterDefinition',
      defaultValue: env.BUILD_CACHE_DIR, description: 'Directory for storing build cache archive', name: 'BUILD_CACHE_DIR']
  ]
]])

def write_build_env(label) {
  def build_env="""# These parameters are read from bash and docker --env-file.
# So do not use single or double quote for the value part.
LEAVE_CONTAINER=$LEAVE_CONTAINER
REPO_BASE_DIR=$REPO_BASE_DIR
BUILD_CACHE_DIR=$BUILD_CACHE_DIR
BUILD_OS=$label
RELEASE_SUFFIX=$RELEASE_SUFFIX
"""
  writeFile(file: "build.env", text: build_env)
}

@Field RELEASE_SUFFIX=null

def stage_rpmbuild(label) {
  node("el7") {
    stage("Build ${label}") {
      checkout scm
      write_build_env(label)
      sh "./deployment/docker/build.sh ./build.env"
    }
  }
}

def stage_test_rpm(label) {
  node(label) {
    stage("RPM Install Test ${label}") {
      checkout scm
      write_build_env(label)
      sh "./deployment/docker/test-rpm-install.sh ./build.env"
    }
  }
}

node() {
  stage("Checkout") {
    checkout scm
    // http://stackoverflow.com/questions/36507410/is-it-possible-to-capture-the-stdout-from-the-sh-dsl-command-in-the-pipeline
    // https://issues.jenkins-ci.org/browse/JENKINS-26133
    RELEASE_SUFFIX=sh(returnStdout: true, script: "./deployment/packagebuild/gen-dev-build-tag.sh").trim()
  }
}

build_nodes=BUILD_OS_TARGETS.clone()
if( BUILD_OS != "all" ){
  build_nodes=[BUILD_OS]
}
// Using .each{} hits "a CPS-transformed closure is not yet supported (JENKINS-26481)"
for( label in build_nodes) {
  stage_rpmbuild(label)
  stage_test_rpm(label)
}
