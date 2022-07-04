<VirtualHost *:80>
	ServerName $DOMAIN
	DocumentRoot $PWD/www/$DOMAIN/html

	SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1

	<Directory $PWD/www/$DOMAIN/html>
		AllowOverride All
		Require all granted
		DirectoryIndex index.html index.php

		<FilesMatch \.php$>
			SetHandler "proxy:fcgi://127.0.0.1:$PHP_FPM_PORT"
			ProxyFCGISetEnvIf "reqenv('SCRIPT_FILENAME') =~ m|$PWD/www/$DOMAIN/html(.*)|" SCRIPT_FILENAME "/var/www/$DOMAIN/html$1"
		</FilesMatch>
	</Directory>
</VirtualHost>

<VirtualHost *:443>
	ServerName $DOMAIN
	DocumentRoot $PWD/www/$DOMAIN/html
	Protocols h2 http/1.1

	SSLEngine on
	SSLCertificateFile      /etc/ssl/private/$DOMAIN.crt
	SSLCertificateKeyFile   /etc/ssl/private/$DOMAIN.key
	SSLCertificateChainFile /etc/ssl/private/$DOMAIN.chain.crt

	SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1

	<Directory $PWD/www/$DOMAIN/html>
		AllowOverride All
		Require all granted
		DirectoryIndex index.html index.php

		<FilesMatch \.php$>
			SetHandler "proxy:fcgi://127.0.0.1:$PHP_FPM_PORT"
			ProxyFCGISetEnvIf "reqenv('SCRIPT_FILENAME') =~ m|$PWD/www/$DOMAIN/html(.*)|" SCRIPT_FILENAME "/var/www/$DOMAIN/html$1"
		</FilesMatch>
	</Directory>
</VirtualHost>
