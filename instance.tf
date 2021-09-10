#get the data fro the global vars WS
data "terraform_remote_state" "global" {
  backend = "remote"
  config = {
    organization = var.org
    workspaces = {
      name = var.globalwsname
    }
  }
}

#get the db serer name
data "terraform_remote_state" "dbvm" {
  backend = "remote"
  config = {
    organization = var.org
    workspaces = {
      name = var.dbvmwsname
    }
  }
}

data "terraform_remote_state" "appvm" {
  backend = "remote"
  config = {
    organization = var.org
    workspaces = {
      name = var.appvmwsname
    }
  }
}

variable "org" {
  type = string
}
variable "dbvmwsname" {
  type = string
}

variable "globalwsname" {
  type = string
}

variable "appvmwsname" {
  type = string
}

resource "null_resource" "vm_node_init" {

  provisioner "file" {
    source = "scripts/"
    destination = "/tmp"
    connection {
      type = "ssh"
      host = "${local.appvmip}"
      user = "root"
      password = "${local.root_password}"
      port = "22"
      agent = false
    }
  }
  provisioner "file" {
    source = "appwars/"
    destination = "/tmp"
    connection {
      type = "ssh"
      host = "${local.appvmip}" 
      user = "root"
      password = "${local.root_password}"
      port = "22"
      agent = false
    }
  }

  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/tominstance.sh",
    ]
    connection {
      type = "ssh"
      host = "${local.appvmip}" 
      user = "root"
      password = "${local.root_password}"
      port = "22"
      agent = false
    }
  }

  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/startsvc.sh",
    ]
    connection {
      type = "ssh"
      host = "${local.appvmip}" 
      user = "root"
      password = "${local.root_password}"
      port = "22"
      agent = false
    }
  }

  provisioner "remote-exec" {
    inline = [<<EOT
        %{ for app in local.appwars ~} 
            /tmp/tominstance.sh ${app.svcname} ${app.svcport} ${app.svrport} ${app.appwar} ${local.dbvmip}
        %{ endfor ~} 
    EOT
    ]
    connection {
      type = "ssh"
      host = "${local.appvmip}" 
      user = "root"
      password = "${local.root_password}"
      port = "22"
      agent = false
    }
  }

  provisioner "remote-exec" {
    inline = [<<EOT
        %{ for app in local.appwars ~}
            /tmp/startsvc.sh ${app.svcname} ${app.svcport} ${app.svrport} ${app.appwar} ${local.dbvmip}
        %{ endfor ~}
    EOT
    ]
    connection {
      type = "ssh"
      host = "${local.appvmip}" 
      user = "root"
      password = "${local.root_password}"
      port = "22"
      agent = false
    }
  }


}


locals {
  appwars = data.terraform_remote_state.global.outputs.apps
  dbvmip = data.terraform_remote_state.dbvm.outputs.vm_ip[0]
  root_password = yamldecode(data.terraform_remote_state.global.outputs.root_password)
  appvmip = data.terraform_remote_state.appvm.outputs.vm_ip[0]
}

