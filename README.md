# wordpress-docker-factory

This project provides set of commands that allows creating and running multiple production-ready Docker-isolated Wordpress sites on a Linux server.

All the sites use the same shared MySQL server, that runs on host environment (not dockerized), and there's single web server (Apache or Nginx) that forwards requests to the Wordpress containers.

Containers have access to TCP services running on the host environment, but cannot read files of each other, and cannot execute PHP scripts of each other.

Each container is running PHP-FPM service. Applications on the host environment do can connect to the PHP-FPM of any site and execute their PHP scripts.

All the Wordpress files are mapped to the host filesystem, making it easy for server administrators to access them.

## System requirements

1. Linux server environment with `bash`, `perl`, `tput`, `cksum`, `cut`, `id` and `envsubst` commands. `Ubuntu` and `Amazon Linux` are OK.
2. GNU make
3. Docker and Docker Compose
4. Web server, either Apache2 or Nginx
5. MySQL server and command-line client

## Creating and running Wordpress sites

1. Run either Apache2 or Nginx web server on the host environment.
2. Make sure that SSL and HTTP/2 features are enabled on your www server.
3. Run MySQL server that listens on `0.0.0.0:3306`.
4. Copy this project directory to the server (e.g. to `/var/www/wordpress-docker-factory`).
5. Choose domain name for the site. I'll use `example.com`. Running commands with different domain name will install another container.

6. Configure your site by running the following command:

```bash
sudo make setup DOMAIN="example.com" DB_ROOT_USER="root"
```

The `DB_ROOT_USER` argument is optional, and defaults to `root`.

The above command creates directory called `www/example.com` that will hold all the wordpress files.

It also generates Apache and Nginx configuration files, and offers you to symlink or copy them to your web server configuration directory (like `/etc/apache2/sites-available/`, `/etc/nginx/sites-available`, `/etc/httpd/conf.d`, `/etc/nginx/conf.d/`, ...).

Also this command tells you where to put SSL certificates for the site.

Then this command creates or alters MySQL user. User name matches site name with all non-alphanumeric chars substituted with `_` (e.g. `example_com`).
Also this creates database with the same name, and grants all privileges on this database to the site user.

7. Start the container.

For production-mode container do:

```bash
make apache-up DOMAIN="example.com"
# OR:
make nginx-up DOMAIN="example.com"
```

For development-mode container, that includes XDebug do:

```bash
make apache-up-dev DOMAIN="example.com"
# OR:
make nginx-up-dev DOMAIN="example.com"
```

8. The site is ready on `https://example.com/`.

9. The container will run from now on, even after server restart. You can see it running in the

```bash
docker ps
```

To stop the container, do:

```bash
make down DOMAIN="example.com"
```

10. To deploy another wordpress site, repeat the process with different value for the DOMAIN variable.

## PHP configuration

Configuration files are in `conf` directory. They're applied to each site container.
Also each container has it's own configuration override files in `www/$DOMAIN` directory.

When running in production-mode (started through `make apache-up`), `conf/www.conf-production` and `conf/php.ini-production` are used.

When running in development-mode (started through `make apache-up-dev`), `conf/www.conf-development` and `conf/php.ini-development` are used.

Setting `pm.max_children = 10` in `conf/www.conf-production` will result in having at most 10 PHP processes per container, so with 5 containers there can be 50 processes.

## Debugging

When running a container in development-mode, it will connect to PHP debugger on the host environment to port `9003` (you can change it in `conf/xdebug.ini`).

For VSCode debugger, this project includes `.vscode/launch.json`.

## Design and limitations

By design, you only provide `DOMAIN` variable to commands in this project, and all the other things are derived from it.

Database name will match `DOMAIN` with all non-alphanumeric chars substituted with `_`.
MySQL user name will be the same as database name.

Also each site container is a service listening on some port, mapped to the host environment, and this port number is also derived from `DOMAIN`.
It's a number in range from `10_000` to `0xBFFF`, that is based on CRC hash of the `DOMAIN` name.

One consequence is that this port number can conflict with other open ports on the system.
