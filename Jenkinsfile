pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {

        git 'https://github.com/Ebikakpou/cloud-automation-toolkit.git'
    stage('Build & Test') {
      steps {
        sh 'pip install pytest'
        sh 'pytest test_backup.py'
      }
    }

