FROM php:7-apache
MAINTAINER Lloyd Nanka <lloyd.nanka@peopleplan.com.au>

# Swap out sh for bash (this is required for nvm)
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install PHP extensions
RUN set -xe \
	&& apt-get update \
	&& apt-get install -y \
		git \
		libicu-dev \
		libpq-dev \
		libmcrypt-dev \
	&& apt-get clean \
	&& rm -r /var/lib/apt/lists/* \
	&& docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
	&& docker-php-ext-install \
		intl \
		mbstring \
		mcrypt \
		pcntl \
		pdo_mysql \
		pdo_pgsql \
		pgsql \
		zip \
		opcache

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Install Node.js
ENV NVM_DIR /usr/local/.nvm
ENV NODE_VERSION 5.10.1

RUN git clone https://github.com/creationix/nvm.git $NVM_DIR \
	&& cd $NVM_DIR \
	&& git checkout `git describe --abbrev=0 --tags`

# Install default version of Node.js
RUN source $NVM_DIR/nvm.sh \
	&& nvm install $NODE_VERSION \
	&& nvm alias default $NODE_VERSION \
	&& nvm use default

RUN echo "source ${NVM_DIR}/nvm.sh" > $HOME/.bashrc \
	&& source $HOME/.bashrc \
	&& npm install --global gulp-cli

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Put apache config for Laravel
#COPY apache2-laravel.conf /etc/apache2/sites-available/laravel.conf
#RUN a2dissite 000-default.conf && a2ensite laravel.conf && a2enmod rewrite

# Mount docker-entrypoint script
COPY docker-entrypoint.sh /entrypoint.sh

# RUN composer install && npm install && gulp --production

# Change uid and gid of apache to docker user uid/gid
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

COPY . /usr/src/app

WORKDIR /usr/src/app
RUN composer install --no-interaction --prefer-dist --profile --optimize-autoloader && npm rebuild node-sass && npm install && gulp --production

RUN rm -Rf /usr/src/app/storage/app/public/* && \
	rm -Rf /usr/src/app/storage/framework/cache/* && \
	rm -Rf /usr/src/app/storage/framework/sessions/* && \
	rm -Rf /usr/src/app/storage/framework/views/* && \
	rm -Rf /usr/src/app/bootstrap/cache/* && \
	rm -Rf /usr/src/app/.git

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
