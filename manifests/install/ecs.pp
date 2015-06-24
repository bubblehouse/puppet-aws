class aws::install::ecs($cluster_name) {
  class { 'docker':
    manage_kernel => false,
    docker_users => ['ubuntu']
  }
  
  docker::run { 'ecs-agent':
    image   => 'amazon/amazon-ecs-agent:latest',
    ports => ['51678', '51678'],
    expose => ['51678', '51678'],
    volumes => [
      "/var/run/docker.sock:/var/run/docker.sock"
      "/var/log/ecs/:/log"
      "/var/lib/ecs/data:/data"
    ],
    env => [
      "ECS_LOGFILE=/log/ecs-agent.log"
      "ECS_LOGLEVEL=info"
      "ECS_DATADIR=/data"
      "ECS_CLUSTER=${cluster_name}"
    ]
  }
}