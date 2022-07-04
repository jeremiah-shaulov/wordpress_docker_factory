# Redirect to docker.
server
{	server_name $DOMAIN;
	root $PWD/www/$DOMAIN/html;

	listen 80;
	listen [::1]:80;
	listen 443 ssl http2;
	listen [::1]:443 ssl http2;

	ssl_certificate /etc/ssl/private/$DOMAIN.pub;
	ssl_certificate_key /etc/ssl/private/$DOMAIN.key;

	index index.php index.html;
	error_page 404 /404.html;
	error_page 500 502 503 504 /50x.html;

	location /
	{	try_files $uri $uri/ =404;
	}

	location ~ \.php$
	{	fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass 127.0.0.1:$PHP_FPM_PORT;
		fastcgi_index index.php;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME /var/www/$DOMAIN/html/$fastcgi_script_name;
		fastcgi_param SCRIPT_NAME $fastcgi_script_name;
	}

	location ~ /\.
	{	deny all;
	}
}
