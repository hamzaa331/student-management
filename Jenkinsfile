pipeline {
    agent any

    stages {
        stage('Checkout from Git') {
            steps {
                echo 'Code already checked out by Jenkins from SCM'
            }
        }

        stage('Show Maven Version') {
            steps {
                sh 'mvn -version'
            }
        }
    }
}
