# db-workstation-automation

This repo contains the scripts and Terraform binaries to provision a new DB Virtual machine for class usage.  You should be able to run 'git clone https://github.com/byui-bwh/db-workstation-automation.git' from your AWS Console's Cloud Shell terminal.  This will pull the code locally.  

Then do a 'cd db-workstation-automation' to change into the directory.  Then source the script by running '. ./provision_vm.sh'  The script will prompt you for your email.  Please use your university email for the authentication of the VM.  The script will automate the creation of a new virtual machine instance for you with the settings required for the class.

Upon completion of the script, the output will display a URL for you to copy into your browser.  Please use this URL to connect to your instance as described in the documentation.