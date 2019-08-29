# wct-app

## Usage

### Running Locally

1. Build the container

   ```sh
   docker build . -t wct-app:local
   ```

1. Run locally

   ```sh
   docker run --rm -d --name wct-app -p 8000:8000 wct-app:local
   ```

1. Hit it with curl

   ```sh
   $ curl -X POST http://localhost:8001/api/v0/widgetize -d '{"widget_material":"make me a widget!"}'
   {"wct_version":"1.2.4","widget":"(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n(\u0ca0_\u0ca0)make me a widget!(\u0ca0_\u0ca0)\n"}
   ```

1. Delete the container when you are done

   ```sh
   docker rm -f wct-app
   ```

## Contributing

### Releasing a new version

1. Change the value of the `WCT_VERSION` variable in [Dockerfile](./Dockerfile)
