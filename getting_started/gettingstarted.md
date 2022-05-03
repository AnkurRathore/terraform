## Deploy a Single Server

Terraform code is written in the HashiCorp Configuration Language (HCL) in files with the extension .tf.8 It is a declarative language, so your goal is to describe the infrastructure you want, and Terraform will figure out how to create it. Terraform can create infrastructure across a wide variety of platforms, or what it calls providers, including AWS, Azure, Google Cloud, DigitalOcean, and many others.

The first step to using Terraform is typically to configure the provider(s) you want to use. Create an empty folder and put a file in it called main.tf that contains the following contents:

```
provider "aws" {
  region = "us-east-2"
}

```

This tells Terraform that you are going to be using AWS as your provider and that you want to deploy your infrastructure into the us-east-2 region. 

For each type of provider, there are many different kinds of resources that you can create, such as servers, databases, and load balancers. The general syntax for creating a resource in Terraform is:

resource "<PROVIDER>_<TYPE>" "<NAME>" {
  [CONFIG ...]
}

where PROVIDER is the name of a provider (e.g., aws), TYPE is the type of resource to create in that provider (e.g., instance), NAME is an identifier you can use throughout the Terraform code to refer to this resource (e.g., my_instance), and CONFIG consists of one or more arguments that are specific to that resource.

For example, to deploy a single (virtual) server in AWS, known as an EC2 Instance, use the aws_instance resource in main.tf as follows:

resource "aws_instance" "example" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
}

Creating security groups
```
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
An expression in Terraform is anything that returns a value. You’ve already seen the simplest type of expressions, literals, such as strings (e.g., "ami-0fb653ca2d3203ac1") and numbers (e.g., 5). Terraform supports many other types of expressions that you’ll see throughout the book.

One particularly useful type of expression is a reference, which allows you to access values from other parts of your code. To access the ID of the security group resource, you are going to need to use a resource attribute reference, which uses the following syntax:

<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>

where PROVIDER is the name of the provider (e.g., aws), TYPE is the type of resource (e.g., security_group), NAME is the name of that resource (e.g., the security group is named "instance"), and ATTRIBUTE is either one of the arguments of that resource (e.g., name) or one of the attributes exported by the resource 

When you add a reference from one resource to another, you create an implicit dependency. Terraform parses these dependencies, builds a dependency graph from them, and uses that to automatically determine in which order it should create resources. For example, if you were deploying this code from scratch, Terraform would know that it needs to create the security group before the EC2 Instance, because the EC2 Instance references the ID of the security group. You can even get Terraform to show you the dependency graph by running the graph command

When Terraform walks your dependency tree, it creates as many resources in parallel as it can, which means that it can apply your changes fairly efficiently. That’s the beauty of a declarative language: you just specify what you want and Terraform determines the most efficient way to make it happen.

To allow you to make your code more DRY and more configurable, Terraform allows you to define input variables. Here’s the syntax for declaring a variable:

variable "NAME" {
  [CONFIG ...]
}

The body of the variable declaration can contain the following optional parameters:

description

    It’s always a good idea to use this parameter to document how a variable is used. Your teammates will not only be able to see this description while reading the code, but also when running the plan or apply commands (you’ll see an example of this shortly).
default

    There are a number of ways to provide a value for the variable, including passing it in at the command line (using the -var option), via a file (using the -var-file option), or via an environment variable (Terraform looks for environment variables of the name TF_VAR_<variable_name>). If no value is passed in, the variable will fall back to this default value. If there is no default value, Terraform will interactively prompt the user for one.
type

    This allows you to enforce type constraints on the variables a user passes in. Terraform supports a number of type constraints, including string, number, bool, list, map, set, object, tuple, and any. It’s always a good idea to define a type constraint to catch simple errors. If you don’t specify a type, Terraform assumes the type is any.
validation

    This allows you to define custom validation rules for the input variable that go beyond basic type checks, such as enforcing minimum or maximum values on a number.
sensitive

    If you set this parameter to true on an input variable, Terraform will not log it when you run plan or apply. You should use this on any secrets you pass into your Terraform code via variables: e.g., passwords, API keys


Here is an example of an input variable that checks to verify that the value you pass in is a number:

variable "number_example" {
  description = "An example of a number variable in Terraform"
  type        = number
  default     = 42
}

And here’s an example of a variable that checks whether the value is a list:

variable "list_example" {
  description = "An example of a list in Terraform"
  type        = list
  default     = ["a", "b", "c"]
}

You can combine type constraints, too. For example, here’s a list input variable that requires all of the items in the list to be numbers:

variable "list_numeric_example" {
  description = "An example of a numeric list in Terraform"
  type        = list(number)
  default     = [1, 2, 3]
}

And here’s a map that requires all of the values to be strings:

variable "map_example" {
  description = "An example of a map in Terraform"
  type        = map(string)

  default = {
    key1 = "value1"
    key2 = "value2"
    key3 = "value3"
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

A data source represents a piece of read-only information that is fetched from the provider (in this case, AWS) every time you run Terraform. Adding a data source to your Terraform configurations does not create anything new; it’s just a way to query the provider’s APIs for data and to make that data available to the rest of your Terraform code. Each Terraform provider exposes a variety of data sources. For example, the AWS provider includes data sources to look up VPC data, subnet data, AMI IDs, IP address ranges, the current user’s identity, and much more.

The syntax for using a data source is very similar to the syntax of a resource:

data "<PROVIDER>_<TYPE>" "<NAME>" {
  [CONFIG ...]
}

Here, PROVIDER is the name of a provider (e.g., aws), TYPE is the type of data source you want to use (e.g., vpc), NAME is an identifier you can use throughout the Terraform code to refer to this data source, and CONFIG consists of one or more arguments that are specific to that data source.

 For example, here is how you can use the aws_vpc data source to look up the data for your Default VPC:

data "aws_vpc" "default" {
  default = true
}

Note that with data sources, the arguments you pass in are typically search filters that indicate to the data source what information you’re looking for. With the aws_vpc data source, the only filter you need is default = true, which directs Terraform to look up the Default VPC in your AWS account.

To get the data out of a data source, you use the following attribute reference syntax:

data.<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>

For example, to get the ID of the VPC from the aws_vpc data source, you would use the following:

data.aws_vpc.default.id

You can combine this with another data source, aws_subnets, to look up the subnets within that VPC:

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}