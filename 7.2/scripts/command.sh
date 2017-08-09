#!/bin/bash

/prepare.sh

if [ "php-fpm7.2" != "$1" ] && [ "/bin/bash" != "$1" ]; then
    exec gosu www-data "$@"
else
    if [ "php-fpm7.2" == "$1" ]; then
        touch /.checkfpm
    fi
    exec "$@"
fi