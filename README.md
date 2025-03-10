# SRE/DevOps Interview Exercise

This challenge is designed to assess your troubleshooting, debugging, and problem‐solving skills across both infrastructure-as-code and application layers.

## Objective

You are provided with three files:
- **Terraform Configuration:** This file provisions an AWS EC2 instance along with an Application Load Balancer (ALB) and related security groups.
- **Flask Application:** A simple web server running on the provisioned instance.
- **Python Connectivity Script:** A script that attempts to connect to the ALB endpoint.

**Note:** Currently, the Python connectivity script does not successfully connect to the ALB. Your task is to analyze both the configuration and the application code to identify what might be causing this connectivity failure, and then propose and explain your actions.

## Guidelines

- **Time Limit:** Aim to complete your review and propose corrective actions within 10 minutes.
- **Process:** As you work through the exercise, please explain your thought process out loud. We are very interested in how you approach troubleshooting and problem resolution.
- **Discussion:** Be prepared to walk us through your findings and recommendations during the discussion.

Good luck!

Problem Statement ends here.

<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>


# SRE/DevOps Interview Exercise - My Solution

This document outlines the issues I encountered with the provided Terraform configuration, Flask application, and Python connectivity script, along with the solutions I implemented.  I'll also discuss further enhancements and potential future scope.

## Initial Problem Analysis

The primary issue was the Python connectivity script's inability to connect to the ALB endpoint. My troubleshooting process started with a thorough review of the Flask application code to ensure the application itself was functioning correctly and listening on the expected port. I then examined the Terraform configuration, paying close attention to the security group rules and load balancer configuration. Finally, I analyzed the Python connectivity script to verify its accuracy and target endpoint.


## Identified Issues

1.  **Missing Health Check Endpoint:** The Flask application lacked a `/health` route.  This prevented the ALB's target group health checks from functioning correctly, which would ultimately prevent the EC2 instance from being added to the target group.

2.  **Incorrect Security Group Configuration:** The security group only allowed traffic on port 80, but the Flask application was exposed on port 5000. This mismatch would block communication with the instance.

3.  **Application Deployment:** There was no mechanism to deploy the `app.py` file to the EC2 instance and run it.

4.  **Security Group Misconfiguration:** Both the load balancer and the EC2 instance were using the *same* security group. This is a security risk. The load balancer's security group unnecessarily had port 5000 open to the internet, and the EC2 instance's security group had port 80 open, exposing it unnecessarily.

5.  **EC2 Instance in Public Subnet:** The EC2 instance was placed in a public subnet, which is another security concern.

6.  **Hardcoded Values:** The Terraform configuration contained many hardcoded values, making it less flexible and reusable.

## Solutions Implemented

1.  **Health Check Endpoint:** I added a `/health` route to the Flask application that returns a 200 status code. This allows the ALB's target group to perform health checks.
```python
@app.route("/health")
def healthcheck():
    return "", 200
```

2.  **Security Group Rule for Port 5000:** I added an ingress rule to the security group to allow traffic on port 5000.  Initially, I added the rule to the same security group.

3.  **Application Deployment Script:** I created a `script.sh` that downloads the `app.py` file from a GitHub repository, installs the necessary Python dependencies (Flask), and then runs the Flask application in the background using `nohup`.
```bash
#!/bin/bash

apt update -y && apt upgrade -y                                                           #makes the OS up-to-date

wget https://raw.githubusercontent.com/coooolk/datalogz-test/refs/heads/master/app.py     #download app.py

apt install -y python3 python3-pip python3-venv                                           #install venv

python3 -m venv .venv                                                                     #create a venv
source .venv/bin/activate                                                                 #activat the venv

pip install Flask                                                                         #install flask

nohup python3 app.py > flask.log 2>&1 &                                                   #run app.py in bg using nohup comamnd

echo "Flask app started in the background."
```

4.  **User Data Deployment:** I used the `user_data` feature in the `aws_instance` resource to deploy the `script.sh` to the EC2 instance during provisioning.

5. **Security Group Association with ALB:** I associated the web_sg security group with the Application Load Balancer as well.  This allowed the ALB to receive traffic on port 80 (which was already allowed by the security group's ingress rules) and then forward it to the EC2 instance on port 5000.

After implementing these initial fixes, the application started to function.
<br/>
<br/>
Here's the initial architecture(before enhancements):
<img width="1449" alt="datalogz test architecture before enhancements" src="https://github.com/user-attachments/assets/614a6a42-d6f8-430b-b487-a0177da407f2" />
<br/>
<br/>

## Further Enhancements

To improve the architecture and security, I made the following enhancements:

1. **VPC with Public and Private Subnets:** I created a VPC with both public and private subnets. 
-  _**Why:**_ This separation enhances security. Public subnets are used for resources that need to be accessible from the internet (like the load balancer), while private subnets are used for resources that should not be directly exposed to the internet (like the EC2 instance). This isolates the application server and reduces the attack surface.

2.  **Separate Security Groups:** I created two separate security groups: one for the load balancer (`lb_sg`) and one for the EC2 instance (`web_sg`). 
-  _**Why:**_ This is crucial for security and proper traffic flow. The load balancer's security group allows traffic on port 80 from the internet, while the EC2 instance's security group _only_ allows traffic on port 5000. This prevents direct access to the EC2 instance from the internet and ensures that all traffic goes through the load balancer. It also simplifies security management by clearly defining the allowed traffic for each component.

3.  **Private EC2 Instance:** I disabled the option to assign a public IP address to the EC2 instance and placed it in a private subnet. This makes the instance only accessible through the load balancer.
-  _**Why:**_ This significantly improves security. By removing the public IP address, the EC2 instance is no longer directly reachable from the internet. Communication with the instance is now only possible through the load balancer, which acts as a single point of entry and control.

4.  **Public Load Balancer:** The load balancer was placed in the public subnets, making it internet-facing.
-  _**Why:**_ The load balancer _must_ be in public subnets to receive incoming traffic from the internet. It acts as the entry point for all requests to the application.

5.  **NAT Gateway for Private Subnet:** Because the EC2 instance was now in a private subnet and needed internet access for installing dependencies, I created a NAT gateway and associated it with the private subnet.
- _**Why:**_ The EC2 instance, now in a private subnet, still needs access to the internet to download the application code (`app.py`) from GitHub and install its dependencies (Flask). A NAT gateway allows instances in private subnets to initiate outbound connections to the internet (e.g., for updates, package installations) without exposing them to inbound connections from the internet. This maintains the security of the private subnet while allowing necessary internet access.

6.  **`depends_on` for NAT Gateway:** I added `depends_on = [ module.vpc.enable_nat_gateway ]` to the `aws_instance` resource to ensure that the NAT gateway is fully provisioned *before* the EC2 instance is started. This prevents issues with the instance trying to connect to the internet before the NAT gateway is available.

7.  **Terraform Best Practices:** I refactored the Terraform code to use variables for greater flexibility and organized the configuration into separate files for better maintainability.
-  _**Why:**_ Using variables makes the Terraform code more flexible and reusable. It allows you to easily change values (like instance type, AMI ID, etc.) without modifying the core configuration. Separating the configuration into multiple files improves readability and maintainability.

8.  **Output Variables:** I used Terraform outputs to display relevant information (like the load balancer's DNS name and the instance's private IP) directly in the terminal, simplifying access and verification.
-  _**Why:**_ Outputs make it easy to retrieve important information about the deployed infrastructure. This simplifies access and verification without having to manually navigate the AWS console.
<br/>
<br/>
And here's the final architecture after enhancements:
<img width="1449" alt="datalogz test architecture after enhancements" src="https://github.com/user-attachments/assets/d9e418de-8bd5-460a-941b-85c56264643e" />
<br/>
<br/>

## Future Scope

The following are potential future enhancements:

1.  **CI/CD Pipeline:** Implementing a CI/CD pipeline to automate the build, test, and deployment process.

2.  **Auto Scaling Group:** Implementing auto scaling to dynamically adjust the number of EC2 instances based on traffic demand.

3.  **Containerization:** Containerizing the application using Docker for improved portability and consistency.

4.  **Kubernetes:** If the application grows to include multiple microservices, migrating to Kubernetes for better orchestration and management.

