#!/bin/bash

set -e

curl -LsS https://packages.blackfire.io/gpg.key | apt-key add -
echo "deb http://packages.blackfire.io/debian any main" > /etc/apt/sources.list.d/blackfire.list

apt-get update
#apt-get install -y php${DW_PHP_VERSION}-xdebug php${DW_PHP_VERSION}-tideways git blackfire-php
# no tideways yet for php 8
apt-get install -y php${DW_PHP_VERSION}-xdebug git blackfire-php
apt-get clean -y
curl -LsS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/local/lib --filename=composer
[[ -e /usr/local/lib/composer ]] || false && true
# compat composer version for older versions
curl -LsS https://getcomposer.org/installer | \
    php -- --1 --install-dir=/usr/local/lib --filename=composer1
[[ -e /usr/local/lib/composer1 ]] || false && true

(
    cd /usr/lib/php/$(php -i | grep ^extension_dir | sed -e 's/.*\/\([0-9]*\).*/\1/')
    curl -O https://raw.githubusercontent.com/tideways/profiler/master/Tideways.php
    [[ -e Tideways.php ]] || false && true
)

printf "xdebug.mode = develop,debug\nxdebug.discover_client_host = 1\nxdebug.max_nesting_level=400\n" \
    >> /etc/php/${DW_PHP_VERSION}/mods-available/xdebug.ini

if [[ -e /etc/php/${DW_PHP_VERSION}/mods-available/tideways.ini ]]; then
    cp -a /etc/php/${DW_PHP_VERSION}/mods-available/tideways.ini \
        /etc/php/${DW_PHP_VERSION}/mods-available/xhprof.ini

    printf "auto_prepend_file=/usr/share/xhprof/prepend.php\n" \
        >> /etc/php/${DW_PHP_VERSION}/mods-available/xhprof.ini

    printf "tideways.udp_connection=\"tideways:8135\"\ntideways.connection=\"tcp://tideways:9135\"\ntideways.monitor_cli=1\n" \
        >> /etc/php/${DW_PHP_VERSION}/mods-available/tideways.ini
    printf "auto_prepend_file=/usr/share/tideways/prepend.php\n" \
        >> /etc/php/${DW_PHP_VERSION}/mods-available/tideways.ini
fi

if [[ -e /etc/php/${DW_PHP_VERSION}/mods-available/blackfire.ini ]]; then
    sed -e 's#\(blackfire.agent_socket\).*#\1=tcp://blackfire:8707#' \
        -i /etc/php/${DW_PHP_VERSION}/mods-available/blackfire.ini
fi

phpdismod xdebug
phpdismod tideways
phpdismod blackfire
