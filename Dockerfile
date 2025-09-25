FROM alpine

RUN apk update && apk add --no-cache git openssh-client libssl3 libcrypto3

ADD *.sh /

ENTRYPOINT ["/debug.sh"]
