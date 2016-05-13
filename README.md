lambit
========

A utility to manage AWS Lambda Service. Lambda + It => Lambit!

This tool programmatically manages AWS Lambdas including various Event Sources using Lambit project conventions and a yaml configuration file. It also has the ability to associate alarms based on metrics produced.


## Prerequisites
- AWS properly configured on machine for SDK/CLI


## Shell Environment Variables
- $AWS_REGION
    * Required
- $AWS_ACCESS_KEY
    * Optional
- $AWS_SECRET_KEY
    * Optional
- $LAMBIT_PROJECT_PATH
    * Required path to Lambit project
- $LAMBIT_CONFIG_FILENAME
    * The config filename for Lambit
    * Defaults to 'lambit.yml'
- $LAMBIT_REGEXP
    * The filter regexp to filter Lambda Function(s)
    * Default is nil and processes all project Lambdas


## Lambit Commands
- build
    * Builds Lambda Function deploy packages for deployment for Lambit project Lambda(s)
- deploy
    * Deploys (creates AWS Lambda Functions) for project Lambda(s) using built Lambda Function deploy packages
- delete
    * Deletes the AWS Lambda Functions for the project Lambda(s)
- add_event_sources
    * Adds Event Sources to the AWS Lambda Functions for the project Lambda(s)
- remove_event_sources
    * Removes Event Sources from the AWS Lambda Functions for the project Lambda(s)
- add_alarms
    * Adds CloudWatch Alarms to the AWS Lambda Functions for the project Lambda(s)
- delete_alarms
    * Deletes CloudWatch Alarms from the AWS Lambda Functions for the project Lambda(s)


### Example Usages
``` shell
lambit build
lambit deploy
lambit add_event_sources
lambit add_alarms
```

## Lambit Project Conventions

```shell
./lambdas
  ./my-lambit-project
    ./function
    ./templates
    .lambit.yml
  ./my-other-lambit-project
    ...
```

- 'function' directory should contain any function code (required)
- 'templates' directory should contain any templates like .json files (optional)
- 'lambit.yml' configuration file for Lambit project, please look at example 'lambit.yml.example'
  - Relevant section values conform to aws-sdk expected hashes, refer to the 'aws-sdk' for rb for details
  - Python Lambda Functions are able to install 'required_pips' for deployable packages
  - Advanced: Sprinkle of built-in magic that provides support for fetching function names and indexes (subject to change)

Credit [Ethan Rowe ](https://github.com/ethanrowe) for the original command handler technique in [hadupils](https://github.com/ethanrowe/hadupils).