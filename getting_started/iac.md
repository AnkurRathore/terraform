## What is Infrastructure as Code

The idea behind infrastructure as code (IAC) is that you write and execute code to define, deploy, update, and destroy your infrastructure. This represents an important shift in mindset in which you treat all aspects of operations as software—even those aspects that represent hardware (e.g., setting up physical servers). In fact, a key insight of DevOps is that you can manage almost everything in code, including servers, databases, networks, log files, application configuration, documentation, automated tests, deployment processes, and so on.


There are five broad categories of IAC tools:

1. Ad hoc scripts

2. Configuration management tools

3. Server templating tools

4. Orchestration tools

5. Provisioning tools

## How Terraform Works

Here is a high-level and somewhat simplified view of how Terraform works. Terraform is an open source tool created by HashiCorp and written in the Go programming language. The Go code compiles down into a single binary (or rather, one binary for each of the supported operating systems) called, not surprisingly, terraform.

You can use this binary to deploy infrastructure from your laptop or a build server or just about any other computer, and you don’t need to run any extra infrastructure to make that happen. That’s because under the hood, the terraform binary makes API calls on your behalf to one or more providers, such as AWS, Azure, Google Cloud, DigitalOcean, OpenStack, and more. This means that Terraform gets to leverage the infrastructure those providers are already running for their API servers, as well as the authentication mechanisms you’re already using with those providers (e.g., the API keys you already have for AWS).

You can define your entire infrastructure—servers, databases, load balancers, network topology, and so on—in Terraform configuration files and commit those files to version control. You then run certain Terraform commands, such as terraform apply, to deploy that infrastructure. The terraform binary parses your code, translates it into a series of API calls to the cloud providers specified in the code, and makes those API calls as efficiently as possible on your behalf.

When someone on your team needs to make changes to the infrastructure, instead of updating the infrastructure manually and directly on the servers, they make their changes in the Terraform configuration files, validate those changes through automated tests and code reviews, commit the updated code to version control, and then run the terraform apply command to have Terraform make the necessary API calls to deploy the changes.

When selecting IAC tools,Here are the main trade-offs to consider:

1. Configuration management versus provisioning

2. Mutable infrastructure versus immutable infrastructure

3. Procedural language versus declarative language

4. Master versus masterless

5. Agent versus agentless

6. Large community versus small community

7. Mature versus cutting-edge

8. Using multiple tools together

