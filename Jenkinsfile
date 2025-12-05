pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "hamzaab325/student-management:1.0.0"
        SONAR_HOST   = "http://localhost:9000"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/hamzaa331/student-management.git'
            }
        }

        stage('Build & Test with Maven') {
            steps {
                // Build + tests + génération du JAR + rapport Jacoco
                sh 'mvn clean package jacoco:report'
            }
        }

        stage('Analyse SonarQube') {
    steps {
        withSonarQubeEnv('sonarqube-docker') { // <-- le nom EXACT du serveur dans Jenkins
            sh 'mvn sonar:sonar'
        }
    }
}

        stage('MVN SONARQUBE') {
            steps {
                withCredentials([string(
                    credentialsId: 'sonar-token',
                    variable: 'SONAR_TOKEN'
                )]) {
                    sh """
                        mvn sonar:sonar \
                          -Dsonar.host.url=${SONAR_HOST} \
                          -Dsonar.login=\$SONAR_TOKEN
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    echo "=== Workspace content ==="
                    ls -R

                    echo "=== Building Docker image ==="
                    docker build -t ${DOCKER_IMAGE} -f Docker/student-app/Dockerfile .
                """
            }
        }

        stage('Login to Docker Hub & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-cred',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}
                    """
                }
            }
        }
    }
}




