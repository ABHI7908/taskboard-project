pipeline {
  agent any

  environment {
    AWS_ACCOUNT_ID = '035930871892'
    AWS_REGION     = 'ap-south-1'
    ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    ECR_REPO       = "${ECR_REGISTRY}/taskboard-project"
    IMAGE_TAG      = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main',
            url: 'https://github.com/ABHI7908/taskboard-project.git'
      }
    }

    stage('Build & Unit Test') {
      steps {
        sh 'npm ci'
        sh 'npm test'
      }
    }

    stage('Docker Build') {
      steps {
        sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
      }
    }

    stage('Push to ECR') {
      steps {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} |
          docker login --username AWS --password-stdin ${ECR_REGISTRY}
          docker push ${ECR_REPO}:${IMAGE_TAG}
        """
      }
    }

    stage('Deploy to EKS') {
      steps {
        sh """
          sed -i 's|IMAGE_PLACEHOLDER|${ECR_REPO}:${IMAGE_TAG}|' k8s/deployment.yaml
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml
          kubectl rollout status deployment/taskboard
        """
      }
    }
  }
}