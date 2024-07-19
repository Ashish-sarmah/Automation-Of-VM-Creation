// This is jenkins pipeline for VM creation.

//Declaring Global variables, quick tip: In Jenkins local variables are defined using keyword 'def' , without 'def' variables are accessible throughout the Jenkinsfile.
DIR_PATH = 'VM_Management'             // All paths are relative to Jenkins Workspace
HELPER_PATH = 'VM_Management/HelperFiles'
SCAN_IP_PATH = 'VM_Management/ScanIP'
INVENTORY_PATH = 'VM_Management/InventoryFiles'
APPROVAL_EMAIL_LIST = "ashish.sharma@opshub.com" 
USERS_CAN_APPROVE = "admin,kinjal" 
INP_TIMEOUT = 3                   // ---> provided value will be considered as Hours, you can update the unit in input section of Approval.
MESSAGE = ""                      // ---> this field will be sent in user email

def CheckIP(ip){

    def (net_addr, host_addr1, host_addr2, host_addr3) = ip.split('\\.')      // ---> here I am splitting the IP according to Class A addresses. First octet is network address, and remaining is host address. Double-slash is used to escape '.' character.
    
    host_addr3 = Integer.parseInt(host_addr3)

    if( net_addr && host_addr1 && host_addr2 && host_addr3 && net_addr == '10' && host_addr1 == '13' && ((host_addr2 == '28' && Region == 'INDIA') || (host_addr2 == '27' && Region == 'US')) && (host_addr3 < 254) ) {

        def path = "${SCAN_IP_PATH}/check_ip.sh"                 // --> Script to verify provided IP is available.
        def flag = sh(script: "$path $ip", returnStdout: true).trim() 

        // flag value being "1" signifies IP is available to use.
        if(flag == "1") {
            echo "Provided IP is available to use." 
            return true
        }
        else {
            echo "IP ${ip} provided is not free to be used. You may enter another one."
            return false
        }
    }
    else {
        echo "Ip entered is invalid. You may enter another one."
        return false
    } 
}

def Approval() {
   
    
    def descript = """VM Name: ${params.VM_Name}\nOS: ${params.OS}\nCores: ${params.Cores}\nRAM: ${params.RAM}\nRegion: ${params.Region}\nPurpose: ${params.Purpose}\nIP: ${env.IP}\nRequested by: ${BUILD_USER}\nUser Email: ${BUILD_USER_EMAIL}\n\nSelect Yes to approve or No to reject """
    def result = input(
                id: 'input_approval',
                message: 'Do you approve this VM provisioning?',
                ok: 'approve',
                submitter: "${USERS_CAN_APPROVE}",
                parameters: [
                    choice(name: 'VM_Creation', choices: ['Yes', 'No'],

 description: "${descript}" ) ,
                    string(name: 'Description [OPTIONAL]', description: 'Reason for not approving VM Creation. Provide this field if VM is not being provisioned, will be sent to user in email', trim: true) ,
                    string(name: 'Manual IP [OPTIONAL]',  description: 'Note: IP entered should be according to the "Region" field chosen earlier. Leave empty if current IP value is alright.', trim : true)
                ]
                )
    
    def approval = result['VM_Creation']
    def ip = result['Manual IP [OPTIONAL]']

  
    if (approval == 'No') {
        MESSAGE = result['Description [OPTIONAL]']
        error("VM provisioning was not approved")
    }
    else if(approval == 'Yes' && !ip) {
        echo "Continuing with previous IP"
    }
    else {
        def check = CheckIP(ip)
        if(check){      
            return ip
        }
        else {
            return Approval()
        }
    }
    
    return env.IP               // ---> return previous IP value.
}

// To assign IP if not available in the provided range.
def NewIP() {
    def ip = input(
                message: 'Provide an IP [Required]',
                ok: 'Proceed',
                submitter: "${USERS_CAN_APPROVE}",
                parameters: [
                string(name: 'IP ADDRESS',  description: 'Note: IP entered should be according to the "Region" field chosen earlier', trim : true)
                ]
            )
    if(ip) {
        def check = CheckIP(ip)
        if(check){      
            return ip
        }
        else {
            return NewIP()
        }
    }
    echo "No input from your side :("
    return ip
}



pipeline {
    agent any

    parameters {
        string(name: 'VM_Name', description: 'Name of the virtual machine [Mandatory Field]')

        choice(name: 'Region', choices: ['US', 'INDIA'], description: 'Select a Region')

        choice(name: 'Purpose', choices: ['Testing', 'Production'], description: 'Reason for VM Provisioning')

        choice(name: 'OS', choices: ['Ubuntu_22.04', 'Ubuntu_24.04', 'Windows_Server_2016' , 'Windows_Server_2019'], description: 'Operating System')
        
        choice(name: 'Cores', choices: ['1', '2', '4', '6'], description: 'Number of CPU cores')
        
        choice(name: 'RAM', choices: [ '8GB', '10GB', '12GB','14GB', '16GB'], description: 'Amount of RAM')

        string(name: 'OH_ID')

        string(name: 'User_Email', description: 'User that triggered build')
    }

    stages{
        stage("Validate input and remove old error.log file(if any)"){
            steps{
                script {
                    if(!params.VM_Name) {
                        error("Build failed because a mandatory field is not provided called 'VM_Name' ")
                    }
                    
                    def path = "${DIR_PATH}/error.log"  
                    sh "rm -f ${path}"                           // remove old error.log, if present
                }
            }
        }

        stage('Scan for IP') {
            steps {
                script {

                    def path = ""
                    if(Region == "US") {
                        sh(script: "${HELPER_PATH}/ensure_us_vpn_is_up.sh")           //execute ensure_us_vpn_is_up.sh script to ensure VM is connected to US VPN
                        path = "${SCAN_IP_PATH}/scan_ip_range_us.sh"
                    }
                    else {
                        path = "${SCAN_IP_PATH}/scan_ip_range_india.sh"
                    }

                    def output_ip = sh(script: "$path" , returnStdout: true).trim()
                    
                    env.IP = output_ip                             // Set the environment variable
                    echo "Ip to be assigned: ${env.IP}"

                    if(!env.IP) {
                        echo "IP not available in the provided range. Enter One Manually"
                        env.IP = NewIP()
                        if(!env.IP) {
                            error "IP not available"
                        }
                        else {
                            echo "IP to be assigned to VM: ${env.IP}"
                        }
                    }
                    else {
                        echo "IP to be assigned to VM: ${env.IP}"
                    }                  
                }
            }
        }

        // stage('Locally host api') {
        //     steps{
        //         script{
        //             sh "sudo kill -9 `sudo lsof -t -i:5000`"        //kill any already running process on port 5000
        //             sh "python3 '${HELPER_PATH}/approve.py'"
        //         }
        //     }
        // }

        stage('Request Approval') {
            steps {
                timeout(time: "${INP_TIMEOUT}", unit: 'HOURS') {               // other units: 'MINUTES', 'DAYS'
                    script {
                        env.jenkins_window = 'input'
                        emailext (
                            subject: "Approval needed for VM Creation in Jenkins",
                            body: '${FILE,path="VM_Management/HelperFiles/VM_Details_template.html"}',        // Required to pass absolute path
                            to: "${APPROVAL_EMAIL_LIST}",
                            mimeType: 'text/html'
                        )
                        env.IP = Approval()                                     // Call for Approval
                
                    }
                }           
            }
        }
        
        stage("Create VM") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'infra-automationuser' , usernameVariable: 'username', passwordVariable: 'password')]) {
                    sh """
                        
                        echo "#!/bin/bash" > "${HELPER_PATH}/vault_pass.sh"
                        echo "echo \$password" >> "${HELPER_PATH}/vault_pass.sh"
                        chmod "700" "${HELPER_PATH}/vault_pass.sh"
                        ansible-vault decrypt --vault-password-file "${HELPER_PATH}/vault_pass.sh" ${INVENTORY_PATH}/Hosts_sensitive_config.ini
                        rm "${HELPER_PATH}/vault_pass.sh"
                        cat ${INVENTORY_PATH}/Hosts_sensitive_config.ini >> ${INVENTORY_PATH}/hosts.ini
                        ansible-playbook -i "${INVENTORY_PATH}/hosts.ini"  ${DIR_PATH}/vm_create_config.yml \
                        -e "vm_name=${VM_Name} OS=${OS} ram=${RAM} cores=${Cores} ip_address=${env.IP} region=${Region}"
                        
                    """
                }
            }
// ansible-vault decrypt --vault-password-file ./"${HELPER_PATH}/vault_pass.sh" "${INVENTORY_PATH}/individual_hosts_config.ini"            
        }

    }
    
    post {
        always {
	        script{
		        // The body of this email contains content of error.log generated dynamically during above playbook execution. This is done to ensure that if VM creation fails on some check , the error reaches to the user.

                // Read the content of error.log
                def path = "${DIR_PATH}/error.log"
                def error_message = ""
                if(fileExists(path)) {
                    error_message = readFile("${path}").trim()
                }
                env.jenkins_window = ''
                // Send email to user using emailext plugin
                emailext (
                    to: "${email}",
                    subject: 'VM Creation Email from Jenkins',
                    body: '${FILE,path="VM_Management/HelperFiles/VM_Details_template.html"}' + "<html><p><br><b>BUILD STATUS : ${currentBuild.currentResult}<br><br>${MESSAGE}${error_message}</b></p></html>" ,               //Absolute path is required
                    mimeType: 'text/html'
                )
            }
        }
    }
}

