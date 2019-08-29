# wct-app

## Usage

### Running Locally

1. Build the container. See [Build the docker container](#build-the-docker-container)

2. Run locally

   ```sh
   docker run --rm -d --name wct-app -p 8000:8000 wct-app:local
   ```

3. Hit it with curl

   ```sh
   $ curl -X POST http://localhost:8000/api/v0/widgetize -d '{"widget_material":"make me a widget!"}'

   {"wct_version":"1.2.4","widget":"(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n"}
   ```

4. Delete the container when you are done

   ```sh
   docker rm -f wct-app
   ```

## Contributing

### Get the Taskfile tool

The project uses [task](https://taskfile.dev). There is a small shell script you can run to install it to `./bin/task`.

```sh
curl -sL https://taskfile.dev/install.sh | sh
```

Homebrew:

```sh
brew install go-task/tap/go-task
```

Other platforms: [https://taskfile.dev/#/installation](https://taskfile.dev/#/installation)

### Mimicing the Jenkins testing pipeline locally

Shell into the same container Jenkins uses for building and testing the app

```sh
docker run -it --rm --mount type=bind,source="$(pwd)",target=/project -w /project bitnami/python:3.7 bash -c "curl -sL https://taskfile.dev/install.sh | sh && bash"
```

Then run the commands Jenkins runs

```sh
bin/task installDeps
bin/task safetyCheck
bin/task lint
bin/task test
```

### Build the docker container

To build the docker container, run:

```sh
task dockerBuild
```

The docker container will be built and tagged as `wct-app:local`

### Releasing a new version

1. Change the value of the `WCT_VERSION` variable in [Dockerfile](./Dockerfile)
