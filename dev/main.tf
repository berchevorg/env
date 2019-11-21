terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "berchevorg"

    workspaces {
      name = "env-dev"
    }
  }
}

data "template_file" "init" {
  template = file("template.tpl")
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "server" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name 
  associate_public_ip_address = "true"
}

resource "null_resource" "add_file_content" {
  connection {
    host = aws_instance.server.public_ip
  }

  provisioner "file" {
    content     = data.template_file.init.rendered
    destination = "/tmp/script.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/Dropbox/ec2_key_pair/berchev_key_pair.pem")
    }
  }
}

resource "null_resource" "execute_script" {
  depends_on = [null_resource.add_file_content]

  connection {
    host = aws_instance.server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "cd /tmp",
      "./script.sh",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/Dropbox/ec2_key_pair/berchev_key_pair.pem")
    }
  }
}

output "ip" {
  value = aws_instance.server.public_ip
}

