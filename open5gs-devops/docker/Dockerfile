FROM ubuntu:22.04 AS builder

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && \
    apt-get install -y \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    ninja-build \
    build-essential \
    flex \
    bison \
    git \
    cmake \
    libsctp-dev \
    libgnutls28-dev \
    libgcrypt-dev \
    libssl-dev \
    libidn11-dev \
    libmongoc-dev \
    libbson-dev \
    libyaml-dev \
    libnghttp2-dev \
    libmicrohttpd-dev \
    libcurl4-gnutls-dev \
    libnghttp2-dev \
    libtins-dev \
    libtalloc-dev \
    meson \
    && rm -rf /var/lib/apt/lists/*

# Clone and build Open5GS
WORKDIR /open5gs
RUN git clone --depth 1 https://github.com/open5gs/open5gs.git /open5gs

RUN meson build --prefix=/usr/local && \
    ninja -C build && \
    cd build && \
    ninja install

# Runtime stage
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y \
    libsctp1 \
    libgnutls30 \
    libgcrypt20 \
    libssl3 \
    libidn11 \
    libmongoc-1.0-0 \
    libbson-1.0-0 \
    libyaml-0-2 \
    libnghttp2-14 \
    libmicrohttpd12 \
    libcurl4-gnutls-dev \
    libtins4.4 \
    libtalloc2 \
    iptables \
    iputils-ping \
    tcpdump \
    net-tools \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy built files from builder
COPY --from=builder /usr/local /usr/local

# Create necessary directories
RUN mkdir -p /var/log/open5gs && \
    mkdir -p /etc/open5gs && \
    mkdir -p /var/run/open5gs

# Set library path
ENV LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu

WORKDIR /

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD pgrep -f open5gs || exit 1

CMD ["/bin/bash"]
