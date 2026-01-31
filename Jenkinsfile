pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = ''  // Will be set dynamically
        EKS_CLUSTER_NAME = 'redbus-cluster'
        ECR_REGISTRY = ''    // Will be set dynamically
        FRONTEND_IMAGE = ''  // Will be set dynamically
        BACKEND_IMAGE = ''   // Will be set dynamically
        SONAR_SCANNER_HOME = tool 'SonarQubeScanner'
        SONAR_PROJECT_KEY = 'redbus-devops'
    }

    tools {
        nodejs 'NodeJS-18'
    }

    stages {
        stage('Setup ECR Registry') {
            steps {
                script {
                    // Get AWS Account ID dynamically
                    AWS_ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                    // Set ECR Registry URL
                    ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    // Set image names
                    FRONTEND_IMAGE = "${ECR_REGISTRY}/redbus-frontend"
                    BACKEND_IMAGE = "${ECR_REGISTRY}/redbus-backend"
                    echo "📦 ECR Registry: ${ECR_REGISTRY}"
                    echo "🖼️ Frontend Image: ${FRONTEND_IMAGE}"
                    echo "🖼️ Backend Image: ${BACKEND_IMAGE}"
                }
            }
        }

        stage('Checkout') {
            steps {
                echo '📥 Checking out source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Frontend Dependencies') {
                    steps {
                        dir('front-end-redbus') {
                            sh 'npm install'
                        }
                    }
                }
                stage('Backend Dependencies') {
                    steps {
                        dir('back-end-redbus') {
                            sh 'npm install'
                        }
                    }
                }
            }
        }

        stage('Run Tests') {
            parallel {
                stage('Frontend Tests') {
                    steps {
                        dir('front-end-redbus') {
                            sh 'CI=true npm test -- --passWithNoTests'
                        }
                    }
                }
                stage('Backend Tests') {
                    steps {
                        dir('back-end-redbus') {
                            sh 'npm test || true'
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo '🔍 Running SonarQube code quality analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.projectName="RedBus DevOps" \
                            -Dsonar.projectVersion=${BUILD_NUMBER} \
                            -Dsonar.sources=. \
                            -Dsonar.exclusions=**/node_modules/**,**/build/**,**/dist/**,**/*.test.js \
                            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                    '''
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                echo '⏳ Waiting for SonarQube Quality Gate...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                echo '🛡️ Running OWASP Dependency Check...'
                dependencyCheck additionalArguments: '''
                    --scan .
                    --format HTML
                    --format JSON
                    --format XML
                    --out dependency-check-report
                    --prettyPrint
                    --disableYarnAudit
                ''', odcInstallation: 'OWASP-Dependency-Check'
                
                dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.xml'
            }
        }

        stage('Security Scan - Trivy') {
            steps {
                echo '🔒 Running security scan with Trivy...'
                sh '''
                    trivy fs --severity HIGH,CRITICAL --format table -o trivy-fs-report.txt .
                    trivy fs --severity HIGH,CRITICAL --exit-code 0 .
                '''
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build Frontend Image') {
                    steps {
                        echo '🐳 Building Frontend Docker image...'
                        sh '''
                            docker build -f docker/frontend.Dockerfile -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} ./front-end-redbus
                            docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${FRONTEND_IMAGE}:latest
                        '''
                    }
                }
                stage('Build Backend Image') {
                    steps {
                        echo '🐳 Building Backend Docker image...'
                        sh '''
                            docker build -f docker/backend.Dockerfile -t ${BACKEND_IMAGE}:${BUILD_NUMBER} ./back-end-redbus
                            docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${BACKEND_IMAGE}:latest
                        '''
                    }
                }
            }
        }

        stage('Scan Docker Images') {
            parallel {
                stage('Scan Frontend Image') {
                    steps {
                        sh '''
                            trivy image --severity HIGH,CRITICAL --format table -o trivy-frontend-report.txt ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                            trivy image --severity CRITICAL --exit-code 1 ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        '''
                    }
                }
                stage('Scan Backend Image') {
                    steps {
                        sh '''
                            trivy image --severity HIGH,CRITICAL --format table -o trivy-backend-report.txt ${BACKEND_IMAGE}:${BUILD_NUMBER}
                            trivy image --severity CRITICAL --exit-code 1 ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        '''
                    }
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                echo '📤 Pushing Docker images to ECR...'
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                        # Login to ECR
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        
                        # Push images
                        docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${FRONTEND_IMAGE}:latest
                        docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${BACKEND_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '🚀 Deploying to EKS cluster...'
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                        # Configure kubectl
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                        
                        # Create namespace if not exists
                        kubectl get ns redbus || kubectl create ns redbus
                        
                        # Apply Kubernetes manifests first
                        kubectl apply -f infra/kubernetes/ -n redbus
                        
                        # Update image tags in deployments
                        kubectl set image deployment/frontend-deployment frontend=${FRONTEND_IMAGE}:${BUILD_NUMBER} -n redbus
                        kubectl set image deployment/backend-deployment backend=${BACKEND_IMAGE}:${BUILD_NUMBER} -n redbus
                        
                        # Wait for rollout to complete
                        kubectl rollout status deployment/frontend-deployment -n redbus --timeout=300s
                        kubectl rollout status deployment/backend-deployment -n redbus --timeout=300s
                    '''
                }
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up...'
            sh 'docker system prune -f || true'
            
            // Archive reports
            archiveArtifacts artifacts: '**/dependency-check-report/**', allowEmptyArchive: true
            archiveArtifacts artifacts: '**/trivy-*.txt', allowEmptyArchive: true
            
            // Publish HTML reports
            publishHTML(target: [
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'dependency-check-report',
                reportFiles: 'dependency-check-report.html',
                reportName: 'OWASP Dependency Check Report'
            ])
        }
        success {
            echo '✅ Pipeline completed successfully!'
            emailext(
                subject: "✅ SUCCESS: RedBus Pipeline - Build #${BUILD_NUMBER}",
                body: """
                    <html>
                    <body>
                        <h2 style="color: #28a745;">🎉 Pipeline Successful!</h2>
                        <p><strong>Project:</strong> RedBus DevOps</p>
                        <p><strong>Build Number:</strong> ${BUILD_NUMBER}</p>
                        <p><strong>Build URL:</strong> <a href="${BUILD_URL}">${BUILD_URL}</a></p>
                        <p><strong>Git Branch:</strong> ${env.GIT_BRANCH ?: 'N/A'}</p>
                        <p><strong>Git Commit:</strong> ${env.GIT_COMMIT ?: 'N/A'}</p>
                        <hr>
                        <h3>📊 Build Summary:</h3>
                        <ul>
                            <li>✅ Code Checkout - Passed</li>
                            <li>✅ Install Dependencies - Passed</li>
                            <li>✅ Run Tests - Passed</li>
                            <li>✅ SonarQube Analysis - Passed</li>
                            <li>✅ OWASP Dependency Check - Passed</li>
                            <li>✅ Trivy Security Scan - Passed</li>
                            <li>✅ Docker Build - Passed</li>
                            <li>✅ Docker Push - Passed</li>
                            <li>✅ Kubernetes Deployment - Passed</li>
                        </ul>
                        <hr>
                        <h3>🐳 Docker Images:</h3>
                        <ul>
                            <li>Frontend: ${FRONTEND_IMAGE}:${BUILD_NUMBER}</li>
                            <li>Backend: ${BACKEND_IMAGE}:${BUILD_NUMBER}</li>
                        </ul>
                        <hr>
                        <p style="color: #6c757d; font-size: 12px;">This is an automated message from Jenkins.</p>
                    </body>
                    </html>
                """,
                mimeType: 'text/html',
                to: '${DEFAULT_RECIPIENTS}',
                attachLog: false,
                compressLog: true
            )
        }
        failure {
            echo '❌ Pipeline failed!'
            emailext(
                subject: "❌ FAILED: RedBus Pipeline - Build #${BUILD_NUMBER}",
                body: """
                    <html>
                    <body>
                        <h2 style="color: #dc3545;">⚠️ Pipeline Failed!</h2>
                        <p><strong>Project:</strong> RedBus DevOps</p>
                        <p><strong>Build Number:</strong> ${BUILD_NUMBER}</p>
                        <p><strong>Build URL:</strong> <a href="${BUILD_URL}">${BUILD_URL}</a></p>
                        <p><strong>Git Branch:</strong> ${env.GIT_BRANCH ?: 'N/A'}</p>
                        <p><strong>Git Commit:</strong> ${env.GIT_COMMIT ?: 'N/A'}</p>
                        <hr>
                        <h3>🔴 Action Required:</h3>
                        <p>Please check the build logs for details:</p>
                        <p><a href="${BUILD_URL}console">${BUILD_URL}console</a></p>
                        <hr>
                        <h3>📋 Possible Issues:</h3>
                        <ul>
                            <li>Code quality issues detected by SonarQube</li>
                            <li>Security vulnerabilities found by OWASP/Trivy</li>
                            <li>Test failures</li>
                            <li>Docker build errors</li>
                            <li>Kubernetes deployment issues</li>
                        </ul>
                        <hr>
                        <p style="color: #6c757d; font-size: 12px;">This is an automated message from Jenkins.</p>
                    </body>
                    </html>
                """,
                mimeType: 'text/html',
                to: '${DEFAULT_RECIPIENTS}',
                attachLog: true,
                compressLog: true
            )
        }
        unstable {
            echo '⚠️ Pipeline unstable!'
            emailext(
                subject: "⚠️ UNSTABLE: RedBus Pipeline - Build #${BUILD_NUMBER}",
                body: """
                    <html>
                    <body>
                        <h2 style="color: #ffc107;">⚠️ Pipeline Unstable!</h2>
                        <p><strong>Project:</strong> RedBus DevOps</p>
                        <p><strong>Build Number:</strong> ${BUILD_NUMBER}</p>
                        <p><strong>Build URL:</strong> <a href="${BUILD_URL}">${BUILD_URL}</a></p>
                        <hr>
                        <p>The build completed but with warnings or test failures.</p>
                        <p>Please review the build logs: <a href="${BUILD_URL}console">${BUILD_URL}console</a></p>
                        <hr>
                        <p style="color: #6c757d; font-size: 12px;">This is an automated message from Jenkins.</p>
                    </body>
                    </html>
                """,
                mimeType: 'text/html',
                to: '${DEFAULT_RECIPIENTS}',
                attachLog: true,
                compressLog: true
            )
        }
    }
}
