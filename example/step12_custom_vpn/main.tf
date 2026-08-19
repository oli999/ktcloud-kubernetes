# main.tf

# terraform_example/test01/main.tf

# version 명시하기 
terraform {
  required_version = "~>1.14.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
  }
}

# 1. provider 설정
provider "aws" {
    region = "ap-northeast-1" # 도쿄 리전 
}

# 2. vpc 및 네트워크 생성 (인프라의 기초 공사)

# vpc
resource "aws_vpc" "main" {
    cidr_block              = "10.0.0.0/16"
    enable_dns_hostnames    = true
    tags                    = { Name = "lecture-vpc" }
}

# 인터넷 게이트 웨이
resource "aws_internet_gateway" "igw" {
    # 위에서 만들어진 vpc 의 아이디를 참조 하도록 한다.
    vpc_id  = aws_vpc.main.id
    tags    = { Name = "lecture-igw"}
}

# 현재 리전에서 사용가능한(avaliable) 가용 영역 데이터 가져오기
data "aws_availability_zones" "available"{
    state = "available"
}

# public subnet
resource "aws_subnet" "public_subnet" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.1.0/24" # 256 개의 ip 를 이방에 할당 
    
    # data.aws_availability_zones.available.names 는 배열인데 거기에는 여러개의 가용영역 데이터가 들어있다.
    # 그중에서 0 번 방에 있는 데이터를 연결한다 
    availability_zone = data.aws_availability_zones.available.names[0]

    map_public_ip_on_launch = true # 이방에 생기는 서버는 무조건 공인 ip 를 받는다.
    tags = { 
        Name = "lecture-subnet" 
    }
}


# 라우팅 테이블 : 트레픽 이정표 
resource "aws_route_table" "public_rt" {
    # 어떤 vpc 의 소속인지 설정 
    vpc_id = aws_vpc.main.id
    # 라우팅 규칙 (0.0.0.0/0) 으로 가는 트레픽은 인터넷 게이트(igw) 웨이로 보내라
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

# public subnet 을 위의 라우팅 테이블로 연결
resource  "aws_route_table_association" "a" {
    subnet_id       = aws_subnet.public_subnet.id # 우리가 만든 퍼블릭 서브넷은
    route_table_id  = aws_route_table.public_rt.id # 위에서 만든 라우팅 테이블로 연결 
}

# pem 파일 관련 작업

# 알고리즘 결정
resource "tls_private_key" "pk" {
    algorithm = "RSA"
    rsa_bits  = 4096
}
# 키등록
resource "aws_key_pair" "kp" {
    key_name   = "lecture-key"
    public_key = tls_private_key.pk.public_key_openssh
}

# 개인키를 가져오기
# "local_file" resource 를 이용하면 파일을 생성할수 있다.
resource "local_file" "ssh_key" {
    # ${path.module} 은 현재 실행경로를 의미한다. 
    filename        = "${path.module}/lecture-key.pem"
    content         = tls_private_key.pk.private_key_pem
    file_permission = "0600" # 파일의 권한 설정 
}

# 보안그룹
resource "aws_security_group" "ssh_sg" {
    # 보안 그룹의 이름은 겹치지 않게 유일하게 식별되는 이름을 지어야 한다.
    name = "allow-ssh"
    vpc_id = aws_vpc.main.id

    # 밖에서 안으로 들어오는 규칙  ingress 
    ingress {
        from_port   = 22            # 시작 port
        to_port     = 22            # 끝 port
        protocol    = "tcp"         # protocol
        cidr_blocks = ["0.0.0.0/0"] # 외부에서 들어오는 모든 traffic (실무에서는 나의 ip 만)
    }
    # 안에서 밖으로 나가는 규칙  egress
    egress {
        from_port   = 0             # 0번부터 
        to_port     = 0             # 0번까지 (모든 포트)
        protocol    = "-1"          # 모든 프로토콜 
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# ec2 에 설치할 amazon linux 최신 이미지 검색
data "aws_ami" "latest_al2023" {
    most_recent   = true
    owners        = ["amazon"]
    filter {
        name    = "name"
        values  = ["al2023-ami-*-x86_64"]  # 이름이 이렇게 시작하는 것들 중에서 최신 이미지 검색 
    }
}

# ec2 만들기
resource "aws_instance" "my_ec2" {
    ami                     = data.aws_ami.latest_al2023.id     # 검색된 최신의 os 이미지 id
    instance_type           = "t3.micro"                        # 서버사양
    subnet_id               = aws_subnet.public_subnet.id       # 위에서 미리 준비한 public subnet 의 id
    vpc_security_group_ids  = [aws_security_group.ssh_sg.id]       # 보안그룹 (여러개 등록할수 있다) 
    key_name                = aws_key_pair.kp.key_name          # 위에서 미리 준비한 key pair 의 이름 
    tags = {
        Name = "my-ec2"
    }
}


# 생성된 EC2의 퍼블릭 IP 주소 출력
output "ec2_public_ip" {
    description = "EC2 인스턴스의 퍼블릭 IP 주소"
    value       = aws_instance.my_ec2.public_ip
}










