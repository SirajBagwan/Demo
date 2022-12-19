terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.38.0"
    }
  }
}

provider "aws" {
  # Configuration options
	region = "ap-south-1"
}

# Adding VPC

resource "aws_vpc" "test" {
  cidr_block       = "10.0.0.0/24"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "Test"
  }
}

# Adding subnets to VPC
resource "aws_subnet" "publicA" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.0.0/28"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "publicA"
  }
}


resource "aws_subnet" "publicB" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.0.16/28"
  availability_zone =  "ap-south-1b"


  tags = {
    Name = "publicB"
  }
}

resource "aws_subnet" "privateA" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.0.32/28"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "privateA"

  }
}


resource "aws_subnet" "privateB" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.0.48/28"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "privateB"
  }
}

# Adding internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test.id
  

  tags = {
    Name = "igw"
  }
}

# Adding Route Tables
resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }


  tags = {
    Name = "publicRT"
  }
}







# RT Association
resource "aws_route_table_association" "RTApublicA" {
  subnet_id      = aws_subnet.publicA.id
  route_table_id = aws_route_table.publicRT.id
}

resource "aws_route_table_association" "RTApublicB" {
  subnet_id      = aws_subnet.publicB.id
  route_table_id = aws_route_table.publicRT.id
}

# VPC S3_Endpoint
resource "aws_vpc_endpoint" "s3" {

  vpc_id       = aws_vpc.test.id
  service_name = "com.amazonaws.ap-south-1.s3"
} 

# RT for S3 Endpoint association
resource "aws_vpc_endpoint_route_table_association" "RTpublicENDA" {
  route_table_id  = aws_route_table.publicRT.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}




# Security group
resource "aws_security_group" "Firewall" {
  name        = "Firewall"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.test.id

  ingress {
    description      = "from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.test.cidr_block]
  }

ingress {
    description      = "all traffic from my ip"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["103.93.196.74/32"]
  }
ingress {
    description      = "rdp traffic"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["103.93.196.74/32"]
  }



  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Firewall"
  }
}



#launch instance
#Web server Provisioning
resource "aws_instance" "web" {
  ami                         = "ami-07560b8c00bfb9d95"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.publicA.id
  vpc_security_group_ids      =[aws_security_group.Firewall.id]
  key_name                    = "raw"
  
   
  tags = {
    Name = "Web Server"
  }
}






#cm provisioning
resource "aws_spot_instance_request" "cm" {
  ami                            = "ami-02607ba8880c51aa1"
  count                          = 1
  spot_price                     = "0.067"
  instance_type                  = "m5.xlarge"
  spot_type                      = "persistent"
  associate_public_ip_address    = true
  subnet_id                      = aws_subnet.publicA.id
  vpc_security_group_ids         = [aws_security_group.Firewall.id]
  key_name                       = "raw"
  iam_instance_profile           = "S3AccessRoleToEc2Instance"
  instance_interruption_behavior = "stop"


  tags = {
    Name = "cm"
  }
}



/*
resource "aws_spot_instance_request" "Pre_Req" {
  ami                            = "ami-02607ba8880c51aa1"
  count                          = 5
  spot_price                     = "0.067"
  instance_type                  = "m5.xlarge"
  spot_type                      = "persistent"
  associate_public_ip_address    = true
  subnet_id                      = aws_subnet.publicA.id
  vpc_security_group_ids         = [aws_security_group.Firewall.id]
  key_name                       = "raw"
  iam_instance_profile           = "S3AccessRoleToEc2Instance"
  instance_interruption_behavior = "stop"
  


  tags = {
    Name = "prod"
  }
}




#subnet group for rds
resource "aws_db_subnet_group" "dbpubsub" {
  name       = "main"
  subnet_ids = [aws_subnet.publicA.id,aws_subnet.publicB.id]

  tags = {
    Name = "My DB subnet group"
  }
}






# AWS RDS database provisioning
resource "aws_db_instance" "mysql" {
  allocated_storage      = 10
  db_name                = "datse"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "admin123"
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = "main"
  vpc_security_group_ids = [aws_security_group.Firewall.id]
  port                   = "3306"
  identifier             = "database"

}

*/