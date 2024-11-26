#!/bin/bash

#  An automation script to provision AWS EC2 instance into sandbox account.  This will get your AWS account ID and then request access to the DB AMI.  Then it will run a Terraform script to provision an EC2 instance.

#  grant access to AWS AMI
account_id=$(aws sts get-caller-identity --query "Account" --output text)
echo "Your AWS account ID is: $account_id"
read -p "Enter your BYUI email address with format {SSSNNNNN@byui.edu} S=letter, N=number:" email
echo "Your email: $email"
curl=$(curl -s -X PUT -H "Content-Type: application/json" -d "{  \"email\": \"$email\",  \"accountId\": \"$account_id\" }" "https://ooy1dmgurf.execute-api.us-west-2.amazonaws.com/prod")
statusCode=$(echo $curl | jq -r '.statusCode')
if (( $statusCode != 204 )); then
	echo -e "An error occurred granting you permissions to the VM image.  Error: $curl\nContact your TA or instructor with this error for help."
fi

#  Create a directory for Terraform and change into the directory.  Then install Terraform.account_id=$(aws sts get-caller-identity --query "Account" --output text)
if ! [ -d ~/tf ]; then
	unzip terraform_1.9.8_linux_amd64.zip
	mkdir ~/bin
	mv terraform ~/bin
	mv ./tf/ ~/tf/
	cd ~/tf
	ssh-keygen -t rsa -b 4096 -f "$(pwd)/db_workstation.pem" -m pem -P "" && mv "$(pwd)/db_workstation.pem.pub" "$(pwd)/db_workstation.pub"
	aws secretsmanager create-secret --name MyDBWorkstationSecret --secret-string "$(cat db_workstation.pem)"
	rm db_workstation.p*
	terraform init
	terraform apply -auto-approve
	external_ip=$(terraform output instance_public_ip)
	ip=$(sed -e 's/^"//' -e 's/"$//' <<<"$external_ip")
	echo "Connect to you VM from this link https://$ip:8443/ in your browser."
else
	echo "Terraform is already in the terminal.  The script is exiting to prevent overwriting existing scripts."
	return
fi



