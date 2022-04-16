provider "aws" {
  profile = "personal"
  region = "ap-south-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0851b76e8b1bce90b"
  instance_type = "t2.micro"

  tags = {
      Name = "terraform-example"
  }
}

