#!/bin/bash

set -eo pipefail

if [[ "$1" == apache2* ]]; then
		cp -fR /usr/src/app/. /var/www/html

		chgrp -R www-data /var/www/html
		chmod -R ug+rwx /var/www/html/storage /var/www/html/bootstrap/cache

		php artisan migrate
fi

exec "$@"
