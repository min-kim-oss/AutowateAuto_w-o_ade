FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu20.04 
# nvidia/cuda:11.7.1-cudnn8-devel-ubuntu20.04
# https://hub.docker.com/r/nvidia/cuda 참고하여 버전 

ENV NVIDIA_VISIBLE_DEVICES ${NVIDIA_VISIBLE_DEVICES:-all} 
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

ENV USERNAME autoware 
ENV HOME /home/$USERNAME
RUN useradd -m $USERNAME && \
        echo "$USERNAME:$USERNAME" | chpasswd && \
        usermod --shell /bin/bash $USERNAME && \
        usermod -aG sudo $USERNAME && \
        mkdir /etc/sudoers.d && \
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
        chmod 0440 /etc/sudoers.d/$USERNAME && \
        # Replace 1000 with your user/group id
        usermod  --uid 1000 $USERNAME && \
        groupmod --gid 1000 $USERNAME
        
SHELL ["/bin/bash", "-c"] 
      
# install package
ENV DEBIAN_FRONTEND noninteractive
RUN apt-key del 7fa2af80 
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu2004/x86_64/7fa2af80.pub
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        apt-utils \
        git \
        cmake \
        python3-pip \
        tilix \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
        
RUN pip3 install -U colcon-common-extensions vcstool
      
RUN apt-get update && apt install -y --no-install-recommends \
        software-properties-common \
        curl \
        gnupg2 \
        lsb-release \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# install Git LFS
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt-get install git-lfs && \
    git lfs install && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key  -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt update && apt-get install -y --no-install-recommends \
        ros-foxy-desktop \
        ros-foxy-ros-base \
        ros-foxy-rmw-cyclonedds-cpp \
        python3-rosdep \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*  
    
RUN rosdep init
USER $USERNAME
WORKDIR /home/$USERNAME
RUN rosdep update
    
# install Autoware Auto
RUN source /opt/ros/foxy/setup.bash && \
    git clone https://gitlab.com/autowarefoundation/autoware.auto/AutowareAuto.git -b master && \
    cd AutowareAuto && \
    git lfs pull --exclude="" --include="*" && \ 
    sudo apt-get update && \
    vcs import < autoware.auto.foxy.repos && \
    rosdep install -y -i --from-paths src && \
    sudo mkdir /opt/AutowareAuto && \
    sudo chmod 777 /opt/AutowareAuto && \
    colcon build --install-base /opt/AutowareAuto --cmake-args -DCMAKE_BUILD_TYPE=Release && \
    sudo apt-get clean && \ 
    sudo rm -rf /var/lib/apt/lists/* 

RUN echo "source /opt/ros/foxy/setup.bash" >> ~/.bashrc && \
    echo "source /opt/AutowareAuto/setup.bash" >> ~/.bashrc && \
    source ~/.bashrc
