# DockerShellScript

DESENVOLVIMENTO DO SCRIPT
	Os scripts desenvolvidos para o seguinte trabalho foram divididos em 6 diferentes funções: 
Script inicial: é aquele que vai dar início aos contêineres garantindo a base para o funcionamento do experimento;
Dockerfiles: comandos que irão garantir o início dos contêineres e seus serviços;
NGINX: Serviço para realizar o controle das páginas web;
RABBITMQS: Utilizado para enviar e receber mensagens entre sistemas, facilitando a comunicação entre diferentes componentes de uma aplicação e serviços
REDIS: Sistema de gerenciamento de banco de dados em memória, open-source, que pode ser usado como banco de dados;
MYSQL: A própria aplicação do banco de dados, onde todas as informações serão armazenadas.

Sendo assim, abaixo estão elencados os scripts utilizados para a realização do experimento conforme proposto.

O objetivo central deste projeto é simplificar e padronizar a configuração dos ambientes mencionados, assegurando que cada um utilize portas específicas para o serviço NGINX: 8080 e 8090 para desenvolvimento, 8081 e 8091 para teste, e 8082 e 8092 para produção. Para alcançar este objetivo, serão desenvolvidos Dockerfiles customizados baseados no Ubuntu 22.04, abrangendo diversos serviços essenciais como NGINX, Apache, MySQL, RabbitMQ e Redis.
Além disso, será criado um script em shell que automatize a criação e configuração dos containers, garantindo a correta mapeamento das portas de acesso e a conexão de cada ambiente a uma rede separada: net-dev (desenvolvimento), net-test (teste) e net-prod (produção). A documentação detalhada dos scripts e das etapas de configuração realizadas também será elaborada, assegurando a clareza e a reprodutibilidade do processo.

