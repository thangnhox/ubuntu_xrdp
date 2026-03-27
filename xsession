#!/bin/bash

# Load the udocker environment variables saved by the entrypoint
source /root/.container_env

# Replace this shell with the XFCE desktop environment
exec xfce4-session
