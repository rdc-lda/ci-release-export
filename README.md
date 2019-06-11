# CI build Docker: export release

CI Docker image for exporting a release from S3 to local directory, remote S3 or (S)FTP destination.

## Background

When creating a software release for clients, often you need to ship more then just the binaries alone; artefact fingerprints, deployment manifests, example configuration files, test reports are some examples which come to mind.

A good practice is to implement a release gateway within your organization which on one side is connected to the build-release pipelines internally and provides a secure, immutable endpoint as a start for the deployment processes, wether these are internal or for client use.

An example directory setup for Spring Boot based artefacts is shown below:

~~~text
artefactA
└── x.y.z
    ├── CHANGELOG.md
    ├── COMPONENT.md
    ├── RELEASE_NOTES.md
    ├── artefactA-x.y.z.jar
    ├── artefactA-x.y.z.jar.sig
    ├── config
    │   └── application.properties
    ├── deployment
    │   ├── container
    │   │   ├── Dockerfile
    │   │   └── start-service.sh
    │   └── paas
    │       ├── cloudfoundry
    │       │   ├── manifest.yml
    │       │   └── params.yml
    │       └── openshift
    │           ├── configure.yml
    │           └── deploy.yml
    └── reports
        ├── api-security.pdf
        ├── code-quality.pdf
        ├── cve-impact.pdf
        ├── oss-licenses.pdf
        └── performance.pdf
~~~

This CI Docker image helps you extracting a release from your main release gateway exporting only those artefacts / versions which are required.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

In order to develop / test, you need the following tools installed:

* [Docker](https://docs.docker.com/docker-for-mac/install/)
* [GNU Make](http://osxdaily.com/2014/02/12/install-command-line-tools-mac-os-x/) 3.8 or higher

## Built With

* Docker

### Build Docker

~~~bash
# Build the Docker locally
#  -- see output how to run this Docker on your machine
$ make image

# Push Docker to the Docker Registry
$ make push
~~~

## Deployment

Use the Docker image in your CI tooling - you need to specify the following as part of your build:

* `release-manifest.json` - defines the set of artefacts to be included in the release.
* `release-source.json` - defines the source properties of the release (S3, (S)FTP)
* `release-destination.json` - defines the destination properties of the release (local, S3, (S)FTP)

### Release manifest definition

A release consists of a name, version, type (full or update), description and a list of artefacts:

~~~yaml
{
   "name": "my-release",
   "version": "x.y.z",
   "type": "full",
   "description": "Adds features a, b, c.",
   "platform": "openshift",
   "artefacts": {
      "artefact": [
         {
            "name": "my-web-app",
            "version": "x.y.z"
         },
         {
            "name": "my-service-1",
            "version": "x.y.z"
         },
         {
            "name": "my-service-2",
            "version": "x.y.z"
         }
      ]
   }
}
~~~

### Release source properties

The release source (in the directory structure as shown above) needs to be made accessible; hence the file below needs to be defined including some environment variables (since you do not want to expose credentials via source control!).

#### AWS S3 example

Assure you have set in environment the following variables.

| Variable | Description | Example |
|--- |--- |---|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key giving access to the S3 hosted release repository | `MAHYIBA123CS3MUKN456` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Key giving access to the S3 hosted release repository | `zIlwT3123R93Zt3iTu7twN1yuE4Dhbjli143456` |

~~~yaml
{
   "endpoint": {
      "type": "s3",
      "base_url": "s3://s3.ap-south-1.amazonaws.com/my-releases"
   }
}
~~~

### Release destination properties

Similar to the source connection, you also need to provide a destination. For the pipeline always use `local` since the containers will link via workspaces. `S3` is also supported, see previous paragraph for example.

#### SFTP example

Assure you have set in environment the following variables.

| Variable | Description | Example |
|--- |--- |---|
| `SFTP_USER` | Your username giving access to the SFTP hosted release repository | `user123` |
| `SFTP_PASSWORD` | Your password giving access to the SFTP hosted release repository | `S0meth1n9L0n9AndH@rdT0Gu355` |

~~~yaml
{
   "endpoint": {
      "type": "sftp",
      "base_url": "sftp://sftp.host.domain:22/my-releases"
   }
}
~~~

#### Local example

Note the `base_dir` here needs to match your CI/CD pipeline's workspace directory (writable and transferable to next stages).

~~~yaml
{
   "endpoint": {
      "type": "local",
      "base_dir": "./artefacts"
   }
}
~~~

### CircleCI

Just copy the YAML into your build definition:

~~~yaml
TODO
~~~

...and enable to validate step after the build phase in the overall flow:

~~~yaml
# Glue the jobs together
TODO
~~~

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/rdc-lda/fintech-blogs/tags).

## Authors

* **Robin Huiser** - *Initial work* - [robinhuiser](https://github.com/robinhuiser)

See also the list of [contributors](CONTRIBUTORS.md) who participated in this project.

## License

This project is licensed under the Apache License - see the [LICENSE](LICENSE) file for details