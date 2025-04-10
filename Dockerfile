#########################################################################################
# Stage 1: Build & Install Aerostack2
# https://github.com/aerostack2/aerostack2/blob/main/docker/humble/Dockerfile
#########################################################################################

FROM ros:humble-ros-core

WORKDIR /root

######### Install Aerostack2
WORKDIR /root/
RUN apt-get update -y \
    && apt-get install -y \
        apt-utils \
        software-properties-common \
        git \
        tmux \
        tmuxinator \
        python3-rosdep  \
        python3-pip     \
        python3-colcon-common-extensions \
        python3-colcon-mixin \
        ros-dev-tools \
        python3-flake8 \
        python3-flake8-builtins  \
        python3-flake8-comprehensions \
        python3-flake8-docstrings \
        python3-flake8-import-order \
        python3-flake8-quotes \
        cppcheck lcov \
    &&  rm -rf /var/lib/apt/lists/*

RUN pip3 install pylint flake8==4.0.1 pycodestyle==2.8 cmakelint cpplint  colcon-lcov-result PySimpleGUI-4-foss

# RUN colcon mixin update default
# RUN rm -rf log # remove log folder

RUN mkdir -p /root/aerostack2_ws/src/
WORKDIR /root/aerostack2_ws/src/
RUN git clone https://github.com/aerostack2/aerostack2.git aerostack2 -b main --depth=1
RUN git clone https://github.com/aerostack2/as2_platform_pixhawk.git as2_platform_pixhawk -b main --depth=1
RUN git clone https://github.com/PX4/px4_msgs.git px4_msgs -b release/1.14 --depth=1

# Cut down set of deps from rosdep
RUN apt-get update -y\
    && apt-get install -y \
        ros-humble-tf2 \
        ros-humble-tf2-ros \
        ros-humble-sdformat-urdf \
        ros-humble-robot-state-publisher \
        ros-humble-image-transport \
        ros-humble-tf2-msgs \
        ros-humble-cv-bridge \
        python3-jinja2 \
        python3-pydantic \
        libeigen3-dev \
        libyaml-cpp-dev \
        libbenchmark-dev \
        ros-humble-tf2-geometry-msgs \
        ros-humble-geographic-msgs \
        ros-humble-mocap4r2-msgs \
        python3-pymap3d \
        libgeographic-dev \
        pybind11-dev \
        libncurses-dev \
    # && rosdep init && rosdep update \
    # && rosdep fix-permissions \
    # && rosdep install --from-paths src --ignore-src -r -y \
    &&  rm -rf /var/lib/apt/lists/*

WORKDIR /root/aerostack2_ws
RUN . /opt/ros/$ROS_DISTRO/setup.sh \
    && colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release \
        --packages-select \
            as2_core \ 
            as2_msgs \
            as2_state_estimator \
            px4_msgs \
            as2_platform_pixhawk \
            as2_alphanumeric_viewer \    
            as2_external_object_to_tf \
            as2_motion_controller \
            as2_motion_reference_handlers \
            as2_behavior \
            as2_behaviors_motion \
            as2_behaviors_trajectory_generation \
            as2_platform_pixhawk \
            px4_msgs \
    && echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc \
    && echo 'export AEROSTACK2_PATH=/root/aerostack2_ws/src/aerostack2' >> ~/.bashrc \
    && echo 'source $AEROSTACK2_PATH/as2_cli/setup_env.bash' >> ~/.bashrc

WORKDIR /root/aerostack2_ws/src/
COPY . project_px4_vision

COPY config/device_env.bash /device_env.bash
RUN echo 'source /device_env.bash' >> ~/.bashrc

WORKDIR /root/aerostack2_ws/src/project_px4_vision
# Note that the -ic forces it to use interactive command so bashrc is sourced
CMD ["/bin/bash", "-ic", "./launch_as2.bash"]

