
pipeline {
    agent any

    tools {
        nodejs 'NodeJS20'
        sonarScanner 'SonarScanner'
    }

    environment {
        IMAGE_NAME = "alimaalej/kaddem-frontend"
        NEXUS_URL = "http://10.0.2.15:8081"
        NEXUS_REPOSITORY = "angular-releases"
        SONAR_PROJECT_KEY = "kaddem-frontend"
    }

    stages {

        stage('Build') {
            steps {
                sh 'npm ci'
                sh 'npm run build:prod'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'npm run test:ci'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'sonarqube-token',
                        variable: 'SONAR_TOKEN'
                    )
                ]) {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                          -Dsonar.host.url=http://10.0.2.15:9000 \
                          -Dsonar.token=$SONAR_TOKEN \
                          -Dsonar.javascript.lcov.reportPaths=coverage/**/lcov.info
                    '''
                }
            }
        }

        stage('Deploy to Nexus') {
            steps {
                sh '''
                    zip -r kaddem-frontend-${BUILD_NUMBER}.zip dist/exam1
                '''

                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USERNAME',
                        passwordVariable: 'NEXUS_PASSWORD'
                    )
                ]) {
                    sh '''
                        curl --fail --show-error \
                          -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                          --upload-file "kaddem-frontend-${BUILD_NUMBER}.zip" \
                          "${NEXUS_URL}/repository/${NEXUS_REPOSITORY}/kaddem-frontend-${BUILD_NUMBER}.zip"
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                      -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                      -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" |
                          docker login -u "$DOCKER_USERNAME" --password-stdin

                        docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                sh '''
                    docker compose pull frontend
                    docker compose up -d --force-recreate frontend
                '''
            }
        }

        /*
        stage('Cleanup') {
            steps {
                sh '''
                    docker image prune -f
                '''
            }
        }
        */
    }

    post {
        always {
            sh 'docker logout || true'
            cleanWs()
        }

        success {
            echo 'Angular pipeline executed successfully!'
        }

        failure {
            echo 'Angular pipeline execution failed!'
        }
    }
}
