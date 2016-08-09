node {
    stage "Checkout"
    checkout scm
    stage "Build"
    sh "./deployment/docker/build.sh"
}