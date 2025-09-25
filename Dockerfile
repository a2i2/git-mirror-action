FROM alpine

RUN apk update && apk add --no-cache git openssh-client libssl3 libcrypto3

# Ensure SSH uses container's OpenSSL libraries
ENV LD_LIBRARY_PATH=/usr/lib:/lib

ADD *.sh /

ENTRYPOINT ["/debug.sh"]
