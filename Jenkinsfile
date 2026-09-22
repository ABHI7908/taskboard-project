pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '035930871892'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/taskboard"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Run unit tests') {
            steps {
                sh 'npm test -- --ci --coverage'
            }
        }

        stage('Code Quality - SonarQube') {
            steps {
                withSonarQubeEnv('sonarqube-server') {
                    sh '''
                        sonar-scanner \
                        -Dsonar.projectKey=taskboard \
                        -Dsonar.projectName=taskboard \
                        -Dsonar.sources=. \
                        -Dsonar.exclusions=node_modules/**,coverage/**,k8s/**,terraform/**,terraform-jenkins/**
                    '''
                }
            }
        }

        stage('Security Scan - Trivy (filesystem)') {
            steps {
                sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
            }
        }

        stage('Security Scan - Trivy (image)') {
            steps {
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Push to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                    docker push ${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh """
                    aws eks update-kubeconfig --name taskboard-eks --region ${AWS_REGION}

                    sed -i 's|IMAGE_PLACEHOLDER|${ECR_REPO}:${IMAGE_TAG}|g' k8s/deployment.yaml

                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml

                    kubectl rollout status deployment/taskboard --timeout=180s
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded — image ${ECR_REPO}:${IMAGE_TAG} deployed."
        }
        failure {
            echo 'Pipeline failed — check the stage logs above.'
        }
    }
}
