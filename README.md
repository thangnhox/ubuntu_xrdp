# Build

```Bash
docker build -t ubuntu-xrdp .
```

Supported platform: linux/arm64, linux/amd64

Note:
- You have to build this on docker overlay2 or else udocker won't be able to load it.
- You may need to bind /dev/shm (on android /dev/shm isn't available, you just need to bind it with normal folder)


Enviroment support:
- PULSE_SERVER: Allows to set audio output (requires dedicate pulseaudio server)

Example Command:

```Bash
# Load image
udocker load -i ubuntu-xrdp.tar ubuntu-xrdp

# Create container
udocker create --name=container-name ubuntu-xrdp:latest

# Run
udocker run --env=PULSE_SERVER=127.0.0.1 --volume=/dev/shm:/dev/shm container-name
```
