#!/bin/bash

#  An automation script to provision AWS EC2 instance into sandbox account.  This will get your AWS account ID and then request access to the DB AMI.  Then it will run a Terraform script to provision an EC2 instance.

course_selection=-1
#menu for selecting class to provision VM
display_menu () {
    echo -e "Please select the class you are creating a virtual machine for:\n1. ITM111\n2. ITM220\n3. ITM325\n4. DEFAULT\n"
}

#get user input of the selection of a class
user_input () {
    read -p "Choose your class by entering [1-4] for the class selection: " course_selection

        case $course_selection in
            1)
                echo "You have selected ITM111 for the VM."
                ;;
            2)
                echo "You have selected ITM220 for the VM."
                ;;
            3)
                echo "You have selected ITM325 for the VM."
                ;;
            4)
                echo "You have selected the default VM."
                ;;
            *)
                echo "Invalid input. Please enter 1, 2, 3, or 4."
                user_input
                ;;
        esac
}

#  grant access to AWS AMI
account_id=$(aws sts get-caller-identity --query "Account" --output text)
echo "Your AWS account ID is: $account_id"
read -p "Enter your BYUI email address with format {SSSNNNNN@byui.edu} S=letter, N=number:" email
echo "Your email: $email"

display_menu
user_input

curl=$(curl -s -X PUT -H "Content-Type: application/json" -d "{  \"email\": \"$email\",  \"accountId\": \"$account_id\",  \"classId\": \"$course_selection\" }" "https://ooy1dmgurf.execute-api.us-west-2.amazonaws.com/prod")
statusCode=$(echo $curl | jq -r '.statusCode')
if (( $statusCode != 204 )); then
	echo -e "An error occurred granting you permissions to the VM image.\nError: $curl\nContact your TA or instructor with this error for help."
	return 1
fi

echo -e "You have selected $course_selection\nYour VM will now be provisioned in the cloud.  This will take a few minutes.\nPlease DON'T close the window or hit ctrl-c.  You will receive a prompt when complete with instructions."

#  Create a directory for Terraform and change into the directory.  Then install Terraform.account_id=$(aws sts get-caller-identity --query "Account" --output text)
if ! [ -d ~/tf ]; then
	unzip terraform_1.10.3_linux_amd64.zip
	mkdir ~/bin
	mv terraform ~/bin
	mv ./tf/ ~/tf/
	cd ~/tf
	ssh-keygen -t rsa -b 4096 -f "$(pwd)/db_workstation.pem" -m pem -P "" && mv "$(pwd)/db_workstation.pem.pub" "$(pwd)/db_workstation.pub"
	aws secretsmanager create-secret --name MyDBWorkstationSecret --secret-string "$(cat db_workstation.pem)" --region us-west-2
	terraform init
	terraform apply -auto-approve -var "course_selection=$course_selection"
	rm db_workstation.pem
	external_ip=$(terraform output instance_public_ip)
	ip=$(sed -e 's/^"//' -e 's/"$//' <<<"$external_ip")
	echo "Connect to you VM from this link https://$ip:8443/ in your browser."
else
	echo "Terraform is already in the terminal.  The script is exiting to prevent overwriting existing scripts."
	return
fi





