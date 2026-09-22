pipeline {
  agent any

  environment {
    AWS_REGION   = 'ap-south-1'
    ECR_REPO     = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/taskboard"
    IMAGE_TAG    = "${env.BUILD_NUMBER}"
  }

  stage('Checkout') {
    steps {
        git branch: 'main',
            credentialsId: 'github-cred',
            url: 'https://github.com/ABHI7908/taskboard-project.git'
    }
}

    stage('Build & Unit Test') {
      steps {
        sh 'npm ci'
        sh 'npm test'
      }
    }

    stage('Code Quality - SonarQube') {
      steps {
        withSonarQubeEnv('sonarqube-server') {
          sh 'sonar-scanner'
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
        sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
      }
    }

    stage('Security Scan - Trivy (image)') {
      steps {
        sh "trivy image --exit-code 1 --severity CRITICAL ${ECR_REPO}:${IMAGE_TAG}"
      }
    }

    stage('Push to ECR') {
      steps {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} | \
          docker login --username AWS --password-stdin ${ECR_REPO}
          docker push ${ECR_REPO}:${IMAGE_TAG}
        """
      }
    }

    stage('Deploy to EKS') {
      steps {
        sh """
          aws eks update-kubeconfig --name taskboard-eks --region ${AWS_REGION}
          sed -i 's|IMAGE_PLACEHOLDER|${ECR_REPO}:${IMAGE_TAG}|' k8s/deployment.yaml
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml
          kubectl rollout status deployment/taskboard
        """
      }
    }
  }

  post {
    success {
      echo "Pipeline succeeded — image ${ECR_REPO}:${IMAGE_TAG} deployed."
    }
    failure {
      echo 'Pipeline failed — wire this to Slack/SNS via the Jenkins Slack plugin.'
    }
  }
}
