pipeline {
    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

    agent any

    stages {
        // Checkout the Terraform code from Git
        stage('Checkout') {
            steps {
                script {
                    // Clone the repository into the default workspace
                    git branch: 'main', url: 'https://github.com/Vigneswaran-Murthy/Terraform-jenkinsownbuild.git'

                }
            }
        }

        // Initialize Terraform and create the execution plan
        stage('Plan') {
            steps {
                script {
                    // Initialize Terraform in the working directory
                    sh 'pwd; terraform init'
                    // Generate the terraform plan and output it to a file
                    sh 'terraform plan -out=tfplan'
                    // Show the plan content and save it to a file for review
                    sh 'terraform show -no-color tfplan > tfplan.txt'
                }
            }
        }

        // Approval stage to review and approve the plan before applying
        stage('Approval') {
            when {
                not {
                    equals expected: true, actual: params.autoApprove
                }
            }
            steps {
                script {
                    // Read the terraform plan content
                    def plan = readFile 'tfplan.txt'
                    // Request approval from the user before applying
                    input message: "Do you want to apply the plan?", 
                          parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                }
            }
        }

        // Apply the Terraform plan
        stage('Apply') {
            steps {
                script {
                    // Apply the Terraform plan (use auto-approve if parameter is true)
                    if (params.autoApprove) {
                        sh 'terraform apply -auto-approve tfplan'
                    } else {
                        sh 'terraform apply tfplan'
                    }
                }
            }
        }
    }
}
