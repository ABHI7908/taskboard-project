pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '035930871892'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REPO = "${ECR_REGISTRY}/taskboard"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Set image tag') {
            steps {
                script {
                    def shortSha = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${shortSha}"
                    echo "Using image tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Install dependencies') {
            steps {
                sh '''
                    set -eu
                    export PATH=/usr/bin:/usr/local/bin:$PATH
                    node --version
                    npm --version
                    npm ci
                '''
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
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            set -eu
                            SONAR_HOST_URL="${SONAR_HOST_URL:-http://127.0.0.1:9000}"
                            curl --fail --silent --show-error --max-time 10 "$SONAR_HOST_URL/api/system/status" >/dev/null
                            sonar-scanner \\
                                -Dsonar.projectKey=taskboard \\
                                -Dsonar.projectName=taskboard \\
                                -Dsonar.host.url="$SONAR_HOST_URL" \\
                                -Dsonar.sources=src \\
                                -Dsonar.tests=test \\
                                -Dsonar.test.inclusions=test/**/*.js \\
                                -Dsonar.exclusions=node_modules/**,coverage/**,k8s/**,terraform/**,terraform-jenkins/** \\
                                -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \\
                                -Dsonar.token="$SONAR_TOKEN"
                        '''
                    }
                }
            }
        }

        stage('Security Scan - Trivy (filesystem)') {
            steps {
                sh 'trivy fs --exit-code 0 --severity HIGH,CRITICAL .'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build --tag "${ECR_REPO}:${IMAGE_TAG}" .'
            }
        }

        stage('Security Scan - Trivy (image)') {
            steps {
                sh 'trivy image --exit-code 0 --severity HIGH,CRITICAL "${ECR_REPO}:${IMAGE_TAG}"'
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    set -eu
                    aws ecr get-login-password --region "$AWS_REGION" | \\
                        docker login --username AWS --password-stdin "$ECR_REGISTRY"
                    docker push "$ECR_REPO:$IMAGE_TAG"
                '''
            }
        }

        stage('Approve deployment') {
            options {
                timeout(time: 30, unit: 'MINUTES')
            }
            steps {
                input message: "Deploy ${ECR_REPO}:${IMAGE_TAG} to EKS?", ok: 'Approve deployment', submitter: 'admin', submitterParameter: 'DEPLOY_APPROVER'
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    set -eu
                    aws eks update-kubeconfig --name taskboard-eks --region "$AWS_REGION"

                    sed -i "s|IMAGE_PLACEHOLDER|$ECR_REPO:$IMAGE_TAG|g" k8s/deployment.yaml

                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl rollout status deployment/taskboard --timeout=180s
                '''
            }
        }
    }

    post {
        always {
            script {
                def result = currentBuild.currentResult ?: 'UNKNOWN'

                emailext(
                    to: 'abhinaylone3@gmail.com',
                    subject: "${result}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """Pipeline completed.

Status: ${result}
Job: ${env.JOB_NAME}
Build: #${env.BUILD_NUMBER}
Image: ${env.ECR_REPO}:${env.IMAGE_TAG}
Build URL: ${env.BUILD_URL}
"""
                )
            }
        }
    }
}
