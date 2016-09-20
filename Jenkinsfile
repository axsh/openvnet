#!groovy
properties ([[$class: 'ParametersDefinitionProperty',
  parameterDefinitions: [
    [$class: 'StringParameterDefinition',
      defaultValue: '0', description: 'Leave container after build for debugging.', name: 'LEAVE_CONTAINER'],
    [$class: 'StringParameterDefinition',
      defaultValue: '/var/www/html/repos', description: 'Path to create yum repository', name: 'REPO_BASE_DIR'],
    [$class: 'StringParameterDefinition',
      defaultValue: '/var/lib/jenkins/build-cache', description: 'Directory for storing build cache archive', name: 'BUILD_CACHE_DIR'],
    [$class: 'ChoiceParameterDefinition',
      choices: "el7\nel6", description: 'Target OS name', name: 'BUILD_OS']
  ]
]])

def build_env = """# These parameters are read from bash and docker --env-file.
# So do not use single or double quote for the value part.
LEAVE_CONTAINER=$LEAVE_CONTAINER
REPO_BASE_DIR=$REPO_BASE_DIR
BUILD_CACHE_DIR=$BUILD_CACHE_DIR
BUILD_OS=$BUILD_OS
"""

node {
    stage "Checkout"
    checkout scm
    // http://stackoverflow.com/questions/36507410/is-it-possible-to-capture-the-stdout-from-the-sh-dsl-command-in-the-pipeline
    // https://issues.jenkins-ci.org/browse/JENKINS-26133
    def RELEASE_SUFFIX=sh(returnStdout: true, script: "./deployment/packagebuild/gen-dev-build-tag.sh").trim()
    writeFile(file: "build.env", text: build_env + "\nRELEASE_SUFFIX=${RELEASE_SUFFIX}\n")
    stage "Build"
    sh "./deployment/docker/build.sh ./build.env"
    sh "./deployment/docker/test-rpm-install.sh ./build.env"
}