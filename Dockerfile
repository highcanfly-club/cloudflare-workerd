# Build: docker build --build-arg REMOTE_CACHE_URL=https://user:password@bazel-cache:8080 -t highcanfly/cloudflare-workerd .
# Run: docker run -it --rm highcanfly/cloudflare-workerd
FROM node:bullseye AS builder

ARG FORCED_VERSION
ARG REMOTE_CACHE_URL
RUN if [ -n "$FORCED_VERSION" ]; then \
        export LATEST_TAG=$FORCED_VERSION;  \
    else \
        export LATEST_TAG=$(curl --silent "https://api.github.com/repos/cloudflare/workerd/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'); \
    fi && \
    echo $LATEST_TAG && \
    echo $LATEST_TAG  > /workerd_version

RUN apt-get update
RUN apt-get install -y curl build-essential git lsb-release wget software-properties-common gnupg tcl libc++-dev libc++abi-dev

RUN export LATEST_TAG=$(cat /workerd_version) && \
    cd / && \
    echo "Building version $LATEST_TAG" && \
    cat /workerd_version && \
    git clone https://github.com/cloudflare/workerd.git && \
    cd /workerd && \
    git checkout $LATEST_TAG
WORKDIR /workerd
RUN wget https://apt.llvm.org/llvm.sh
RUN chmod +x llvm.sh
RUN ./llvm.sh 15 all
COPY . .

RUN echo "build:linux --action_env=CC=/usr/lib/llvm-15/bin/clang --action_env=CXX=/usr/lib/llvm-15/bin/clang++" >> .bazelrc
RUN echo "build:linux --host_action_env=CC=/usr/lib/llvm-15/bin/clang --host_action_env=CXX=/usr/lib/llvm-15/bin/clang++" >> .bazelrc
# COPY .bazel-cache /bazel-disk-cache
RUN mkdir /bazel-disk-cache
RUN npm install -g pnpm@latest-7
RUN pnpm install

RUN pnpm exec bazelisk build --sandbox_debug --remote_cache=${REMOTE_CACHE_URL} --remote_cache_compression -c opt //src/workerd/server:workerd

FROM scratch as artifact
COPY --from=builder /workerd/bazel-bin/src/workerd/server/workerd /usr/bin/workerd

FROM debian:bullseye-slim
COPY --from=builder /workerd/bazel-bin/src/workerd/server/workerd /usr/bin/workerd
ENTRYPOINT ["/usr/bin/workerd"]