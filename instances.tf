# data "aws_ami" "amazon-linux-2" {
#   executable_users = ["self"]
#   owners           = ["self"]
#   most_recent      = true
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm*"]
#   }
#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

resource "aws_instance" "jenkins-master" {
  ami                         = "ami-02d03ce209db75523"
  instance_type               = var.instance-type
  key_name                    = "jenkins"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.vpc_sg.id]
  subnet_id                   = aws_subnet.master_public.id
  provisioner "local-exec" {
    command = <<EOF
    aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region} --instance-ids ${self.id}  && AWS_PROFILE=master ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_playbook/install_jenkins.yaml 
EOF
  }
  tags = {
    Name = "Jenkins_Master"
  }
  depends_on = [aws_route_table_association.master_internet_route, aws_subnet.master_public, aws_security_group.vpc_sg]
}

resource "aws_instance" "jenkins-worker" {
  ami                         = "ami-02d03ce209db75523"
  instance_type               = var.instance-type
  key_name                    = "jenkins"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.vpc_sg.id]
  count                       = var.worker-count
  subnet_id                   = aws_subnet.worker_public.id
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "java -jar /home/ec2-user/jenkins-cli.jar -auth @/home/ec2-user/jenkins_auth -s http://${self.tags.Master_Private_IP}:8080 -auth @/home/ec2-user/jenkins_auth delete-node ${self.private_ip}"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/jenkins.pem")
      host        = self.public_ip
    }
  }
  provisioner "local-exec" {
    command = <<EOF
    aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region} --instance-ids ${self.id} && AWS_PROFILE=master ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name} master_ip=${self.tags.Master_Private_IP}' ansible_playbook/install_worker.yaml 
    EOF
  }

  tags = {
    Name              = join("_", ["Jenkins_Worker", count.index + 1]),
    Master_Private_IP = aws_instance.jenkins-master.private_ip
  }
  depends_on = [aws_route_table_association.worker_internet_route, aws_subnet.worker_public, aws_security_group.vpc_sg]
}