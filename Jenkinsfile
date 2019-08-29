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

    // // kubernetes-ops-deployer settings
    // GIT_URL_NO_PROTOCOL = 'github.com/saic-devsecops/hello-world-ops-config.git'
    // APPLICATION_NAME = 'hello-world'
    // APPLICATION_PROTOCOL = 'http://'
    // APPLICATION_HEALTH_ENDPOINT = '/management/health'
    // SERVICE_DEPLOY_TAG_NAME = 'HELLO_WORLD_GATEWAY_DEPLOY_TAG'
  }
  options {
    timeout(time: 1, unit: 'HOURS')
    buildDiscarder(logRotator(numToKeepStr: '5'))
    timestamps()
  }

  // options {
  //   gitLabConnection('code.saicinnovationfactory.com')
  //   timeout(time: 1, unit: 'HOURS')
  // }
  // triggers {
  //   gitlab(triggerOnPush: true, triggerOnMergeRequest: true, branchFilterType: 'All')
  // }
  // environment {
  //   GROUP_NAME = 'devsecops/docker-images'
  //   IMAGE_NAME = 'rclone'
  //   FULLY_QUALIFIED_IMAGE_NAME = "${DOCKER_REGISTRY}/${GROUP_NAME}/${IMAGE_NAME}"
  //   LOCAL_IMAGE_TAG = "${FULLY_QUALIFIED_IMAGE_NAME}:local"
  //   EDGE_IMAGE_TAG = "${FULLY_QUALIFIED_IMAGE_NAME}:edge"
  //   LATEST_IMAGE_TAG = "${FULLY_QUALIFIED_IMAGE_NAME}:latest"
  //   RELEASE_IMAGE_TAG = "${FULLY_QUALIFIED_IMAGE_NAME}:${TAG_NAME}"
  // }

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

    stage('Build Container') {
      steps {
        container('kod') {
          sh '''
            bin/task dockerBuild
          '''
        }
      }
    }

    stage('Deliver') {
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
  // if (env.BRANCH_NAME == 'develop' ||
  //     env.BRANCH_NAME == 'master' ||
  //     (env.TAG_NAME != null && env.TAG_NAME.length > 0)) {
  if (true) {
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
