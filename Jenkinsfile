pipeline {
    agent any

    environment {
        // Mets bien la même version que dans ton Docker Hub ET dans ton YAML Kubernetes
        DOCKER_IMAGE = "hamzaab325/student-management:1.0.2"
        SONAR_HOST   = "http://localhost:9000"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/hamzaa331/student-management.git'
            }
        }

        stage('Test') {
            steps {
                // clean + compile + tests
                sh 'mvn clean test'
            }
        }

        stage('Build & Test with Maven') {
            steps {
                // Build complet + génération du JAR + rapport Jacoco
                sh 'mvn clean package jacoco:report'
            }
        }

        stage('Analyse SonarQube (server config)') {
            steps {
                withSonarQubeEnv('sonarqube-docker') { // nom du serveur Sonar dans Jenkins
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('MVN SONARQUBE (avec token)') {
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
                    credentialsId: 'dockerhub-cred',   // ID des credentials Docker dans Jenkins
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

        stage('Deploy to Kubernetes') {
            steps {
                 sh '''
                    echo "=== Déploiement sur Kubernetes (namespace devops) ==="

                    # Dire à kubectl d'utiliser le kubeconfig du user jenkins
                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    # ⚠ kubectl avec son chemin COMPLET
                   /usr/local/bin/kubectl apply -f k8s/mysql-deployment.yaml -n devops
                   /usr/local/bin/kubectl apply -f k8s/spring-deployment.yaml -n devops

                   echo "=== Rollout status ==="
                   /usr/local/bin/kubectl rollout status deployment/mysql-deployment -n devops
                   /usr/local/bin/kubectl rollout status deployment/student-management-deployment -n devops

                   echo "=== Pods dans le namespace devops ==="
                   /usr/local/bin/kubectl get pods -n devops

                   echo "=== Services dans le namespace devops ==="
                   /usr/local/bin/kubectl get svc -n devops
                   '''
                   }
        }

    }
}
