# A Blocks / JavaScript code editor for the [micro:bit](https://microbit.org) built on Microsoft MakeCode

## Tags:

* **-tools**: MakeCode-related tools, without MakeCode source code
* **-devel**: MakeCode-related tools, with MakeCode source code
* **-final, latest**: small, nginx-based image with compiled, static served MakeCode

## Environment variables (-tools, -devel tags)

* **PUID**: Host User ID for **unpriv** (unprivileged) user
* **PGID**: Host Group ID for **unpriv** (unprivileged) user
* **YOTTA_GITHUB_AUTHTOKEN**: GitHub auth token for building, avoid "anonymous rate limit error", see https://github.com/settings/tokens

## Related links:

* micro:bit: https://microbit.org/
* Microsoft MakeCode: https://makecode.microbit.org/
* Project source code: https://github.com/microsoft/pxt-microbit/
* Builder source code: https://github.com/nevergone/microbit-makecode-editor
* Docker Hub: https://hub.docker.com/r/nevergone/microbit-makecode-editor

***Usage:***

`docker run --name microbit-makecode-editor -p 8080:80 nevergone/microbit-makecode-editor:latest` and visit http://localhost:8080/ with your browser.
