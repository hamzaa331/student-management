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
      echo "=== K8s Deploy (minikube / namespace devops) ==="

      # Debug: prove kubectl exists in this Jenkins shell
      echo "PATH=$PATH"
      which kubectl || true
      /usr/local/bin/kubectl version --client

      # Apply manifests
      /usr/local/bin/kubectl apply -n devops -f k8s/mysql-deployment.yaml
      /usr/local/bin/kubectl apply -n devops -f k8s/spring-deployment.yaml

      echo "=== Rollout status ==="
      /usr/local/bin/kubectl rollout status -n devops deployment/mysql
      /usr/local/bin/kubectl rollout status -n devops deployment/student-app

      echo "=== Verify image ==="
      /usr/local/bin/kubectl get deploy student-app -n devops -o=jsonpath='{.spec.template.spec.containers[0].image}'; echo

      echo "=== Pods ==="
      /usr/local/bin/kubectl get pods -n devops -o wide

      echo "=== Services ==="
      /usr/local/bin/kubectl get svc -n devops -o wide

     echo "=== API Ping ==="
NODEPORT=$(/usr/local/bin/kubectl get svc spring-service -n devops -o=jsonpath='{.spec.ports[0].nodePort}')

# Get the minikube node IP from Kubernetes (works in Jenkins)
NODEIP=$(/usr/local/bin/kubectl get node minikube -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

echo "NODEIP=$NODEIP  NODEPORT=$NODEPORT"

curl -s -i http://$NODEIP:$NODEPORT/student/students/ping | head -n 20

    '''
  }
}





    }
}
