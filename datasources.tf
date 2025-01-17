data "aws_ami" "server_ami" {
  most_recent = true
  #owners      = ["125523088429"]
  owners = ["137112412989"]

  filter {
    name = "name"
    #values = ["Fedora-Cloud-Base-38-*.x86_64-hvm-us-west-1-gp3-0"]
    values = ["al2023-ami-*-kernel-*-arm64"]    
  }
}
