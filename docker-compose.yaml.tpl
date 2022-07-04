version: "3.7"

services:

  $DB_NAME:
    build:
      context: ../..
      target: $TARGET
      args:
        - USER_ID=$USER_ID
        - GROUP_ID=$GROUP_ID
        - DOMAIN=$DOMAIN
    image: wordpress-docker-factory-$USER_NAME-$DB_NAME:$TAG
    container_name: $DB_NAME
    environment:
      WORDPRESS_DB_HOST: host.docker.internal:3306
      WORDPRESS_DB_PASSWORD_FILE: /run/secrets/db_password
      WORDPRESS_DB_USER: $DB_NAME
      WORDPRESS_DB_NAME: $DB_NAME
      WORDPRESS_DB_CHARSET: utf8
      WORDPRESS_DB_COLLATE: utf8mb4_unicode_ci
    restart: always
    volumes:
      - ../../conf/www.conf-$TARGET:/usr/local/etc/php-fpm.d/www.conf
      - ../../conf/php.ini-$TARGET:/usr/local/etc/php/php.ini
      - ./www.conf:/usr/local/etc/php-fpm.d/www2.conf
      - ./php.ini:/usr/local/etc/php/conf.d/php2.ini
      - ./html:/var/www/$DOMAIN/html
      $MORE_VOLUMES
    secrets:
      - db_password
    ports:
      - 127.0.0.1:$PHP_FPM_PORT:9000
    extra_hosts:
      - host.docker.internal:host-gateway

secrets:
  db_password:
    file: ./secrets/db_password

networks:
  default:
    name: $DB_NAME
