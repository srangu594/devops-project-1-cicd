pipeline {
    agent any

    environment {
        DOCKER_IMAGE     = "srangu594/devops-project1"
        IMAGE_TAG        = "${BUILD_NUMBER}"
        DEPLOY_SERVER_IP = credentials('deploy-server-ip')
        DEPLOY_SSH_KEY   = credentials('deploy-ssh-key')
        CONTAINER_NAME   = "project1-app"
        APP_PORT         = "5000"
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Branch: ${GIT_BRANCH} | Commit: ${GIT_COMMIT.take(7)}"
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                // Tests run inside Docker build Stage 1 — fail here = no push
                sh """
                    docker build \
                        -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
                        -t ${DOCKER_IMAGE}:latest \
                        .
                """
            }
        }

        stage('Security Scan') {
            steps {
                // Trivy scans for CVEs — won't block but shows what's vulnerable
                sh """
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy:latest image \
                        --exit-code 0 \
                        --severity HIGH,CRITICAL \
                        --no-progress \
                        ${DOCKER_IMAGE}:${IMAGE_TAG} || true
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy') {
            when { branch 'main' }
            steps {
                sh """
                    ssh -o StrictHostKeyChecking=no \
                        -i ${DEPLOY_SSH_KEY} \
                        ec2-user@${DEPLOY_SERVER_IP} \
                        'bash -s' < scripts/deploy.sh \
                        ${DOCKER_IMAGE} ${IMAGE_TAG} ${CONTAINER_NAME} ${APP_PORT}
                """
            }
        }

        stage('Health Check') {
            when { branch 'main' }
            steps {
                sh """
                    sleep 10
                    ssh -o StrictHostKeyChecking=no \
                        -i ${DEPLOY_SSH_KEY} \
                        ec2-user@${DEPLOY_SERVER_IP} \
                        'bash -s' < scripts/health_check.sh ${APP_PORT}
                """
            }
        }
    }

    post {
        success {
            echo "Build #${BUILD_NUMBER} deployed successfully"
        }
        failure {
            echo "Build #${BUILD_NUMBER} FAILED - rolling back to previous build"
            sh """
                PREV=\$((${BUILD_NUMBER} - 1))
                ssh -o StrictHostKeyChecking=no -i ${DEPLOY_SSH_KEY} \
                    ec2-user@${DEPLOY_SERVER_IP} \
                    'bash -s' < scripts/deploy.sh \
                    ${DOCKER_IMAGE} \${PREV} ${CONTAINER_NAME} ${APP_PORT} || true
            """
        }
        always {
            sh 'docker image prune -f || true'
            cleanWs()
        }
    }
}
