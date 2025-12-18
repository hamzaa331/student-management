pipeline {
  agent any

  options {
    timestamps()
    skipDefaultCheckout(true)
  }

  environment {
    DOCKER_IMAGE = "hamzaab325/student-management:1.0.3"
    NEXUS_REPO   = "http://localhost:8081/repository/maven-public/"
    KUBE_NS     = "devops"
    KCTL        = "./kubectl --insecure-skip-tls-verify=true"
  }

  stages {
    /* =======================
       1. SOURCE CONTROL
    ======================== */
    stage('Checkout Source Code') {
      steps {
        git branch: 'main',
            url: 'https://github.com/hamzaa331/student-management.git'
      }
    }

    stage('Prepare kubectl') {
  steps {
    sh '''
      set -e
      if [ ! -f ./kubectl ]; then
        echo "Downloading kubectl into workspace..."
        curl -LO https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
        chmod +x ./kubectl
      fi
      ./kubectl version --client
    '''
  }
}


    /* =======================
       2. DEPENDENCY REPOSITORY
    ======================== */
    stage('Check Nexus Availability') {
      steps {
        sh '''
          code=$(curl -s -o /dev/null -w "%{http_code}" ${NEXUS_REPO})
          echo "Nexus HTTP code = $code"
          if [ "$code" != "200" ] && [ "$code" != "401" ]; then
            exit 1
          fi
        '''
      }
    }

    /* =======================
       3. COMPILE
    ======================== */
    stage('Maven Compile') {
      steps {
        sh 'mvn -s settings.xml clean compile'
      }
    }

    /* =======================
       4. UNIT TESTS
    ======================== */
    stage('Unit Tests (JUnit)') {
      steps {
        sh 'mvn -s settings.xml test'
      }
    }

    /* =======================
       5. CODE COVERAGE
    ======================== */
    stage('JaCoCo Coverage') {
      steps {
        sh 'mvn -s settings.xml jacoco:report'
      }
    }

    /* =======================
       6. SONARQUBE
    ======================== */
    stage('SonarQube Analysis') {
  steps {
    withSonarQubeEnv('sonarqube-docker') {
  withCredentials([string(credentialsId: 'sonar-token-student', variable: 'SONAR_TOKEN')]) {
  sh '''
    mvn -s settings.xml clean verify sonar:sonar \
      -Dsonar.projectKey=tn.esprit:student-management \
      -Dsonar.projectVersion=${BUILD_NUMBER} \
      -Dsonar.token=$SONAR_TOKEN \
      -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
  '''
}
}
  }
}





    /* =======================
       7. PACKAGE APPLICATION
    ======================== */
    stage('Maven Package') {
      steps {
        sh 'mvn -s settings.xml package -DskipTests'
      }
    }

    /* =======================
       8. DOCKER IMAGE
    ======================== */
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

    /* =======================
       9. KUBERNETES
    ======================== */
    stage('Deploy to Kubernetes') {
  steps {
    sh '''
      set -e
      $KCTL apply -n ${KUBE_NS} -f k8s/mysql-deployment.yaml --validate=false
      $KCTL apply -n ${KUBE_NS} -f k8s/spring-deployment.yaml --validate=false

      $KCTL rollout status -n ${KUBE_NS} deployment/mysql
      $KCTL rollout status -n ${KUBE_NS} deployment/student-app
    '''
  }
}


    stage('Deploy Monitoring (Prometheus & Grafana)') {
  steps {
    sh '''
      set -e
      echo "=== DEPLOY PROMETHEUS + GRAFANA ==="
      $KCTL apply -n ${KUBE_NS} -f k8s/monitoring.yaml --validate=false

      echo "=== WAIT FOR ROLLOUT ==="
      $KCTL rollout status -n ${KUBE_NS} deployment/prometheus
      $KCTL rollout status -n ${KUBE_NS} deployment/grafana

      echo "=== SERVICES ==="
      $KCTL get svc -n ${KUBE_NS} prometheus grafana -o wide
    '''
  }
}





    /* =======================
       10. APPLICATION CHECK
    ======================== */
    stage('Health Check (Spring Actuator)') {
  steps {
    sh '''
      set -e
      NODEPORT=$($KCTL get svc spring-service -n ${KUBE_NS} -o=jsonpath='{.spec.ports[0].nodePort}')
      NODEIP=$($KCTL get node minikube -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

      curl -f http://$NODEIP:$NODEPORT/student/actuator/health
    '''
  }
}

  }
}
