ARG BUILDPLATFORM
FROM --platform=$BUILDPLATFORM golang:1.23.4-alpine AS buildstage
ARG TARGETPLATFORM

RUN apk update --no-cache && apk add make gcc git curl

# Enable go modules
ENV GO111MODULE=on
ENV GOPATH=/go

# Build ipmi_exporter
WORKDIR /$GOPATH/src/github.com/platinasystems/ipmi_exporter
COPY . .
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        make precheck style unused build DOCKER_ARCHS=arm64; \
    else \
        make precheck style unused build DOCKER_ARCHS=amd64; \
    fi
RUN mv ipmi_exporter /

# Copy the ipmi_exporter binary
FROM alpine:3
RUN apk --no-cache add freeipmi
LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"
WORKDIR /
COPY --from=buildstage /ipmi_exporter /

EXPOSE      9290
USER        nobody
ENTRYPOINT  [ "/ipmi_exporter" ]