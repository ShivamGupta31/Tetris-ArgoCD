#pipeline v1 script
pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {
        stage('Code Checkout') {
            steps {
                git branch: 'main', credentialsId: 'git-cred', url: 'https://github.com/ShivamGupta31/Tetris-ArgoCD-v1.git'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=Tetris-v1 \
                        -Dsonar.projectKey=Tetris-v1 \
                        -Dsonar.sources=.
                    """
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs . > trivyfs.txt'
            }
        }
        stage('OWASP FS Scan') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh '''
                        docker build -t tetrisv1 .
                        docker tag tetrisv1 shivamgupta31/tetrisv1:latest
                        docker push shivamgupta31/tetrisv1:latest
                        '''
                    }
                }
            }
        }
        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image shivamgupta31/tetrisv1:latest > trivyimage.txt'
            }
        }
        stage('Trigger Image Update') {
            steps {
                build job: 'Manifest-v1', wait: true
            }
        }
    }
    post {
        always {
            emailext (
                attachLog: true,
                subject: "'${currentBuild.result}'",
                body: """
                    Project: ${env.JOB_NAME}<br/>
                    Build Number: ${env.BUILD_NUMBER}<br/>
                    URL: ${env.BUILD_URL}<br/>
                """,
                to: 'shivwsr@gmail.com',
                attachmentsPattern: 'trivyfs.txt, trivyimage.txt'
            )
        }
    }
}
