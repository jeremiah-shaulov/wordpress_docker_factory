# Parameters that can be overriden: DOMAIN - on what site do operate; DB_ROOT_USER - use this admin MySQL user to setup a new database;
DOMAIN ?=
DB_ROOT_USER ?= root

# Variables derived from DOMAIN and TRY_USER_NAME (that must be set later with "eval")
DB_NAME := $(shell echo "$(DOMAIN)" | perl -pe 's/^\s*|\s*$$//g;  s/\W/_/g')
PHP_FPM_PORT := $(shell bash -c 'echo $$(( 10000 + $$(echo "$(DB_NAME)" | cksum /dev/stdin | cut -d " " -f 1) % (0xBFFF - 10000) ))')
USER_NAME = $(shell id -u "$(TRY_USER_NAME)" 1>/dev/null 2>&1 && echo "$(TRY_USER_NAME)" || echo www-data)
USER_ID = $(shell id -u "$(USER_NAME)" 2>/dev/null || id -u www-data 2>/dev/null || echo 33)
GROUP_ID = $(shell id -g "$(USER_NAME)" 2>/dev/null || id -g www-data 2>/dev/null || echo 33)

# PASS_ENV (all the env vars to pass to docker compose) and DOCKER_COMPOSE (either "docker compose" or "docker-compose")
PASS_ENV = DOMAIN="$(DOMAIN)" DB_NAME="$(DB_NAME)" PHP_FPM_PORT="$(PHP_FPM_PORT)" USER_NAME="$(USER_NAME)" USER_ID="$(USER_ID)" GROUP_ID="$(GROUP_ID)"
DOCKER_COMPOSE = $(shell docker compose version 1>/dev/null 2>&1 && echo 'docker compose' || echo 'docker-compose')


.PHONY : _require_root  _require_domain  apache-build  apache-build-dev  apache-up  apache-up-dev  nginx-build  nginx-build-dev  nginx-up  nginx-up-dev  down  setup


# Fail if not running as root
_require_root :
	@test "$$(id -u)" = 0 || (echo "$$(tput setaf 1)Please, run as root$$(tput sgr0)" && false)

# Fail if DOMAIN is not set
_require_domain :
	@test ! -z "$(DOMAIN)" || (echo "DOMAIN environment variable is not set" && false)


apache-build : _require_domain
	$(DOCKER_COMPOSE) -f "www/$(DOMAIN)/docker-compose.apache.yaml" build

apache-build-dev : _require_domain
	$(DOCKER_COMPOSE) -f "www/$(DOMAIN)/docker-compose.apache.dev.yaml" build

apache-up : _require_domain
	$(DOCKER_COMPOSE) -f "www/$(DOMAIN)/docker-compose.apache.yaml" up -d

apache-up-dev : _require_domain
	$(DOCKER_COMPOSE) -f "www/$(DOMAIN)/docker-compose.apache.dev.yaml" up -d

nginx-build : _require_domain
	$(DOCKER_COMPOSE) -f "www/$(DOMAIN)/docker-compose.nginx.yaml" build

nginx-build-dev : _require_domain
	$(DOCKER_COMPOSE) -f "www/$(DOMAIN)/docker-compose.nginx.dev.yaml" build

nginx-up : _require_domain
	$(DOCKER_COMPOSE) -f "www/$(DOMAIN)/docker-compose.nginx.yaml" up -d

nginx-up-dev : _require_domain
	$(DOCKER_COMPOSE) -f "www/$(DOMAIN)/docker-compose.nginx.dev.yaml" up -d

down : _require_domain
	$(DOCKER_COMPOSE) -f "www/$(DOMAIN)/docker-compose.apache.yaml" down

setup : _require_root  _require_domain
	@#Create "www/DOMAIN/html", "www/DOMAIN/secrets", "www/DOMAIN/www.conf", "www/DOMAIN/php.ini"
	@mkdir -p "www/$(DOMAIN)/html"
	@mkdir -p "www/$(DOMAIN)/secrets"
	@test -f "www/$(DOMAIN)"/www.conf || mkdir -p "www/$(DOMAIN)" && echo '[www]' | tee "www/$(DOMAIN)"/www.conf > /dev/null
	@test -f "www/$(DOMAIN)"/php.ini || mkdir -p "www/$(DOMAIN)" && echo '[PHP]' | tee "www/$(DOMAIN)"/php.ini > /dev/null

	$(eval TRY_USER_NAME=apache)
	@$(PASS_ENV) TARGET=production TAG=latest MORE_VOLUMES="" envsubst < docker-compose.yaml.tpl | tee "www/$(DOMAIN)/docker-compose.$(TRY_USER_NAME).yaml" > /dev/null
	@$(PASS_ENV) TARGET=development TAG=dev MORE_VOLUMES="- ../../conf/xdebug.ini:/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" envsubst < docker-compose.yaml.tpl | tee "www/$(DOMAIN)/docker-compose.$(TRY_USER_NAME).dev.yaml" > /dev/null
	@$(PASS_ENV) envsubst '$$PWD $$DOMAIN $$PHP_FPM_PORT' < "$(TRY_USER_NAME).conf.tpl" | tee "www/$(DOMAIN)/$(DOMAIN).$(TRY_USER_NAME).conf" > /dev/null

	$(eval TRY_USER_NAME=nginx)
	@$(PASS_ENV) TARGET=production TAG=latest MORE_VOLUMES="" envsubst < docker-compose.yaml.tpl | tee "www/$(DOMAIN)/docker-compose.$(TRY_USER_NAME).yaml" > /dev/null
	@$(PASS_ENV) TARGET=development TAG=dev MORE_VOLUMES="- ../../conf/xdebug.ini:/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" envsubst < docker-compose.yaml.tpl | tee "www/$(DOMAIN)/docker-compose.$(TRY_USER_NAME).dev.yaml" > /dev/null
	@$(PASS_ENV) envsubst '$$PWD $$DOMAIN $$PHP_FPM_PORT' < "$(TRY_USER_NAME).conf.tpl" | tee "www/$(DOMAIN)/$(DOMAIN).$(TRY_USER_NAME).conf" > /dev/null

	@echo "1. I created Apache and Nginx configuration files:"
	@echo "  $$(tput bold)www/$(DOMAIN)/$(DOMAIN).apache.conf$$(tput sgr0)"
	@echo "  $$(tput bold)www/$(DOMAIN)/$(DOMAIN).nginx.conf$$(tput sgr0)"
	@echo "Please, symlink or copy one of them (depending on what www server you're using, or both) to your sites configuration directory (like sites-available or conf.d)"
	@echo "2. Make sure that SSL feature is enabled on your www server. Then put your site certificates to /etc/ssl/private."
	@echo "For Apache:"
	@echo "  $$(tput bold)/etc/ssl/private/$(DOMAIN).key$$(tput sgr0) (private key)"
	@echo "  $$(tput bold)/etc/ssl/private/$(DOMAIN).crt$$(tput sgr0) (public key)"
	@echo "  $$(tput bold)/etc/ssl/private/$(DOMAIN).chain.crt$$(tput sgr0) (chain)"
	@echo "For Nginx:"
	@echo "  $$(tput bold)/etc/ssl/private/$(DOMAIN).key$$(tput sgr0) (private key)"
	@echo "  $$(tput bold)/etc/ssl/private/$(DOMAIN).pub$$(tput sgr0) (concatenation of public key and optional chain)"
	@echo "3. Please run the following command to make sure that this directory is readable by www server:"
	@echo "For Apache:"
	$(eval TRY_USER_NAME=apache)
	@echo "  $$(tput bold)sudo -u $$(echo "$(USER_NAME)") stat "www/$(DOMAIN)" > /dev/null && echo 'ok'$$(tput sgr0)"
	@echo "For Nginx:"
	$(eval TRY_USER_NAME=nginx)
	@echo "  $$(tput bold)sudo -u $$(echo "$(USER_NAME)") stat "www/$(DOMAIN)" > /dev/null && echo 'ok'$$(tput sgr0)"
	@echo "4. Let's create or alter MySQL user $$(tput bold)$(DB_NAME)$$(tput sgr0) and create database $$(tput bold)$(DB_NAME)$$(tput sgr0) on localhost:3306"
	
	@stty -echo  ;\
	read -p "Enter new password for $(DB_NAME) - empty to bypass> " PASS  ;\
	stty echo  ;\
	echo  ;\
	if test -z "$$PASS"  ;\
	then  \
		echo "Empty password. Not updating the user."  ;\
	else  \
		stty -echo  ;\
		read -p "Repeat please> " PASS2  ;\
		stty echo  ;\
		echo  ;\
		if test "$$PASS" != "$$PASS2"  ;\
		then  \
			echo "$$(tput setaf 1)Passwords don't match. Not updating the user.$$(tput sgr0)"  ;\
		else  \
			echo "Please, enter MySQL password for $$(tput bold)$(DB_ROOT_USER)$$(tput sgr0)"  ;\
			mysql -u "$(DB_ROOT_USER)" -p --execute="  \
				CREATE USER IF NOT EXISTS \`$(DB_NAME)\`@\`%\` IDENTIFIED BY '$$PASS';  \
				ALTER USER \`$(DB_NAME)\`@\`%\` IDENTIFIED BY '$$PASS';  \
				CREATE DATABASE IF NOT EXISTS \`$(DB_NAME)\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT ENCRYPTION='N';  \
				GRANT ALL ON \`$(DB_NAME)\`.* TO \`$(DB_NAME)\`@\`%\`;  \
			"  ;\
			if test "$$?" = 0  ;\
			then  \
				echo "$$(tput setaf 2)User and database updated successfully$$(tput sgr0)"  ;\
				echo "$$PASS" | tee "www/$(DOMAIN)/secrets/db_password" > /dev/null  ;\
				if test "$$?" = 0  ;\
				then  \
					echo "$$(tput setaf 2)Password stored to www/$(DOMAIN)/secrets/db_password$$(tput sgr0)"  ;\
				fi  ;\
			fi  ;\
		fi  ;\
	fi 
