pipeline { 
  agent any 
  stages { 
    stage('Checkout') { 
      steps { checkout scm } 
    } 
    stage('Secrets Scan (Gitleaks)') { 
      steps { 
        sh ''' 
          docker run --rm -v $(pwd):/repo zricethezav/gitleaks:latest \ 
            detect --no-git --source /repo \ 
            --report-format json --report-path gitleaks-report.json || true 
        ''' 
      } 
      post { always { archiveArtifacts 'gitleaks-report.json' } } 
    } 
    stage('Static Analysis (Semgrep)') { 
      steps { 
        sh ''' 
          docker run --rm -v $(pwd):/src -w /src returntocorp/semgrep:latest \ 
            semgrep scan --config p/javascript --config p/owasp-top-ten \ 
            --sarif > semgrep-report.sarif || true 
        ''' 
      } 
      post { always { archiveArtifacts 'semgrep-report.sarif' } } 
    } 
 
stage('SonarQube Analysis') { 
      steps { 
        script { 
          def scanner = tool 'sonar-scanner' 
          withSonarQubeEnv('sonarqube') { 
            sh "${scanner}/bin/sonar-scanner -Dsonar.projectKey=test-app -Dsonar.sources=./src" 
          } 
        } 
      } 
    } 
    stage('Docker Build') { 
      steps { 
        sh 'docker build -t test-app:ci .' 
      } 
    } 
    stage('Trivy Scan') { 
      steps { 
        sh ''' 
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \ 
            aquasec/trivy:latest image --exit-code 0 --severity LOW,MEDIUM test-app:ci 
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \ 
            aquasec/trivy:latest image --exit-code 1 --severity HIGH,CRITICAL test-app:ci 
        ''' 
      } 
      post { always { archiveArtifacts 'trivy-report.json' allowEmptyArchive: true } } 
    } 
    stage('Deploy to Staging') { 
      steps { 
        echo 'Deploying minimal test app (dummy deployment step)...' 
      } 
    } 
    
stage('DAST (OWASP ZAP)') { 
steps { 
sh ''' 
mkdir -p zap 
docker run --rm -u 0 -v $(pwd)/zap:/zap/wrk zaproxy/zap-stable \ 
zap-baseline.py -t http://localhost:3000/health -r zap-report.html || true 
''' 
} 
post { always { archiveArtifacts 'zap/*' allowEmptyArchive: true } } 
} 
} 
} 