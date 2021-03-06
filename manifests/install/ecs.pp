class aws::install::ecs {
  class { 'docker':
    manage_kernel => false,
    docker_users => ['ubuntu']
  }
  
  if($aws::bootstrap::ecs_docker_host != "" and $aws::bootstrap::ecs_docker_host != nil){
    docker::registry { $aws::bootstrap::ecs_docker_host:
      username => $aws::bootstrap::ecs_docker_username,
      password => $aws::bootstrap::ecs_docker_password,
      email    => $aws::bootstrap::ecs_docker_email,
      before   => Docker::Run['ecs-agent']
    }
    $auth_data = join([
      "ECS_ENGINE_AUTH_DATA={\\\"${aws::bootstrap::ecs_docker_host}\\\":{",
      "\\\"username\\\":\\\"${aws::bootstrap::ecs_docker_username}\\\",",
      "\\\"password\\\":\\\"${aws::bootstrap::ecs_docker_password}\\\",",
      "\\\"email\\\":\\\"${aws::bootstrap::ecs_docker_email}\\\"}}"
    ], "")

  }
  else {
    $auth_data = 'ECS_ENGINE_AUTH_DATA={}'
  }
  
  docker::run { 'ecs-agent':
    image   => 'amazon/amazon-ecs-agent:latest',
    ports => ['51678', '51678'],
    expose => ['51678', '51678'],
    volumes => [
      "/var/run/docker.sock:/var/run/docker.sock",
      "/var/log/ecs/:/log",
      "/var/lib/ecs/data:/data"
    ],
    env => [
      "ECS_LOGFILE=/log/ecs-agent.log",
      "ECS_LOGLEVEL=info",
      "ECS_DATADIR=/data",
      "ECS_CLUSTER=${aws::bootstrap::ecs_cluster_name}",
      "ECS_ENGINE_AUTH_TYPE=docker",
      $auth_data
    ],
    require => Class['docker']
  }
}