# Use Ubuntu as the base
FROM ubuntu:22.04

# Expose Docker's built-in architecture variable
ARG TARGETARCH

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh


# 1. Install necessary packages
# We add python3 for the subreaper syscall and dbus-x11 for XFCE stability
# Change this:
# apt-get install -y --no-install-recommends xrdp xfce4 xfce4-goodies sudo ...

# To this:
RUN apt-get update && \
    apt-get install -y \
        xrdp \
        xfce4 \
        sudo \
        python3 \
        dbus-x11 \
        x11-xserver-utils \
	xfce4-terminal \
        procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Install Min Browser & Configure it for Root (--no-sandbox)
# Dynamically copy the pre-downloaded file based on the target architecture
COPY installer/min-${TARGETARCH}.deb /tmp/min.deb

RUN apt-get update && \
    apt-get install -y /tmp/min.deb && \
    rm /tmp/min.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN rm /usr/bin/min && \
    echo '#!/bin/bash\nexec /opt/Min/min --no-sandbox "$@"' > /usr/bin/min && \
    chmod +x /usr/bin/min

# 3. Create the non-root user
RUN echo "root:password123" | chpasswd


# 4. Configure XFCE for the user
COPY --chmod=755 xsession /root/.xsession

# 5. Create the entrypoint script inside the image
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# 6. Network configuration
EXPOSE 3389


# 7. Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
