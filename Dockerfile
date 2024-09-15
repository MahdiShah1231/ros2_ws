ARG ROS_VERSION=humble
FROM ros:${ROS_VERSION}
# Need to declare the ARG so it can be used after FROM
ARG ROS_VERSION

ENV ROS_VERSION=${ROS_VERSION}

# Makefile will fill in the value here for username
ARG USERNAME=docker_user
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

ENV USERNAME=${USERNAME}

# Set container shell to bash and dockerfile RUN cmds to use bash
ENV SHELL=/bin/bash
SHELL ["/bin/bash","-c"]

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

WORKDIR /docker_ws/ros2

# RQT takes a while to install, maybe not all of it is needed?
# Maybe just sudo apt install rqt-graph
RUN apt-get update && apt-get install -y \
    gedit \
    dbus-x11 \
    libcanberra-gtk3-module \
    python3-pip \
    wget \
    ros-${ROS_DISTRO}-rviz2 \
    ros-${ROS_DISTRO}-rqt* && \
    rm -rf /var/lib/apt/lists/*

# Source ROS underlay
ENV BASH_PATH=/home/$USERNAME/.bashrc
RUN cat <<EOF >> ${BASH_PATH}
    source /opt/ros/${ROS_DISTRO}/setup.bash
    source /usr/share/colcon_cd/function/colcon_cd.sh
    export _colcon_cd_root=/opt/ros/${ROS_DISTRO}/
    export ROS_DOMAIN_ID=24
    source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash
    alias setup_container='./container_entry.sh'
    alias ws='cd /docker_ws/ros2'
    alias rosdep_install='rosdep install -i --from-path $1 --rosdistro ${ROS_DISTRO} -y'
    alias rsource='source ./install/setup.bash'
    alias cb='rosdep_install ./src && colcon build --symlink-install && rsource'
    alias create_pkg_py='ros2 pkg create --build-type ament_python --dependencies rclpy std_msgs --license Apache-2.0 $1'
    alias create_pkg_cpp='ros2 pkg create --build-type ament_cmake --dependencies rclcpp std_msgs --license Apache-2.0 $1'
    alias ros_clean='rm -r ./build && rm -r ./install && rm -r ./log'
EOF

COPY ./container_entry.sh /
ENTRYPOINT ["/container_entry.sh"]
CMD [ "bash", "-i" ]