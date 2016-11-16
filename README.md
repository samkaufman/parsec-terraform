# parsec-terraform
A Terraform template to spin up a Parsec server in AWS.

Only tested on macOS.

## How to use this
1. Clone this repo.
2. [Install Terraform.](https://www.terraform.io/intro/getting-started/install.html)
3. Create a `~/.tfvars` file that looks like the template below with your vars
   substituted.
4. Either add or remove references to System32/XInput9_1_0.dll,
   Redist/vcredist_x64.exe, and Redist/vcredist_x86.exe  .
5. Run `./up.sh` to build and boot a server.
6. Run `./down.sh` when done. (Thought if CPU is low, the instance will
   self-terminate.)

It's worthwhile, on boot, to restart Windows Explorer so it picks up on the
Registry hackery which points Desktop, Documents, Saved Games, etc. to the
persistent EBS volume mounted at D:.

## .tfvars
```
parsec_authcode = "YOUR_PARSEC_AUTHCODE"
aws_access_key = "YOUR_AWS_ACCESS_KEY_ID"
aws_secret = "YOUR_AWS_SECRET_ACCESS_KEY"
aws_region = "YOUR_AWS_REGION"
```
