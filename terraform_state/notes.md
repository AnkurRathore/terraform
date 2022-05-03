## What is Terraform State
Every time you run Terraform, it records information about what infrastructure it created in a Terraform state file. By default, when you run Terraform in the folder /foo/bar, Terraform creates the file /foo/bar/terraform.tfstate. This file contains a custom JSON format that records a mapping from the Terraform resources in your configuration files to the representation of those resources in the real world. For example, let’s say your Terraform configuration contained the following:

```
resource "aws_instance" "example" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
}
```

After running terraform apply, here is a small snippet of the contents of the terraform.tfstate file (truncated for readability):

```
{
  "version": 4,
  "terraform_version": "1.1.4",
  "serial": 1,
  "lineage": "86545604-7463-4aa5-e9e8-a2a221de98d2",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "example",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "ami": "ami-0fb653ca2d3203ac1",
            "availability_zone": "us-east-2b",
            "id": "i-0bc4bbe5b84387543",
            "instance_state": "running",
            "instance_type": "t2.micro",
            "(...)": "(truncated)"
          }
        }
      ]
    }
  ]
}
```

Using this JSON format, Terraform knows that a resource with type aws_instance and name example corresponds to an EC2 Instance in your AWS account with ID i-0bc4bbe5b84387543. Every time you run Terraform, it can fetch the latest status of this EC2 Instance from AWS and compare that to what’s in your Terraform configurations to determine what changes need to be applied. In other words, the output of the plan command is a diff between the code on your computer and the infrastructure deployed in the real world, as discovered via IDs in the state file.

**The State File Is a Private API

The state file format is a private API that is meant only for internal use within Terraform. You should never edit the Terraform state files by hand or write code that reads them directly.**

If you’re using Terraform for a personal project, storing state in a single terraform.tfstate file that lives locally on your computer works just fine. But if you want to use Terraform as a team on a real product, you run into several problems:

1. Shared storage for state files

    To be able to use Terraform to update your infrastructure, each of your team members needs access to the same Terraform state files. That means you need to store those files in a shared location.
2. Locking state files

    As soon as data is shared, you run into a new problem: locking. Without locking, if two team members are running Terraform at the same time, you can run into race conditions as multiple Terraform processes make concurrent updates to the state files, leading to conflicts, data loss, and state file corruption.
3. Isolating state files

    When making changes to your infrastructure, it’s a best practice to isolate different environments. For example, when making a change in a testing or staging environment, you want to be sure that there is no way you can accidentally break production. But how can you isolate your changes if all of your infrastructure is defined in the same Terraform state file?

The most common technique for allowing multiple team members to access a common set of files is to put them in version control (e.g., Git). Although you should definitely store your Terraform code in version control, storing Terraform state in version control is a bad idea for the following reasons:

Manual error

    It’s too easy to forget to pull down the latest changes from version control before running Terraform or to push your latest changes to version control after running Terraform. It’s just a matter of time before someone on your team runs Terraform with out-of-date state files and as a result, accidentally rolls back or duplicates previous deployments.
Locking

    Most version control systems do not provide any form of locking that would prevent two team members from running terraform apply on the same state file at the same time.
Secrets

    All data in Terraform state files is stored in plain text. This is a problem because certain Terraform resources need to store sensitive data. For example, if you use the aws_db_instance resource to create a database, Terraform will store the username and password for the database in a state file in plain text. Storing plain-text secrets anywhere is a bad idea, including version control. As of May 2019, this is an open issue1 in the Terraform community


Instead of using version control, the best way to manage shared storage for state files is to use Terraform’s built-in support for remote backends. A Terraform backend determines how Terraform loads and stores state. The default backend, which you’ve been using this entire time, is the local backend, which stores the state file on your local disk. Remote backends allow you to store the state file in a remote, shared store. A number of remote backends are supported, including Amazon S3; Azure Storage; Google Cloud Storage; and HashiCorp’s Terraform Cloud and Terraform Enterprise.

Remote backends solve the three issues just listed:

Manual error

    After you configure a remote backend, Terraform will automatically load the state file from that backend every time you run plan or apply and it’ll automatically store the state file in that backend after each apply, so there’s no chance of manual error.
Locking

    Most of the remote backends natively support locking. To run terraform apply, Terraform will automatically acquire a lock; if someone else is already running apply, they will already have the lock, and you will have to wait. You can run apply with the -lock-timeout=<TIME> parameter to instruct Terraform to wait up to TIME for a lock to be released (e.g., -lock-timeout=10m will wait for 10 minutes).
Secrets

    Most of the remote backends natively support encryption in transit and encryption at rest of the state file. Moreover, those backends usually expose ways to configure access permissions (e.g., using IAM policies with an Amazon S3 bucket), so you can control who has access to your state files and the secrets they might contain. It would be better still if Terraform natively supported encrypting secrets within the state file, but these remote backends reduce most of the security concerns, given that at least the state file isn’t stored in plain text on disk anywhere.

If you’re using Terraform with AWS, Amazon S3 (Simple Storage Service), which is Amazon’s managed file store, is typically your best bet as a remote backend for the following reasons:

    It’s a managed service, so you don’t need to deploy and manage extra infrastructure to use it.

    It’s designed for 99.999999999% durability and 99.99% availability, which means you don’t need to worry too much about data loss or outages.2

    It supports encryption, which reduces worries about storing sensitive data in state files. Anyone on your team who has access to that S3 bucket will be able to see the state files in an unencrypted form, so this is still a partial solution, but at least the data will be encrypted at rest (Amazon S3 supports server-side encryption using AES-256) and in transit (Terraform uses TLS when talking to Amazon S3).

    It supports locking via DynamoDB. (More on this later.)

    It supports versioning, so every revision of your state file is stored, and you can roll back to an older version if something goes wrong.

    It’s inexpensive, with most Terraform usage easily fitting into the free tier.

To configure Terraform to store the state in your S3 bucket (with encryption and locking), you need to add a backend configuration to your Terraform code. This is configuration for Terraform itself, so it resides within a terraform block, and has the following syntax:

terraform {
  backend "<BACKEND_NAME>" {
    [CONFIG...]
  }
}

where BACKEND_NAME is the name of the backend you want to use (e.g., "s3") and CONFIG consists of one or more arguments that are specific to that backend (e.g., the name of the S3 bucket to use).