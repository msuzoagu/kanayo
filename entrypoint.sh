#!/bin/sh

addgroup -g "$APP_GROUP_ID" "$APP_GROUP"
adduser -u "$APP_USER_ID" "$APP_USER" -D -G "$APP_GROUP" -h "/home/$APP_GROUP"

export HOME="/home/$APP_GROUP"
cd "/home/$APP_GROUP"
exec /usr/local/bin/gosu "$APP_USER" "$@"
