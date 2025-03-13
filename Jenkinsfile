pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['Запустить', 'Рестарт', 'Бекап и свернуть'],
            description: 'Выберите действие: полный запуск, рестарт или бекап и остановка (свернуть)'
        )
    }

    environment {
        REMOTE_HOST    = '34.208.104.73'
        REMOTE_USER    = 'ubuntu'
        CREDENTIALS_ID = 'b651ff7a-570c-4930-9fc5-3c3a7a99b547'
        REMOTE_DIR     = '/opt/myapp'
    }

    stages {

        stage('Checkout') {
            when { expression { params.ACTION == 'Запустить' } }
            steps {
                git branch: 'main',
                    url: 'git@github.com:Xelmsli/test-jenkins.git',
                    credentialsId: 'b651ff7a-570c-4930-9fc5-3c3a7a99b547'
            }
        }

        stage('Transfer Code to Remote') {
            when { expression { params.ACTION == 'Запустить' } }
            steps {
                script {
                    sshagent([env.CREDENTIALS_ID]) {
                        sh "ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'sudo mkdir -p ${REMOTE_DIR}'"
                    }
                    sshagent([env.CREDENTIALS_ID]) {
                        sh "rsync -avz --delete --rsync-path='sudo rsync' -e \"ssh -o StrictHostKeyChecking=no\" . ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}"
                    }
                }
            }
        }

        stage('Install Dependencies on Remote') {
            when { expression { params.ACTION == 'Запустить' } }
            steps {
                script {
                    sshagent([env.CREDENTIALS_ID]) {
                        sh """
                           ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "bash -s" << 'EOF'
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Installing Docker and curl..."
  sudo apt-get update && sudo apt-get install -y docker.io curl
else
  echo "Docker is installed"
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is not installed. Installing Docker Compose v2..."
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  LATEST=\$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
  sudo curl -SL https://github.com/docker/compose/releases/download/\${LATEST}/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
else
  echo "Docker Compose v2 is installed"
fi
EOF
                        """
                    }
                }
            }
        }

        stage('Build on Remote') {
            when { expression { params.ACTION == 'Запустить' } }
            steps {
                script {
                    sshagent([env.CREDENTIALS_ID]) {
                        sh """
                           ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                             cd ${REMOTE_DIR} &&
                             echo "Содержимое ${REMOTE_DIR}:" && ls -la &&
                             sudo docker compose -f docker-compose.yml build
                           '
                        """
                    }
                }
            }
        }

        stage('Deploy on Remote') {
            when { expression { params.ACTION == 'Запустить' } }
            steps {
                script {
                    sshagent([env.CREDENTIALS_ID]) {
                        sh """
                           ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                             cd ${REMOTE_DIR} &&
                             echo "Содержимое ${REMOTE_DIR}:" && ls -la &&
                             sudo docker compose -f docker-compose.yml up -d
                           '
                        """
                    }
                    sleep 10
                }
            }
        }

        stage('Test WebApp on Remote') {
            when { expression { params.ACTION == 'Запустить' } }
            steps {
                script {
                    sshagent([env.CREDENTIALS_ID]) {
                        def response = sh(
                            script: "ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'curl -s -o /dev/null -w \"%{http_code}\" http://localhost:5000'",
                            returnStdout: true
                        ).trim()

                        if (response != '200') {
                            error "Health-check failed: received HTTP ${response}"
                        } else {
                            echo "Health-check passed: received HTTP 200"
                        }
                    }
                }
            }
        }

        stage('Restart on Remote') {
            when { expression { params.ACTION == 'Рестарт' } }
            steps {
                sshagent([env.CREDENTIALS_ID]) {
                    sh "ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_DIR} && sudo docker compose restart'"
                }
            }
        }

        stage('Backup and Shutdown') {
            when { expression { params.ACTION == 'Бекап и свернуть' } }
            steps {
                sshagent([env.CREDENTIALS_ID]) {

                    sh "ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_DIR} && sudo tar -czf backup_\\\$(date +%Y%m%d%H%M%S).tar.gz .'"
                }
                sshagent([env.CREDENTIALS_ID]) {
                    sh "ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_DIR} && sudo docker compose down'"
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
    }
}
