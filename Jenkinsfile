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
  - name: docker
    image: docker:stable
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
    LOCAL_IMAGE_TAG = "${FULLY_QUALIFIED_IMAGE_NAME}:local"
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
    PRODUCT = "hello-world-gateway"
    PROJECT = "hello-world-gateway"

    // kubernetes-ops-deployer settings
    GIT_URL_NO_PROTOCOL = 'github.com/saic-devsecops/hello-world-ops-config.git'
    APPLICATION_NAME = 'hello-world'
    APPLICATION_PROTOCOL = 'http://'
    APPLICATION_HEALTH_ENDPOINT = '/management/health'
    SERVICE_DEPLOY_TAG_NAME = 'HELLO_WORLD_GATEWAY_DEPLOY_TAG'
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

    stage("Build") {
      steps {
        container('docker') {
          sh '''
            docker build --pull -t ${LOCAL_IMAGE_TAG} ./src/docker
          '''
        }
      }
    }

    stage("Deliver") {
      when {
        anyOf {
          branch 'master'
          buildingTag()
        }
      }
      stages {

        stage("Login Docker") {
          steps {
            container('docker') {
              withCredentials([usernamePassword(credentialsId: 'gitlab-creds', passwordVariable: 'GITLAB_PASSWORD', usernameVariable: 'GITLAB_USERNAME')]) {
                  sh '''
                    docker login -u ${GITLAB_USERNAME} -p ${GITLAB_PASSWORD} ${DOCKER_REGISTRY}
                  '''
              }
            }
          }
        }

        stage('Push Container'){
          parallel {
            stage('Push Edge') {
              when {
                branch 'master'
              }
              steps {
                container('docker') {
                  sh '''
                    docker tag ${LOCAL_IMAGE_TAG} ${EDGE_IMAGE_TAG}
                    docker push ${EDGE_IMAGE_TAG}
                  '''
                }
              }
            }

            stage ('Push Release') {
              when {
                buildingTag()
              }
              steps {
                container('docker') {
                  sh '''
                    docker tag ${LOCAL_IMAGE_TAG} ${RELEASE_IMAGE_TAG}
                    docker push ${RELEASE_IMAGE_TAG}
                    docker tag ${LOCAL_IMAGE_TAG} ${LATEST_IMAGE_TAG}
                    docker push ${LATEST_IMAGE_TAG}
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