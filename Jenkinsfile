pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "hamzaab325/student-management:1.0.3"

        // SonarQube exposed as NodePort 30090
        SONAR_HOST = "http://host.docker.internal:30090"
    }

    stages {

        // ===============================
        // 1. CHECKOUT
        // ===============================
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/hamzaa331/student-management.git'
            }
        }



        // ===============================
        // 2. CHECK NEXUS
        // ===============================
        stage('Check Nexus') {
            steps {
                sh 'curl -I http://host.docker.internal:8081/repository/maven-public/ | head -n 5'
            }
        }

        stage('Test') {
            steps {
                // clean + compile + tests
                sh 'mvn clean test'
            }
        }
        
        // ===============================
        // 3. BUILD + TEST (MAVEN via NEXUS)
        // ===============================
        stage('Build & Test (Maven + Nexus)') {
            steps {
                sh 'mvn -s settings.xml clean verify jacoco:report'
            }
        }

        // ===============================
        // 4. SONARQUBE ANALYSIS
        // ===============================
        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        mvn sonar:sonar \
                          -Dsonar.host.url=${SONAR_HOST} \
                          -Dsonar.login=\$SONAR_TOKEN
                    """
                }
            }
        }

        // ===============================
        // 5. BUILD DOCKER IMAGE
        // ===============================
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} -f Docker/student-app/Dockerfile .'
            }
        }

        // ===============================
        // 6. PUSH TO DOCKER HUB
        // ===============================
        stage('Push Docker Image') {
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

        // ===============================
        // 7. DEPLOY TO KUBERNETES
        // ===============================
        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    echo "=== KUBECTL VERSION ==="
                    /usr/local/bin/kubectl version --client

                    echo "=== APPLY MANIFESTS ==="
                    /usr/local/bin/kubectl apply -n devops -f k8s/mysql-deployment.yaml
                    /usr/local/bin/kubectl apply -n devops -f k8s/spring-deployment.yaml

                    echo "=== ROLLOUT STATUS ==="
                    /usr/local/bin/kubectl rollout status -n devops deployment/mysql
                    /usr/local/bin/kubectl rollout status -n devops deployment/student-app

                    echo "=== VERIFY IMAGE ==="
                    /usr/local/bin/kubectl get deploy student-app -n devops \
                      -o=jsonpath='{.spec.template.spec.containers[0].image}'; echo

                    echo "=== API TEST ==="
                    NODEPORT=$(/usr/local/bin/kubectl get svc spring-service -n devops \
                      -o=jsonpath='{.spec.ports[0].nodePort}')

                    NODEIP=$(/usr/local/bin/kubectl get node minikube \
                      -o=jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

                    curl -s -i http://$NODEIP:$NODEPORT/student/students/ping | head -n 10
                '''
            }
        }
    }
}
