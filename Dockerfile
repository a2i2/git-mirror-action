FROM alpine

RUN apk add --no-cache git openssh-client

# Ensure SSH uses container's OpenSSL libraries
ENV LD_LIBRARY_PATH=/usr/lib:/lib

ADD *.sh /

ENTRYPOINT ["/debug.sh"]
