pipeline{
    agent any
    tools{
        jdk 'jdk-17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/johntoby/netflix-clone-application.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Netflix \
                    -Dsonar.projectKey=Netflix '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install && npm audit fix"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh "docker build --build-arg TMDB_V3_API_KEY=db9ee4907cb9f2eb985252f811b81d05 -t johntoby/netflix:${BUILD_NUMBER} ."
                       sh "docker push johntoby/netflix:${BUILD_NUMBER} "
                    }
                }
            }
        }
        stage('Deploy to container'){
            steps{
                sh 'docker rm -f netflix || true' // Ensures the old container is removed if exists
                sh 'docker run -d --name netflix -p 8081:80 johntoby/netflix:${BUILD_NUMBER}'
            }
        } 
        stage('Deploy to Kubernetes') {
            environment {
               AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
               AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }
           steps {
                script {
                   sh 'aws eks get-token --cluster-name EKS_CLOUD | kubectl apply -f -'
                   sh 'aws eks update-kubeconfig --name EKS_CLOUD --region us-east-2'
                   sh 'kubectl apply -f Kubernetes/deployment.yml'
        }
    }
}
}  
        stage("TRIVY"){
            steps{
                sh "trivy image johntoby/netflix:${BUILD_NUMBER} > trivyimage.txt"
            }
        }
    }

    post {
     always {
        emailext attachLog: true,
            subject: "'${currentBuild.result}'",
            body: "Project: ${env.JOB_NAME}<br/>" +
                "Build Number: ${env.BUILD_NUMBER}<br/>" +
                "URL: ${env.BUILD_URL}<br/>",
            to: 'borderlesspharma@gmail.com',
            attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}


