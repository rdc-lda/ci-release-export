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

This CI Docker image helps you extracting a release from your main release gateway exporting only those artefacts / versions which are required to a designated endpoint (the software client vault) such as SFTP or S3.

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

A release consists of a name, version, type (full or update), description and a list of artefacts.

An example `release-manifest.json` is provided below:

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

### Release source - destination credentials

The release source (in the directory structure as shown above) needs to be made accessible; hence the file below needs to be defined including some environment variables (since you do not want to persist and expose credentials via source control!).

#### AWS S3 example

Assure you have set in environment the following variables.

| Variable | Description | Example |
|--- |--- |---|
| `[SOURCE|DESTINATION]_AWS_ACCESS_KEY_ID` | Your AWS Access Key giving access to the S3 hosted release repository | `MAHYIBA123CS3MUKN456` |
| `[SOURCE|DESTINATION]_AWS_SECRET_ACCESS_KEY` | Your AWS Secret Key giving access to the S3 hosted release repository | `zIlwT3123R93Zt3iTu7twN1yuE4Dhbjli143456` |

An example `release-source.json` or `release-destination.json` is provided below:

~~~yaml
{
   "endpoint": {
      "type": "s3",
      "base_url": "s3://my-releases"
   }
}
~~~

#### SFTP example

Assure you have set in environment the following variables.

| Variable | Description | Example |
|--- |--- |---|
| `[SOURCE|DESTINATION]_SFTP_USERNAME` | Your SFTP username giving access to the SFTP hosted directory | `user123` |
| `[SOURCE|DESTINATION]_SFTP_PASSWORD` | Your AWS Secret Key giving access to the S3 hosted release repository | `S0m3th1n9L0n9AndH@rd!` |

An example `release-source.json` or `release-destination.json` is provided below:

~~~yaml
{
    "endpoint": {
       "type": "sftp",
       "host": "my-sftp.mydomain.com",
       "port": "22",
       "base_dir": "/upload"
    }
 }
~~~

**Tip**: *in order to setup and secure an SFTP Server per user basis, use [this document](./SFTP-Server-Centos.md).*

### Manual download, validate and push release

This section describes how to publish a release to the software vault of the client.

1. Assure you have created the `release-source.json`, `release-destination.json` and `release-manifest.json` files in a `manifest directory` on your machine
1. Assure you have enough disk space locally to accommodate for the release
1. Export the `AWS` credentials in order to retrieve files from the CBX releases to your shell
1. Export the `SFTP` credentials for the destination server to your shell
1. Run the Docker command below to download, validate and push the release

~~~bash
# Set your AWS access keys -- assuming you use S3 as the source for the release
$ export SOURCE_AWS_ACCESS_KEY_ID=your_key_id_here
$ export SOURCE_AWS_SECRET_ACCESS_KEY=your_access_key_here

# Set your SFTP credentials -- assuming you use SFTP as the destination for the release
$ export DESTINATION_SFTP_USERNAME=your_username
$ export DESTINATION_SFTP_PASSWORD=your_password

# Provide the manifest directory on the host and a temporarily directory
$ docker run \
  -v $PWD/test:/var/data/manifests \
  -v /tmp/release-download:/var/data/release-download \
  -e SOURCE_AWS_ACCESS_KEY_ID="$SOURCE_AWS_ACCESS_KEY_ID" \
  -e SOURCE_AWS_SECRET_ACCESS_KEY="$SOURCE_AWS_SECRET_ACCESS_KEY" \
  -e DESTINATION_SFTP_USERNAME="$DESTINATION_SFTP_USERNAME" \
  -e DESTINATION_SFTP_PASSWORD="$DESTINATION_SFTP_PASSWORD" \
  rdclda/ci-export-release
~~~

### CircleCI - download release

Just copy the YAML into your build definition:

~~~yaml
jobs:

  # Download the release artefacts
  download_release:
    docker:
      - image: rdclda/ci-export-release
    working_directory: ~/release
    steps:
      # Checkout the repository
      - checkout

      # Create workspace output folder
      - run:
          name: Create workspace directory
          command: mkdir -p ./artefacts

      # Retrieve the artefacts
      - run:
          name: Export artefacts to its defined destination
          command: |
            download-release \
              --source=release-source.json \
              --manifest=release-manifest.json \
              --destination=./artefacts

      # Copy the release manifest into the workspace
      - run:
          name: Copy release manifest
          command: cp ./release-manifest.json artefacts/

      - persist_to_workspace:
          # Must be an absolute path, or relative path from working_directory
          root: ~/release
          # Must be relative path from root
          paths:
             - artefacts/
~~~

### CircleCI - validate release

Just copy the YAML into your build definition:

~~~yaml
jobs:

  # Validate the downloaded release
  validate_release:
    docker:
      - image: rdclda/ci-export-release
    working_directory: ~/release
    steps:
      - attach_workspace:
          # Must be absolute path or relative path from working_directory
          at: ~/release

      # Retrieve the artefacts
      - run:
          name: Validate the artefacts
          command: |
            validate-release \
              --source=./artefacts \
              --manifest=./artefacts/release-manifest.json
~~~

### CircleCI - push release

Just copy the YAML into your build definition:

~~~yaml
jobs:

  # Validate the downloaded release
  validate_release:
    docker:
      - image: rdclda/ci-export-release
    working_directory: ~/release
    steps:
      - attach_workspace:
          # Must be absolute path or relative path from working_directory
          at: ~/release

      # Retrieve the artefacts
      - run:
          name: Validate the artefacts
          command: |
            push-release \
              --source=./artefacts \
              --manifest=./artefacts/release-manifest.json \
              --destination=./artefacts/release-destination.json
~~~

...and enable to export step in the overall flow:

~~~yaml
# Glue the jobs together
workflows:
  version: 2
  deploy:
    jobs:
      - download_release
      - validate_release:
          requires:
            - download_release
      - push_release:
          requires:
            - validate_release
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