FROM rust:slim-bullseye
RUN rustup target add wasm32-wasi

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
    apt-get install -qq --no-install-recommends -y make curl git libxml2 && \
    rm -rf /var/lib/apt/lists/*

# install nodejs
RUN curl -sL https://deb.nodesource.com/setup_18.x  | bash -
RUN apt-get -qq -y install nodejs

WORKDIR /workers-wasi

CMD ["make", "-j", "test"]
