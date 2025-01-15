#!/bin/bash

#  An automation script to provision AWS EC2 instance into sandbox account.  This will get your AWS account ID and then request access to the DB AMI.  Then it will run a Terraform script to provision an EC2 instance.

course_selection=-1
PASSWORD=itmpassword123
#menu for selecting class to provision VM
display_menu () {
    echo -e "Please select the class you are creating a virtual machine for:\n1. ITM111\n2. ITM220\n3. ITM325\n4. DEFAULT\n"
}

#get user input of the selection of a class
user_input () {

  course_selection=$(whiptail --title "Database Class Selector" --menu "Choose your class" 15 50 5 "1" "ITM111" "2" "ITM220" "3" "ITM325" "4" "Default" 3>&1 1>&2 2>&3)
#    read -p "Choose your class by entering [1-4] for the class selection: " course_selection

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

#function to get new user password
set_newpassword () {
  read -ps "Please enter a new password to be used by your student user on your VM: " PASSWORD
  read -ps "Confirm new password: " CPASSWORD

  if [[ "$PASSWORD" != "$CPASSWORD" ]]; then
    echo "Passwords do not match try again."
    set_newpassword
  fi
}

get_byui_email () {

email=$(whiptail --inputbox "Enter your BYUI email address with format {SSSNNNNN@byui.edu} S=letter, N=number:" 8 39 @byui.edu --title "Enter BYUI email" 3>&1 1>&2 2>&3)
#  read -p "Enter your BYUI email address with format {SSSNNNNN@byui.edu} S=letter, N=number:" email
  echo "Your email: $email"


}

vm_startup_countdown () {
    {
      for ((i = 0 ; i <= 150 ; i+=1)); do
      sleep 1.0;
      echo $i;
      done;
    } | whiptail --gauge "Please wait while virtual machine is starting..." 6 50 0
}

#  grant access to AWS AMI
sudo dnf install -y newt
account_id=$(aws sts get-caller-identity --query "Account" --output text)
echo "Your AWS account ID is: $account_id"
get_byui_email

display_menu
user_input
#set_newpassword

curl=$(curl -s -X PUT -H "Content-Type: application/json" -d "{  \"email\": \"$email\",  \"accountId\": \"$account_id\",  \"classId\": \"$(( course_selection - 1 ))\" }" "https://ooy1dmgurf.execute-api.us-west-2.amazonaws.com/prod")
statusCode=$(echo $curl | jq -r '.statusCode')
if (( $statusCode != 204 )); then
	echo -e "An error occurred granting you permissions to the VM image.\nError: $curl\nContact your TA or instructor with this error for help."
	return 1
fi



#  Create a directory for Terraform and change into the directory.  Then install Terraform.account_id=$(aws sts get-caller-identity --query "Account" --output text)
if ! [ -d ~/tf ]; then
	unzip terraform_1.10.3_linux_amd64.zip
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
	NEWPASSWORD="echo -e \"$PASSWORD\n$PASSWORD\" | sudo passwd student"
  chmod 400 db_workstation.pem

    #sleep for 2.5 minutes while new VM starts
  vm_startup_countdown

#  echo -n "Waiting for new VM to start. Countdown in seconds..."
#  for i in {1..150}; do
#    echo -ne ".$((150 - i))"
#    sleep 1
#  done
  echo -e "\n\nYou will be prompted to enter a new password for your student user.\nUse a strong password and remember this password as you will need it each time you connect. "
  ssh -i db_workstation.pem -o "StrictHostKeyChecking no" -t student@$ip "sudo passwd student && rm ~/.local/share/keyrings/login.keyring"
	rm -f db_workstation.pem

	echo "Connect to you VM from this link https://$ip:8443/ in your browser."
else
	echo "Terraform is already in the terminal.  The script is exiting to prevent overwriting existing scripts."
	return
fi