#!groovy
properties ([[$class: 'ParametersDefinitionProperty',
   parameterDefinitions: [[$class: 'StringParameterDefinition',
       defaultValue: '0', description: 'Leave container after build for debugging.', name: 'LEAVE_CONTAINER']]
]])

def build_env = """
LEAVE_CONTAINER="$LEAVE_CONTAINER"
"""

node {
    stage "Checkout"
    checkout scm
    writeFile(file: "build.env", text: build_env)
    stage "Build"
    sh "./deployment/docker/build.sh ./build.env"
}