#!/bin/bash

set -eo pipefail

if [[ "$1" == apache2* ]]; then
	if [[ "$APP_ENV" != "local" ]]; then
		cp -fR /usr/src/app/. /var/www/html

		chgrp -R www-data /var/www/html
		chmod -R ug+rwx /var/www/html/storage /var/www/html/bootstrap/cache

		composer install --no-interaction --prefer-dist --profile --optimize-autoloader

		if [ ! -d "node_modules" ]; then
			npm install
			gulp --production
		fi

		php artisan migrate
	else
		# Cheat our way through unavailable postgresql
		sleep 10
		php artisan migrate:refresh --seed
	fi
fi

exec "$@"
