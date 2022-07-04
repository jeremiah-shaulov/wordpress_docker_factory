FROM wordpress:fpm as production

ARG USER_ID=33
ARG GROUP_ID=33
ARG DOMAIN

WORKDIR /var/www/$DOMAIN/html

RUN groupmod -g $GROUP_ID www-data && \
	usermod -u $USER_ID www-data && \
	chown www-data: .


FROM production as development

# Install xdebug
RUN pecl install xdebug \
	docker-php-ext-enable xdebug
