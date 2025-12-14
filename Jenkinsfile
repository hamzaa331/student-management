pipeline {
  agent any

  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  environment {
    DOCKER_IMAGE = "hamzaab325/student-management:1.0.3"
    NEXUS_REPO   = "http://localhost:8081/repository/maven-public/"
    NS           = "devops"
  }

  stages {

    stage('Checkout') {
      steps {
        git branch: 'main',
            url: 'https://github.com/hamzaa331/student-management.git'
      }
    }

    stage('Check Nexus') {
      steps {
        sh 'curl -I ${NEXUS_REPO} | head -n 5'
      }
    }

    stage('Build & Test (Maven via Nexus)') {
      steps {
        sh 'mvn -s settings.xml -U clean verify jacoco:report'
      }
    }

    stage('SonarQube Analysis') {
  steps {
    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
      sh '''
        SONAR_URL="http://sonarqube.devops.svc.cluster.local:9000"
        echo "Using SONAR_URL=$SONAR_URL"
        curl -s "$SONAR_URL/api/system/status" || true

        mvn -s settings.xml sonar:sonar \
          -Dsonar.host.url="$SONAR_URL" \
          -Dsonar.login="$SONAR_TOKEN"
      '''
    }
  }
}



    stage('Build Docker Image') {
      steps {
        sh 'docker build -t ${DOCKER_IMAGE} -f Docker/student-app/Dockerfile .'
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-cred',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${DOCKER_IMAGE}
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh '''
          echo "=== APPLY MANIFESTS ==="
          /usr/local/bin/kubectl apply -n ${NS} -f k8s/mysql-deployment.yaml
          /usr/local/bin/kubectl apply -n ${NS} -f k8s/spring-deployment.yaml

          echo "=== ROLLOUT STATUS ==="
          /usr/local/bin/kubectl rollout status -n ${NS} deployment/mysql
          /usr/local/bin/kubectl rollout status -n ${NS} deployment/student-app

          echo "=== PODS ==="
          /usr/local/bin/kubectl get pods -n ${NS} -o wide

          echo "=== SERVICES ==="
          /usr/local/bin/kubectl get svc -n ${NS} -o wide

          echo "=== API TEST ==="
          NODEPORT=$(/usr/local/bin/kubectl get svc spring-service -n ${NS} -o=jsonpath='{.spec.ports[0].nodePort}')
          NODEIP=$(/usr/local/bin/kubectl get node minikube -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

          echo "NODEIP=$NODEIP NODEPORT=$NODEPORT"
          curl -s -i http://$NODEIP:$NODEPORT/student/students/ping | head -n 20
        '''
      }
    }
  }
}
