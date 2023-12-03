pipeline {
    agent any
    tools {
      maven 'MAVEN_HOME'
      jdk 'JAVA_HOME'
    }

      triggers {
        githubPush()
      }

    stages {
        stage('Buildd2') {
            steps {
                sh 'echo "$PATH"'
                sh 'echo "$M2_HOME"'
                sh 'mvn -v'
            }
        }
        stage('Buildd') {
            steps {
                sh 'mvn -B -DskipTests -DskipFTs -Dmaven.test.skip=true clean package -Dquarkus.package.type=fast-jar'
            }
        }
        stage('Docker Build') {
            steps {
                sh 'sudo docker build --no-cache --build-arg HTTP_PROXY --build-arg https_proxy --build-arg no_proxy -f=src/docker/Dockerfile.jvm -t marvel:marvel_Tag .'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}