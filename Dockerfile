# ---- Stage 1: Dependencies ----
# Downloads all Go module dependencies into the module cache. This stage only
# depends on go.mod/go.sum, so its layer is reused by Docker until a real
# dependency change. The build stage below starts from this fully populated
# cache and only fetches newly added dependencies.
FROM golang:1-alpine3.24 AS deps

RUN apk add --no-cache git ca-certificates

WORKDIR /src

COPY mautrix_go/go.mod ./mautrix_go/go.mod
COPY mautrix_go/go.sum ./mautrix_go/go.sum
COPY mautrix_telegram/go.mod ./telegram/go.mod
COPY mautrix_telegram/go.sum ./telegram/go.sum

WORKDIR /src/telegram

RUN go mod download

# ---- Stage 2: Build ----
FROM golang:1-alpine3.24 AS builder

RUN apk add --no-cache git ca-certificates build-base olm-dev

WORKDIR /src

COPY --from=deps /go/pkg/mod /go/pkg/mod

COPY mautrix_go/ ./mautrix_go/
COPY mautrix_telegram/ ./telegram/

WORKDIR /src/telegram

RUN go build -trimpath \
    -ldflags "-s -w -X main.Tag=$(git describe --tags --always 2>/dev/null || echo v0.2608.0) \
              -X main.Commit=$(git rev-parse --short HEAD 2>/dev/null || echo unknown) \
              -X main.BuildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -o /out/mautrix-telegram \
    ./cmd/mautrix-telegram

# ---- Stage 3: Runtime ----
FROM alpine:3.24

ENV UID=1337 GID=1337

RUN apk add --no-cache \
    bash ca-certificates curl jq \
    ffmpeg olm su-exec yq-go lottieconverter \
    procps net-tools iproute2 tcpdump bind-tools \
    && rm -rf /var/cache/apk/*

COPY --from=builder /out/mautrix-telegram /usr/bin/mautrix-telegram
COPY mautrix_telegram/docker-run.sh /docker-run.sh
RUN chmod +x /docker-run.sh

VOLUME /data
EXPOSE 29317

CMD ["/docker-run.sh"]
