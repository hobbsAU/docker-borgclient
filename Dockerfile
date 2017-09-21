FROM alpine:edge
MAINTAINER Adrian Hobbs <adrianhobbs@gmail.com>
ENV PACKAGE "borgbackup"

# Install package using --no-cache to update index and remove unwanted files
RUN 	apk add --no-cache $PACKAGE && \

CMD ["borg"]

