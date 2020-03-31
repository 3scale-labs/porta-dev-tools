# Porxy
Porxy is a porksy proxy of [porta](https://github.com/3scale/porta), a shitty solution to mediate the commnunication between [3scale/APIcast](https://github.com/3scale/APIcast), running in a docker, and [3scale/porta](https://github.com/3scale/porta), running in local environment.

This is extrictly for development purposes and cannot be considered a replacement for Red Hat's official recommendations to work with 3scale.

## Requirements
Porxy assumes you can run 3scale/porta locally with whatever DBMS currently supported (MySQL, PostgreSQL, Oracle). See [installation instructions](https://github.com/3scale/porta/blob/master/INSTALL.md) for help.

You should also have Docker running in your environment.

A Redis instance is expected to be running locally and attending to port 6379, as well as a DNS resolver capable of handling wildcard domains, such as dnsmasq.

If you are using dnsmasq, make sure to include the following two DNS records:

```
address=/example.com.local/127.0.0.1
address=/staging.apicast.dev/127.0.0.1
```

The instructions were tested in Mac OS X with zsh shell. You may addapt to your own environment accordingly.

## Parameters

Consider the following general parameters for the [Setup](#setup) and [Run](#run) sections below. Other parameters may be indicated specifically for each component.

| Parameter | Description |
| ----------|-------------|
| `<APICAST_ACCESS_TOKEN>` | 3scale/APIcast special access token to access 3scale/Porta's Master API |
| `<PATH_TO_APISONATOR_ENV_FILE>` | Path to an env file to be used by 3scale/apisonator. |

## Setup

### Reset 3scale/porta databases
```
redis-cli flushall && bundle exec rails db:reset MASTER_PASSWORD=p USER_PASSWORD=p DEV_GTLD=local APICAST_ACCESS_TOKEN=<APICAST_ACCESS_TOKEN>
```

### Env file for 3scale/apisonator
Prepare an env file for 3scale/apisonator:

```
echo "CONFIG_QUEUES_MASTER_NAME=host.docker.internal:6379/5\n\
CONFIG_REDIS_PROXY=host.docker.internal:6379/6\n\
CONFIG_INTERNAL_API_USER=system_app\n\
CONFIG_INTERNAL_API_PASSWORD=password\n\
RACK_ENV=production" > <PATH_TO_APISONATOR_ENV_FILE>
```

## Run

The instructions below will run:
- [3scale/apisonator](https://github.com/3scale/apisonator) in a docker (listerner attending to port 3001 and worker)
- [3scale/porta](https://github.com/3scale/porta) Rails server in local environment (at port 3000)
- [3scale/porta](https://github.com/3scale/porta) Sidekiq processes in local environment
- Porxy in a docker (listening to port 3008)
- Staging [3scale/APIcast](https://github.com/3scale/APIcast) (listening to port 8080)

### Run 3scale/apisonator in a docker

#### Listener
```
docker run -d --name apisonator --rm -p 3001:3001 --env-file <PATH_TO_APISONATOR_ENV_FILE> -it quay.io/3scale/apisonator:latest 3scale_backend start -p 3001 -l /var/log/backend/3scale_backend.log
```

#### Worker
```
docker run -d --name apisonator_worker --rm --env-file <PATH_TO_APISONATOR_ENV_FILE> -it quay.io/3scale/apisonator:latest 3scale_backend_worker run
```

### Run 3scale/porta locally

#### Porta Rails server
```
DEV_GTLD=local UNICORN_WORKERS=8 rails s -b 0.0.0.0
```

#### Porta Sidekiq (in another shell)
```
DEV_GTLD=local RAILS_MAX_THREADS=5 bundle exec rails sidekiq
```

### Run Porxy in a docker

```
docker run -d --name porxy --rm -p 3008:3008 quay.io/guicassolato/porxy:latest
```

### Run 3scale/APIcast in a docker

```
docker run -d --name apicast --rm -p 8080:8080 -e THREESCALE_PORTAL_ENDPOINT="http://<APICAST_ACCESS_TOKEN>@host.docker.internal:3008/master/api/proxy/configs" -e THREESCALE_DEPLOYMENT_ENV=staging -e BACKEND_ENDPOINT_OVERRIDE="http://host.docker.internal:3001" quay.io/3scale/apicast:master
```
