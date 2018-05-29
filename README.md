# Custom VPC network for deploying cp
The following instructions assumes you already have an AWS account. If you don't have, then sign up for one from here https://aws.amazon.com/

#### Creating VPC
* Once you have logged in your account, from the service list under Networking and content delivery, select VPC
* On the VPC console dash board, select ```Your VPCs``` and click on create VPC
* Fill in the details giving it a name, choosing the CIDR block e.g 10.0.0.0/16 and leave the rest as it is
* click ``` Yes, Create```

#### Creating Public and Private Subnets
* Select Subnets from the VPC dashboard list
* Click on ```Create Subnet``` button
* Give it a name ```pub-sub```, select the VPC you have created from the list, select the zone your are in and choose a CIDR block e.g. 10.0.1.0/24
* Click ```Yes, Create```
* Repeat the above step to create the second subnet with a name ```priv-sub``` and CIDR block e.g 10.0.2.0/24

#### Creating Route Tables
* Select Route Tables from the VPC dashboard list
* Click on ```Create Route Table``` button
* Give it a name ```pub-route```
* Select your VPC
* Repeat the above steps to create the second with a name ```priv-route```

#### Creating Internet Gateway
* Select Internet Gateways from the VPC dashboard list
* Click ```Create internet gateway``` button
* Give it a name ``` vpc-igw```
* While Selected click ```Actions``` button and select ```Attach to VPC``` 
* Select your VPC and save

#### Associating Subnet with Route Tables
* From the Route tables list, select your pub-route 
* Select Routes tab and click on ```Edit``` then ```Add another route```
* Enter ```0.0.0.0/0``` for the Destination while click in the target field and select your ```vpc-igw``` and save. This makes this subnet a public subnet
* Select ```subnet Associations``` and Edit
* Check the box next to your ```pub-sub``` and save
* Select the priv-route, subnet Associations and choose the ```priv-sub``` then save

#### Security groups
* Select security groups from the VPC dashboard list
* Create security group
* Create 2 groups with names pub-sg and priv-sg and select you vpc.
* Select the pub-sg and in the inbound rules tab, add HTTP and HTTPS with sources 0.0.0.0/0, SSH from your IP/32 and save
* Repeat for priv-sg with HTTP/HTTPS sources pub-sg and save
* Create a nat-sg for our nat instance with sources of your priv-sub CIDR

#### Creating NAT instance
This will help us SSH in to our private instances and connect them to the internet for updates and accessing deployment scripts on github
* From EC2 create an instance from community AMIs   by searching for amis having ```amzn-ami-vpc-nat``` in their names and select the first in the list
* Give it your vpc, pub-sub and nat-sg
* Select the nat instance you have created, click on Actions, select Networking and then Change Source/Dest Check and click Yes Disable
* Select priv-route, select Route tab, click Edit and then add route. enter 0.0.0.0/0 in the destination and click and select the nat instance in the target field

#### Creating Instances
With the network ready setup, its time to create our instances in the public and private subnets respectively
* From the EC2 console
* Click Launch Instance
* Select ```Ubuntu Server 16.04 LTS (HVM), SSD Volume Type```
* Select your VPC, pub-sg and enable public IP for the public while VPC, priv-sg and diable public IP for the private
* Launch with an existing key or new key

#### Creating RDS Postgress instance
* From AWS RDS console, slect the instance link
* Click Launch DB Instance and choose PostgreSQL
* Follow the wizard to complete the setup filling in the required parameters like your VPC and the username, password and database name

#### SSH connections to public instance
* Select the public instance and click on connect
* Copy the ssh connection string
* Open your terminal and then connect to your instance using the key you have downloaded for the instance
* Once in, git clone this repo cd in the VPC dir and run ```source react.sh``` to install the front react app

#### SSH connections to private instance
* Select the nat instance and click on connect
* Copy ssh connection string
* From your terminal connect to your nat instance
* Once in, create a new .pem file and copy the content of the key for the private instance in it
* Copy the connection string of the private instance and ssh into it from the nat instance
* Once in, git clone this repo cd in the VPC dir and run ```source api.sh``` to install the api app
* After the installation, copy your RDS endpoint and export the database url using the environment variable DATABASE_URL e.g ```export DATABASE_URL="postgres://username:password@RDS-Endpoint:5432/database-name``` replacing username, password, RDS-Endpoint and database-name with yours values respectively





