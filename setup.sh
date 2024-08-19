#!/bin/bash

# Função para criar rede se não existir
create_network() {
	local network_name=$1
	if ! docker network ls --filter name=^${network_name}$ --format="{{ .Name }}" | grep -w ${network_name} > /dev/null; then
    	docker network create --driver bridge ${network_name}
	fi
}

# Criar redes
create_network net-dev
create_network net-test
create_network net-prod

# Função para construir a imagem Docker
build_image() {
	local image_name=$1
	local dockerfile=$2
	docker build -t ${image_name} -f ${dockerfile} .
}

# Função para criar e rodar o contêiner
run_container() {
	local container_name=$1
	local network_name=$2
	local port_mappings=$3
	local image_name=$4
	local volume_mapping=$5

	# Remover contêiner existente se houver
	if [ "$(docker ps -aq -f name=${container_name})" ]; then
    	docker rm -f ${container_name}
	fi

	# Rodar o contêiner
	docker run -d --name ${container_name} --network ${network_name} ${port_mappings} ${volume_mapping} ${image_name}
}

# Função para criar página web
create_web_page() {
	local container_name=$1
	local service_name=$2

	# Criar página HTML
	echo "<!DOCTYPE html>
<html>
<head>
	<title>Servidor Web</title>
</head>
<body>
	<h1>${service_name}</h1>
</body>
</html>" > /tmp/index.html

	# Copiar página HTML para o contêiner
	docker cp /tmp/index.html ${container_name}:/var/www/html/index.html
}

# Construir imagens
build_image nginx Dockerfile.nginx
build_image apache Dockerfile.apache
build_image mysql Dockerfile.mysql
build_image rabbitmq Dockerfile.rabbitmq
build_image redis Dockerfile.redis

# Rodar contêineres NGINX para cada ambiente
run_container nginx-dev net-dev "-p 8080:80 -p 8090:443" nginx ""
run_container nginx-test net-test "-p 8081:80 -p 8091:443" nginx ""
run_container nginx-prod net-prod "-p 8082:80 -p 8092:443" nginx ""

# Rodar contêineres Apache para cada ambiente (web1 e web2)
run_container apache1dev net-dev "-p 8083:80" apache ""
create_web_page apache1dev "Service Dev 1"

run_container apache1test net-test "-p 8084:80" apache ""
create_web_page apache1test "Service Test 1"

run_container apache1prod net-prod "-p 8085:80" apache ""
create_web_page apache1prod "Service Prod 1"

run_container apache2dev net-dev "-p 8086:80" apache ""
create_web_page apache2dev "Service Dev 2"

run_container apache2test net-test "-p 8087:80" apache ""
create_web_page apache2test "Service Test 2"

run_container apache2prod net-prod "-p 8088:80" apache ""
create_web_page apache2prod "Service Prod 2"

# Rodar contêineres MySQL para cada ambiente
run_container mysql-dev net-dev "-p 3306:3306" mysql ""
run_container mysql-test net-test "-p 3307:3306" mysql ""
run_container mysql-prod net-prod "-p 3308:3306" mysql ""

# Rodar contêineres RabbitMQ para cada ambiente
run_container rabbitmq-dev net-dev "-p 5672:5672 -p 15672:15672" rabbitmq ""
run_container rabbitmq-test net-test "-p 5673:5672 -p 15673:15672" rabbitmq ""
run_container rabbitmq-prod net-prod "-p 5674:5672 -p 15674:15672" rabbitmq ""

# Rodar contêineres Redis para cada ambiente
run_container redis-dev net-dev "-p 6379:6379" redis ""
run_container redis-test net-test "-p 6380:6379" redis ""
run_container redis-prod net-prod "-p 6381:6379" redis ""

# Função para configurar nginx.conf
configure_nginx() {
	local container_name=$1
	local backend1=$2
	local backend2=$3

	cat <<EOT > /tmp/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {
	upstream backend {
    	server ${backend1} weight=2;
    	server ${backend2} weight=1;
	}

	server {
    	listen 80;
    	location / {
        	proxy_pass http://backend/;
    	}
	}

	server {
    	listen 443;
   	 
    location / {
        	proxy_pass http://backend/;
     	}
	}
}
EOT

	docker cp /tmp/nginx.conf ${container_name}:/etc/nginx/nginx.conf
	docker exec ${container_name} nginx -s reload
}

# Obter IP dos contêineres Apache
dev1_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' apache1dev)
dev2_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' apache2dev)

test1_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' apache1test)
test2_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' apache2test)

prod1_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' apache1prod)
prod2_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' apache2prod)

# Configurar nginx.conf para cada ambiente
configure_nginx nginx-dev ${dev1_ip} ${dev2_ip}
configure_nginx nginx-test ${test1_ip} ${test2_ip}
configure_nginx nginx-prod ${prod1_ip} ${prod2_ip}

configure_mysql() {
	local container_name=$1
	local user_host1=$2
	local user_host2=$3

	docker exec ${container_name} mysql -u root -e "CREATE USER 'root'@'${user_host1}' IDENTIFIED BY 'bd';"
	docker exec ${container_name} mysql -u root -e "CREATE USER 'root'@'${user_host2}' IDENTIFIED BY 'bd';"
	docker exec ${container_name} mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'${user_host1}' WITH GRANT OPTION;"
	docker exec ${container_name} mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'${user_host2}' WITH GRANT OPTION;"
	docker exec ${container_name} mysql -u root -e "FLUSH PRIVILEGES;"
}

# Configurar MySQL para ambientes de teste e produção
configure_mysql mysql-test ${test1_ip} ${test2_ip}
configure_mysql mysql-prod ${prod1_ip} ${prod2_ip}
configure_mysql mysql-dev  ${dev1_ip} ${dev2_ip}

echo "Contêineres configurados e rodando para desenvolvimento, teste e produção."
