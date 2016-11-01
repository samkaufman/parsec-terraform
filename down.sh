#!/bin/sh
terraform destroy -var-file=~/.tfvars -target=aws_instance.parsec
