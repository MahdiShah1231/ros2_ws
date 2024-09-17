#!/bin/bash

XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
usage() {
	echo "todo"
}

create_ros2_kobuki_container() {
    docker run $3 \
        --volume=$XSOCK:$XSOCK:rw \
        --volume=$XAUTH:$XAUTH:rw \
        --volume=.:/docker_ws/ros2:rw \
        --env="XAUTHORITY=${XAUTH}" \
        --env="DISPLAY" \
        --user="$1" \
        --name=$CONTAINER_NAME \
        --device=$2:/dev/kobuki \
    $IMAGE_NAME
}

create_ros2_base_container() {

    docker run $2 \
        --volume=$XSOCK:$XSOCK:rw \
        --volume=$XAUTH:$XAUTH:rw \
        --volume=.:/docker_ws/ros2:rw \
        --env="XAUTHORITY=${XAUTH}" \
        --env="DISPLAY" \
        --user="$1" \
        --name=$CONTAINER_NAME \
    $IMAGE_NAME

}


docker_run_flags='-it'
DOCKER_USER="docker_user"
while getopts ":i:u:nd" option; do
    case $option in 
		i)
			IMAGE_NAME="$OPTARG"
			;;
        u)
			DOCKER_USER="$OPTARG"
			;;
        n)
			CONTAINER_NAME="$OPTARG"
			;;
        d)
            docker_run_flags="${docker_run_flags} -d"
            ;;
		*)
			usage
			exit 1
			;;
	esac
done

## TODO get the available users from the docker image
if [[ $IMAGE_NAME == "ros2_docker_kobuki" ]]; then
    devices=(/dev/ttyUSB*)
    for device in ${devices[@]};
        do
            if [[ -n $(udevadm info /dev/ttyUSB0 | grep kobuki) ]]; then
                echo "Found Kobuki at $device"
                break
            fi
        done
    create_ros2_kobuki_container $DOCKER_USER $device $docker_run_flags
elif [[ $IMAGE_NAME == "ros2_docker_base" ]]; then
    create_ros2_base_container $DOCKER_USER $docker_run_flags
else
    echo "Unrecognised image name: $IMAGE_NAME"
fi