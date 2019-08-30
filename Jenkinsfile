pipeline {
  agent {
    kubernetes {
    //cloud 'kubernetes'
    label "wct-app-${UUID.randomUUID().toString()}"
    yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: bitnami/python:3.7
    imagePullPolicy: Always
    command: ['cat']
    tty: true
  - name: kod
    image: ${DOCKER_REGISTRY}/team-vulcan/kubernetes-ops-deployer:latest
    imagePullPolicy: Always
    command: ['cat']
    tty: true
    env:
      - name: DOCKER_HOST
        value: tcp://localhost:2375
  - name: dind
    image: docker:stable-dind
    securityContext:
      privileged: true
    env:
      - name: DOCKER_TLS_CERTDIR
        value: ''
    volumeMounts:
      - name: dind-storage
        mountPath: /var/lib/docker
  volumes:
    - name: dind-storage
      emptyDir: {}
"""
    }
  }
  environment {
    GROUP_NAME = 'vat4ng'
    IMAGE_NAME = 'wct-app'
    FULLY_QUALIFIED_IMAGE_NAME = "${DOCKER_REGISTRY}/${GROUP_NAME}/${IMAGE_NAME}"
    DEV_IMAGE_TAG = "${FULLY_QUALIFIED_IMAGE_NAME}:dev"
    EDGE_IMAGE_TAG = "${FULLY_QUALIFIED_IMAGE_NAME}:edge"
    LATEST_IMAGE_TAG = "${FULLY_QUALIFIED_IMAGE_NAME}:latest"
    RELEASE_IMAGE_TAG = "${FULLY_QUALIFIED_IMAGE_NAME}:${TAG_NAME}"

    AWS_DEFAULT_REGION = "us-east-1"

    // Klar settings
    CLAIR_ADDR = "clair.pipe.svc.cluster.local"
    CLAIR_OUTPUT = "Unknown"
    CLAIR_THRESHOLD = "0"
    CLAIR_TIMEOUT = "1"
    DOCKER_INSECURE = "false"
    REGISTRY_INSECURE = "false"
    JSON_OUTPUT = "true"

    //Whitesource settings
    PRODUCT = "wct-app"
    PROJECT = "wct-app"
  }
  options {
    timeout(time: 1, unit: 'HOURS')
    buildDiscarder(logRotator(numToKeepStr: '5'))
    timestamps()
  }

  stages {
    stage('Install Dependencies') {
      steps {
        container('python') {
          sh '''
            curl -sL https://taskfile.dev/install.sh | sh
            bin/task installDeps
          '''
        }
      }
    }
    stage('Safety Check') {
      steps {
        container('python') {
          sh '''
            bin/task safetyCheck
          '''
        }
      }
    }
    stage('Lint') {
      steps {
        container('python') {
          sh '''
            bin/task lint
          '''
        }
      }
    }
    stage('Test') {
      steps {
        container('python') {
          sh '''
            bin/task test
          '''
        }
      }
    }
    stage('SonarQube Quality Scan') {
      steps {
        container('kod') {
          withSonarQubeEnv('sonar') {
            sh '''
              bin/task sonar
            '''
          }
        }
      }
    }
    stage('Build Container') {
      steps {
        container('kod') {
          sh '''
            bin/task dockerBuild
          '''
        }
      }
    }





    stage('Start Delivery') {
      when {
        anyOf {
          branch 'develop'
          branch 'master'
          buildingTag()
        }
      }
      stages {
        stage('Login Docker') {
          steps {
            container('kod') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                  sh '''
                    bin/task loginEcr
                  '''
              }
            }
          }
        }
        stage('Create Repo') {
          steps {
            container('kod') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                  sh '''
                    bin/task createRepo NAME=${GROUP_NAME}/${IMAGE_NAME}
                  '''
              }
            }
          }
        }
        stage('Push Container') {
          parallel {
            stage('Push Dev') {
              when {
                branch 'develop'
              }
              steps {
                container('kod') {
                  withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    sh '''
                      bin/task pushContainer FULLY_QUALIFIED_IMAGE_NAME=${DEV_IMAGE_TAG}
                    '''
                  }
                }
              }
            }
            stage('Push Edge') {
              when {
                branch 'master'
              }
              steps {
                container('kod') {
                  withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    sh '''
                      bin/task pushContainer FULLY_QUALIFIED_IMAGE_NAME=${EDGE_IMAGE_TAG}
                    '''
                  }
                }
              }
            }
            stage('Push Release') {
              when {
                buildingTag()
              }
              steps {
                container('kod') {
                  withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    sh '''
                      bin/task pushContainer FULLY_QUALIFIED_IMAGE_NAME=${LATEST_IMAGE_TAG}
                      bin/task pushContainer FULLY_QUALIFIED_IMAGE_NAME=${RELEASE_IMAGE_TAG}
                    '''
                  }
                }
              }
            }
          }
        }
      }
    }





    stage('Start Deployment') {
      when {
        anyOf {
          branch 'develop'
          branch 'master'
          buildingTag()
        }
      }
      stages {
        stage('Get Kubeconfig') {
          steps {
            container('kod') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                  sh '''
                    bin/task getKubeconfig
                  '''
              }
            }
          }
        }
        stage('Deploy') {
          parallel {
            stage('Deploy Dev') {
              when {
                branch 'develop'
              }
              steps {
                container('kod') {
                  withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS'],
                    string(credentialsId: 'SAIC_DEVSECOPS_CHARTS_PASSWORD', variable: 'SAIC_DEVSECOPS_CHARTS_PASSWORD')]) {
                    sh '''
                      bin/task deploy ENV=dev KUBE_NAMESPACE=${IMAGE_NAME}-dev TAG_TO_DEPLOY=dev
                    '''
                  }
                }
              }
            }
            stage('Deploy Test') {
              when {
                branch 'master'
              }
              steps {
                container('kod') {
                  withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS'],
                    string(credentialsId: 'SAIC_DEVSECOPS_CHARTS_PASSWORD', variable: 'SAIC_DEVSECOPS_CHARTS_PASSWORD')]) {
                    sh '''
                      bin/task deploy ENV=test KUBE_NAMESPACE=${IMAGE_NAME}-test TAG_TO_DEPLOY=edge
                    '''
                  }
                }
              }
            }
            stage('Deploy Latest') {
              when {
                buildingTag()
              }
              steps {
                container('kod') {
                  withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS'],
                    string(credentialsId: 'SAIC_DEVSECOPS_CHARTS_PASSWORD', variable: 'SAIC_DEVSECOPS_CHARTS_PASSWORD')]) {
                    sh '''
                      bin/task deploy ENV=prod KUBE_NAMESPACE=${IMAGE_NAME} TAG_TO_DEPLOY=latest
                    '''
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  post {
    aborted {
      script {
        currentBuild.result = "ABORTED"
        sendSlackNotification(currentBuild)
      }
    }
    failure {
      script {
        currentBuild.result = "FAILURE"
        sendSlackNotification(currentBuild)
      }
    }
    success {
      script {
        currentBuild.result = "SUCCESS"
        sendSlackNotification(currentBuild)
      }
    }
    unstable {
      script {
        currentBuild.result = "UNSTABLE"
        sendSlackNotification(currentBuild)
      }
    }
  }
}
/**
 *  Sends a Slack notification with a proper build result
 */
def sendSlackNotification(org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper currentBuild) {
  if (env.BRANCH_NAME == 'develop' ||
      env.BRANCH_NAME == 'master' ||
      (env.TAG_NAME != null && env.TAG_NAME.length() > 0)) {
    if (currentBuild.result == "ABORTED") {
        slackSend color: "#b3b3b3", message: "ABORTED: ${currentBuild.fullDisplayName}\n${env.RUN_DISPLAY_URL}"
    }
    else if (currentBuild.result == "SUCCESS") {
        slackSend color: "good", message: "SUCCESS: ${currentBuild.fullDisplayName}\n${env.RUN_DISPLAY_URL}";
    }
    else if (currentBuild.result == "FAILURE") {
        slackSend color: "danger", message: "FAILURE: ${currentBuild.fullDisplayName}\n${env.RUN_DISPLAY_URL}";
    }
    else if (currentBuild.result == "UNSTABLE") {
        slackSend color: "warning", message: "UNSTABLE: ${currentBuild.fullDisplayName}\n${env.RUN_DISPLAY_URL}";
    }
    else {
        slackSend color: "danger", message: "UNKNOWN: ${currentBuild.fullDisplayName}\n${env.RUN_DISPLAY_URL}";
    }
  }
}
