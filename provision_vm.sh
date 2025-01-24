#!/bin/bash

#  An automation script to provision AWS EC2 instance into sandbox account.  This will get your AWS account ID and then request access to the DB AMI.  Then it will run a Terraform script to provision an EC2 instance.
# initialize course selection variable
course_selection=-1

#get user input of the selection of a class
user_input () {
  course_selection=$(whiptail --title "Class Selector" --menu "Choose the class you will be using the VM for" 15 50 5 "1" "ITM111" "2" "ITM220" "3" "ITM325" "4" "ITM350" 3>&1 1>&2 2>&3)

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
                echo "You have selected ITM350 for the VM."
                ;;
            *)
                echo "Invalid input. Please enter 1, 2, 3, or 4."
                user_input
                ;;
        esac
}

#function to get user's byui.edu email
get_byui_email () {
  email=$(whiptail --inputbox "Enter your BYUI email address with format {SSSNNNNN@byui.edu} S=letter, N=number:" 8 39 --title "Enter BYUI email" 3>&1 1>&2 2>&3)
  echo "Your email: $email"
}

vm_startup_countdown () {
    {
      for ((i = 0 ; i <= 200 ; i+=1)); do
      sleep 1.0;
      printf '%.*f\n' 0 $(bc -l <<< "$i/200 * 100");
      done;
    } | whiptail --gauge "Please wait while virtual machine is starting..." 6 60 0
}

#  grant access to AWS AMI
sudo dnf install -y newt
sudo dnf install -y bc
account_id=$(aws sts get-caller-identity --query "Account" --output text)
echo "Your AWS account ID is: $account_id"
get_byui_email
display_menu
user_input

curl=$(curl -s -X PUT -H "Content-Type: application/json" -d "{  \"email\": \"$email\",  \"accountId\": \"$account_id\",  \"classId\": \"$(( course_selection - 1 ))\" }" "https://ooy1dmgurf.execute-api.us-west-2.amazonaws.com/prod")
statusCode=$(echo $curl | jq -r '.statusCode')
if (( $statusCode != 204 )); then
	echo -e "An error occurred granting you permissions to the VM image.\nError: $curl\nContact your TA or instructor with this error for help."
	return 1
fi



#  Create a directory for Terraform and change into the directory.  Then install Terraform.account_id=$(aws sts get-caller-identity --query "Account" --output text)
if ! [ -d ~/tf ]; then
	unzip terraform_1.10.4_linux_amd64.zip
	mkdir ~/.local/bin
	mv terraform ~/.local/bin
	mv ./tf/ ~/tf/
	cd ~/tf
	ssh-keygen -t rsa -b 4096 -f "$(pwd)/db_workstation.pem" -m pem -P "" && mv "$(pwd)/db_workstation.pem.pub" "$(pwd)/db_workstation.pub"
	aws secretsmanager create-secret --name MyDBWorkstationSecret-$( date '+%Y-%m-%d-%s' ) --secret-string "$(cat db_workstation.pem)" --region us-west-2
	terraform init
	echo "-var course_selection=$course_selection"
  	echo -e "You have selected $course_selection\n\nYour VM will now be provisioned in the cloud.\n\nThis will take a few minutes.\n\nPlease DON'T close the window or hit ctrl-c.  You will receive a prompt when complete with instructions."
	terraform apply -auto-approve -var "course_selection=$(( course_selection - 1))"
	external_ip=$(terraform output instance_public_ip)
  ip=$(sed -e 's/^"//' -e 's/"$//' <<<"$external_ip")
	chmod 400 db_workstation.pem

    #sleep for 2.5 minutes while new VM starts
  vm_startup_countdown

  echo -e "\n\nYou will be prompted to enter a new password for your student user.\nUse a strong password and remember this password as you will need it each time you connect.\n\nNote, you will not see of the characters or anything at the cursor as you type your password. "
  ssh -i db_workstation.pem -o "StrictHostKeyChecking no" -t student@$ip "sudo passwd student && rm ~/.local/share/keyrings/login.keyring"
	rm -f db_workstation.pem

	echo "Connect to you VM from this link https://$ip:8443/ in your browser."
else
	echo "Terraform is already in the terminal.  The script is exiting to prevent overwriting existing scripts."
	return
fi
