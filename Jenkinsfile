pipeline {
  agent any

  environment {
    IMAGE = "test-app:ci"
    SONAR_PROJECT_KEY = "test-app"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Secrets Scan (Gitleaks)') {
      steps {
        sh '''
          docker run --rm \
            -v "$PWD:/repo" \
            zricethezav/gitleaks:latest \
            detect --no-git --source /repo \
            --report-format json --report-path /repo/gitleaks-report.json \
            || true
        '''
      }
      post { always { archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true } }
    }

    stage('Static Analysis (Semgrep)') {
      steps {
        sh '''
          docker run --rm \
            -v "$PWD:/src" -w /src \
            returntocorp/semgrep:latest \
            semgrep scan --config p/javascript --config p/owasp-top-ten --sarif \
            > semgrep-report.sarif \
            || true
        '''
      }
      post { always { archiveArtifacts artifacts: 'semgrep-report.sarif', allowEmptyArchive: true } }
    }

    stage('SonarQube Analysis') {
      steps {
        script {
          def scannerHome = tool 'sonar-scanner'
          withSonarQubeEnv('sonarqube') {
            sh """
              ${scannerHome}/bin/sonar-scanner \
                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                -Dsonar.sources=src
            """
          }
        }
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t ${IMAGE} .'
      }
    }

    stage('Trivy Scan') {
  steps {
    sh '''
      docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$PWD:/work" -w /work \
        aquasec/trivy:latest image \
        --format json --output trivy-report.json \
        --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL \
        --ignore-unfixed \
        ${IMAGE}

      # Optional: print only HIGH/CRITICAL summary to logs (still doesn't fail)
      docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        aquasec/trivy:latest image \
        --severity HIGH,CRITICAL \
        --ignore-unfixed \
        ${IMAGE} || true
    '''
  }
  post {
    always {
      archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: false
    }
  }
}

    stage('Run App (for DAST)') {
      steps {
        sh '''
          docker rm -f test-app-ci >/dev/null 2>&1 || true
          docker run -d --name test-app-ci -p 3000:3000 '"$IMAGE"'
          # quick wait
          for i in $(seq 1 20); do
            curl -fsS http://localhost:3000/health && exit 0
            sleep 1
          done
          echo "App did not become ready" >&2
          exit 1
        '''
      }
    }

    stage('DAST (OWASP ZAP)') {
      steps {
        sh '''
          mkdir -p zap
          docker run --rm -u 0 \
            --network host \
            -v "$PWD/zap:/zap/wrk" \
            zaproxy/zap-stable \
            zap-baseline.py -t http://localhost:3000/health -r zap-report.html \
            || true
        '''
      }
      post { always { archiveArtifacts artifacts: 'zap/*', allowEmptyArchive: true } }
    }

    stage('Deploy to Staging') {
      steps {
        echo 'Deploying minimal test app (dummy deployment step)...'
      }
    }
  }

  post {
    always {
      sh 'docker rm -f test-app-ci >/dev/null 2>&1 || true'
    }
  }
}
