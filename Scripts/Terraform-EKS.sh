#Eks cluster creation using jenkins
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'git-cred', url: 'https://github.com/ShivamGupta31/Tetris-ArgoCD.git'
            }
        }
        stage('Initialize terraform') {
            steps {
                dir('Eks-terraform') {
                    sh 'terraform init'
                }
            }
        }
        stage('Validate Terraform') {
            steps {
                dir('Eks-terraform') {
                    sh 'terraform validate'
                }
            }
        }
        stage('Plan') {
            steps {
                dir('Eks-terraform') {
                    sh 'terraform plan'
                }
            }
        }
        stage('Apply/Destroy Terraform') {
            steps {
                dir('Eks-terraform') {
                    sh 'terraform ${action} --auto-approve'
                }
            }
        }
    }
}
