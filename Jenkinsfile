pipeline {

    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        APP_NAME = 'cloudshift-store'
        IMAGE_NAME = 'cloudshift-store'

        STAGING_CONTAINER = 'cloudshift-staging'
        STAGING_PORT = '8081'

        PRODUCTION_CONTAINER = 'cloudshift-store'
        PRODUCTION_PORT = '80'

        APP_URL = 'http://34.227.75.138'
        STAGING_URL = 'http://34.227.75.138:8081'
    }

    triggers {
        githubPush()
    }

    stages {

        stage('Checkout') {
            steps {

                echo '========================================='
                echo 'CHECKOUT'
                echo '========================================='

                checkout scm

                sh '''
                    echo "Repository:"
                    git remote get-url origin

                    echo ""
                    echo "Branch:"
                    git branch --show-current

                    echo ""
                    echo "Commit:"
                    git rev-parse --short HEAD

                    echo ""
                    echo "Commit message:"
                    git log -1 --pretty=%B
                '''
            }
        }

        stage('Build') {
            steps {

                echo '========================================='
                echo 'BUILD APPLICATION'
                echo '========================================='

                sh '''
                    set -e

                    echo "Checking Python..."
                    python3 --version

                    echo "Checking Docker..."
                    docker --version

                    echo ""
                    echo "Building Docker image..."

                    docker build \
                        -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                        -t ${IMAGE_NAME}:latest \
                        .

                    echo ""
                    echo "Docker image successfully built."

                    docker images ${IMAGE_NAME}
                '''
            }
        }

        stage('Test') {
            steps {

                echo '========================================='
                echo 'RUN TESTS'
                echo '========================================='

                sh '''
                    set -e

                    echo "Running application tests inside Docker..."

                    docker run --rm \
                        ${IMAGE_NAME}:${BUILD_NUMBER} \
                        python -m pytest -v test_backup.py

                    echo ""
                    echo "All tests passed."
                '''
            }
        }

        stage('Deploy to Staging') {
            steps {

                echo '========================================='
                echo 'DEPLOY TO STAGING'
                echo '========================================='

                sh '''
                    set -e

                    echo "Removing previous staging container..."

                    docker rm -f ${STAGING_CONTAINER} 2>/dev/null || true

                    echo "Starting new staging container..."

                    docker run -d \
                        --name ${STAGING_CONTAINER} \
                        -p ${STAGING_PORT}:5000 \
                        -e ENVIRONMENT=staging \
                        -e PROVISIONED_BY=jenkins \
                        -e INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo unknown) \
                        ${IMAGE_NAME}:${BUILD_NUMBER}

                    echo ""
                    echo "Staging container started."

                    docker ps \
                        --filter "name=${STAGING_CONTAINER}"
                '''
            }
        }

        stage('Staging Health Check') {
            steps {

                echo '========================================='
                echo 'STAGING HEALTH CHECK'
                echo '========================================='

                sh '''
                    set -e

                    echo "Waiting for staging application..."

                    sleep 5

                    echo "Checking staging health endpoint..."

                    curl --fail \
                        --retry 5 \
                        --retry-delay 2 \
                        http://localhost:${STAGING_PORT}/healthz

                    echo ""
                    echo "Staging health check PASSED."
                '''
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }

            steps {

                echo '========================================='
                echo 'DEPLOY TO PRODUCTION'
                echo '========================================='

                sh '''
                    set -e

                    echo "Production deployment starting..."

                    echo "Stopping existing production application..."

                    docker compose stop app || true

                    echo "Removing old production container..."

                    docker compose rm -f app || true

                    echo "Starting production application with new image..."

                    docker compose up -d --build app

                    echo ""
                    echo "Production application started."

                    docker ps \
                        --filter "name=${PRODUCTION_CONTAINER}"
                '''
            }
        }

        stage('Production Health Check') {
            when {
                branch 'main'
            }

            steps {

                echo '========================================='
                echo 'PRODUCTION HEALTH CHECK'
                echo '========================================='

                sh '''
                    set -e

                    echo "Waiting for production application..."

                    sleep 5

                    echo "Checking production health endpoint..."

                    curl --fail \
                        --retry 10 \
                        --retry-delay 2 \
                        ${APP_URL}/healthz

                    echo ""
                    echo "Production health check PASSED."
                '''
            }
        }

        stage('Verify Monitoring') {
            when {
                branch 'main'
            }

            steps {

                echo '========================================='
                echo 'VERIFY MONITORING STACK'
                echo '========================================='

                sh '''
                    set -e

                    echo "Checking Docker services..."

                    docker compose ps

                    echo ""
                    echo "Checking Prometheus..."

                    curl --fail \
                        --retry 5 \
                        --retry-delay 2 \
                        http://localhost:9090/-/healthy

                    echo ""
                    echo "Prometheus is healthy."

                    echo ""
                    echo "Checking Grafana..."

                    curl --fail \
                        --retry 5 \
                        --retry-delay 2 \
                        http://localhost:3000/api/health

                    echo ""
                    echo "Grafana is healthy."
                '''
            }
        }
    }

    post {

        success {

            echo '========================================='
            echo 'PIPELINE SUCCESS'
            echo '========================================='

            echo """
            Jenkins successfully completed the CI/CD pipeline.

            Application:
            ${APP_URL}

            Staging:
            ${STAGING_URL}

            Jenkins:
            http://34.227.75.138:8080

            Prometheus:
            http://34.227.75.138:9090

            Grafana:
            http://34.227.75.138:3000
            """
        }

        failure {

            echo '========================================='
            echo 'PIPELINE FAILED'
            echo '========================================='

            sh '''
                echo "Docker containers:"
                docker ps -a || true

                echo ""
                echo "Staging logs:"
                docker logs --tail 50 ${STAGING_CONTAINER} 2>/dev/null || true

                echo ""
                echo "Production logs:"
                docker logs --tail 50 ${PRODUCTION_CONTAINER} 2>/dev/null || true

                echo ""
                echo "Compose services:"
                docker compose ps || true
            '''
        }

        always {

            echo '========================================='
            echo 'PIPELINE CLEANUP'
            echo '========================================='

            echo 'Removing staging container...'

            sh '''
                docker rm -f ${STAGING_CONTAINER} 2>/dev/null || true
            '''

            cleanWs()
        }
    }
}