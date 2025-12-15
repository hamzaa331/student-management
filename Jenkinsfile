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
    sh '''
      set -e
      code=$(curl -s -o /dev/null -w "%{http_code}" ${NEXUS_REPO})
      echo "Nexus HTTP code: $code"
      if [ "$code" != "200" ] && [ "$code" != "401" ]; then
        echo "Nexus not reachable (expected 200 or 401)"
        exit 1
      fi
    '''
  }
}


    stage('Build & Test (Maven via Nexus)') {
  steps {
    withCredentials([usernamePassword(
      credentialsId: 'nexus-cred',
      usernameVariable: 'NEXUS_USER',
      passwordVariable: 'NEXUS_PASS'
    )]) {
      sh '''
        mvn -s settings.xml -U clean verify jacoco:report
      '''
    }
  }
}


    stage('SonarQube Analysis') {
  steps {
    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
  sh '''
    mvn -s settings.xml sonar:sonar \
      -Dsonar.host.url=http://localhost:9001 \
      -Dsonar.token=$SONAR_TOKEN
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
