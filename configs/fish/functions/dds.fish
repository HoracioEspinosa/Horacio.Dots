function dds --description "Disable Docker restart policy on all running containers"
    docker ps -q | xargs -I {} docker update --restart=no {}
end
