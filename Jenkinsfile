pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'hamzaab325'
        IMAGE_NAME = "${DOCKERHUB_USER}/student-management"
        IMAGE_TAG  = "1.0.0"
    }

    stages {

        stage('Checkout') {
            steps {
                // Normalement Jenkins fait déjà checkout, mais on le force pour être clean
                checkout scm
            }
        }

        stage('Show Maven Version') {
            steps {
                sh 'mvn -version'
            }
        }

        stage('Build Jar with Maven') {
            steps {
                // Build du jar Spring Boot
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build de l'image Docker à partir du Dockerfile student-app
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f Docker/student-app/Dockerfile .'
            }
        }

        stage('Login to Docker Hub & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }
    }
}
