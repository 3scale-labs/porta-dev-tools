# Porta dev-tools
These are dev tools to play with [3scale/porta](https://github.com/3scale/porta) in local environment. They include:

1. a CLI to ease commands such as starting the Rails server, launch dependencies, deploy to OpenShift, etc (see the [full list](#supported-commands) of commands)
2. [Porxy](porxy/README.md), a porksy proxy to porta


> :warning: Porta dev-tools are for development purposes and cannot in any way be considered a replacement for Red Hat's official recommendations to work with 3scale.

> :warning: Porta dev-tools commands and settings were tested under Mac OS X with zsh shell. You may need adapt them for your own environment.

## Requirements
Porta dev-tools assume you can already run 3scale/porta locally with whatever DBMS currently supported (MySQL, PostgreSQL, Oracle). See [installation instructions](https://github.com/3scale/porta/blob/master/INSTALL.md) for help.

A running instance of Redis is expected to be attending to port 6379, as well as a DNS resolver capable of handling wildcard domains, such as dnsmasq. These are usual requirements of 3scale/porta, but may be used as well by other components triggered with some of Porta dev-tools commands.

If you are using dnsmasq, make sure to include the following two DNS records. (They will be particularly useful to run Porta along with [3scale/APIcast](https://github.com/3scale/apicast).)

```conf
address=/example.com.local/127.0.0.1
address=/staging.apicast.dev/127.0.0.1
```

For [3scale/apisonator](https://github.com/3scale/apisonator), make sure to have an env file saved in your file system with the following content:

```shell
CONFIG_QUEUES_MASTER_NAME=host.docker.internal:6379/5
CONFIG_REDIS_PROXY=host.docker.internal:6379/6
CONFIG_INTERNAL_API_USER=system_app
CONFIG_INTERNAL_API_PASSWORD=password
RACK_ENV=production
```

Apart from the aforementioned requirements, specific commands of Porta dev-tools may additionally require:

- Docker
- [OpenShift CLI Tools](https://docs.openshift.com/container-platform/4.3/cli_reference/openshift_cli/getting-started-cli.html)
- A clone of the [3scale/3scale-operator](https://github.com/3scale/3scale-operator) repo
- A public OpenShift cluster where to deploy 3scale

## Install

```shell
export PORTA_DEV_TOOLS_PATH=/usr/local/porta-dev-tools
git clone git@github.com:guicassolato/porta-dev-tools.git $PORTA_DEV_TOOLS_PATH
echo "export PATH=$PORTA_DEV_TOOLS_PATH/bin:$PATH">>~/.zshrc
```

### Settings/defaults
You may want to copy and edit the `settings.yml` file. This file holds default values to options of the Porta dev-tools commands, such as the paths to the Porta and other repos locally, secret keys, etc.

```shell
cp $PORTA_DEV_TOOLS_PATH/config/examples/settings.yml $PORTA_DEV_TOOLS_PATH/config/
```

## Usage

General syntax:

```shell
porta CMD [options]
```

### Supported commands

| Command  | Description                                                                           |
| ---------|---------------------------------------------------------------------------------------|
| server   | Starts the Rails server locally                                                       |
| sidekiq  | Starts a Sidekiq worker locally                                                       |
| portafly | Starts Portafly                                                                       |
| reset    | Resets Porta's databases (Redis and DBMS)                                             |
| assets   | Removes node_modules and precompile assets again                                      |
| test     | Bundle execs a Porta's Rails test file                                                |
| cuke     | Bundle execs a Porta's Cucumber test file                                             |
| deps     | Runs (in docker) components that Porta depends upon – Apisonator, APIcast and porxy   |
| sync     | Resyncs Porta with Apisonator (Sidekiq and Apisonator must both be running)           |
| build    | Builds Porta for OpenShift                                                            |
| push     | Pushes latest `system-os` docker image to quay.io                                     |
| deploy   | Deploys 3scale to an OpenShift devel cluster, fetching images from quay.io            |
| help     | Prints the list of available commands                                                 |

You can get a full list of the supported commands by running:

```shell
porta help
```

### Common options

The following options are available with all commands:

| Option      | Description                                                                              |
| ------------|------------------------------------------------------------------------------------------|
| `--help`    | Prints the specific help fo rthe command, which includes a list of the supported options |
| `--explain` | Prints the commands to STDOUT instead of executing them                                  |
| `--verbose` | Prints every command executed                                                            |

## Examples

### Workflow to run porta and dependencies locally

```shell
porta reset
porta deps
porta sidekiq  # hijacks the shell
porta sync
porta server   # hijacks the shell
```

### Workflow to build and deploy porta to OCP

```shell
porta build
porta push
porta deploy --watch
```
