#!/bin/bash

usage() {
    echo "  options:"
    echo "      -i: initialise"
    echo "      -n: docker name, defaults to as2_pixhawk_imu"
    echo "      -r: registry, defaults to 128.16.29.85:5000"
}

# Initialize variables with default values
init="false"
name="project_px4_vision"
registry="128.16.29.85:5000"

# Arg parser
while getopts "in:r:" opt; do
  case ${opt} in
    i )
      init="true"
      ;;
    n )
      name="${OPTARG}"
      ;;
    r )
      registry="${OPTARG}"
      ;;
    : )
      if [[ ! $OPTARG =~ ^[wrt]$ ]]; then
        echo "Option -$OPTARG requires an argument" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ ${init} == "true" ]]; then
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    docker buildx create \
        --name container-builder-px4 \
        --driver docker-container \
        --config config/buildkitd.toml \
        --driver-opt network=host \ 
        --bootstrap --use
    # --driver-opt needed to push to local 127.0.0.1:5000...
fi

FULL_NAME="${registry}/${name}:latest"

docker buildx build --platform linux/amd64,linux/arm64/v8 -t "${FULL_NAME}" --push .