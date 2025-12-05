#!/usr/bin/env bash

# shellcheck disable=SC2145,SC2046,SC2034

# --------------------------------------------------------------
# Copyright (C) 2023: Snyder Business And Technology Consulting. - All Rights Reserved
#
# Licensing:
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Date:
# November 22, 2023
#
# Author:
# Alexander Snyder
#
# Email:
# alexander@sba.tc
#
# Repository:
# https://github.com/thisguyshouldworkforus/bash
#
# Dependency:
# Access to root
# Docker
#
# Description:
# Useful Docker Functions
# --------------------------------------------------------------

# Generate a list of running containers
function ContainerList(){
    unset LIST_OF_KNOWN_CONTAINERS
    read -r -a LIST_OF_KNOWN_CONTAINERS <<< $(docker ps | awk 'NR>=2{print $1","$2","$NF}' | tr '\n' ' ' | tr '[:upper:]' '[:lower:]')
}

function ConfigList(){
    unset LIST_OF_KNOWN_CONFIGURATIONS
    read -r -a LIST_OF_KNOWN_CONFIGURATIONS <<< $(find /opt/apps -type f -iname "*-compose.yml" | awk -F '/' '{print $4}' | sort -u | tr '\n' ' ')
}

# Jump Into A Container
function jumpinto(){
    ContainerList
    if [[ -n "$1" ]]
        then
            NORMALIZED_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
            for CONTAINER in "${LIST_OF_KNOWN_CONTAINERS[@]}"
                do
                    CONTAINER_ID=$(echo "$CONTAINER" | awk -F ',' '{print $1}')
                    CONTAINER_IMAGE=$(echo "$CONTAINER" | awk -F ',' '{print $2}')
                    CONTAINER_NAME=$(echo "$CONTAINER" | awk -F ',' '{print $3}')
                    if [[ "$NORMALIZED_NAME" = "$CONTAINER_NAME" ]]
                        then
                            echo -en "\n\n############################################\n#\n# Jumping into \"$CONTAINER_NAME\"\n#\n############################################\n\n\n"
                            if [[ "$CONTAINER_NAME" = 'splunk' ]]
                                then
                                    docker container exec --interactive --tty --privileged --user='root' --workdir='/opt/splunk' "$CONTAINER_NAME" /bin/bash
                            elif [[ "$CONTAINER_NAME" = 'splunkforwarder' ]]
                                then
                                    docker container exec --interactive --tty --privileged --user='root' --workdir='/opt/splunkforwarder' "$CONTAINER_NAME" /bin/bash
                            elif [[ "$CONTAINER_IMAGE" =~ (.*)(lscr\.io)(.*) ]]
                                then
                                    docker container exec --interactive --tty --privileged --workdir='/config' "$CONTAINER_NAME" /bin/bash
                                else
                                    docker container exec --interactive --tty --privileged "$CONTAINER_NAME" /bin/bash
                            fi
                    fi
                done
    fi
}

# Stop a docker container
function docstop(){
    ContainerList
    if [[ -n "$1" ]]
        then
            NORMALIZED_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
            if [[ "$NORMALIZED_NAME" = 'all' ]]
                then
                    declare -a STOPPING_ARRAY
                    for CONTAINER in "${LIST_OF_KNOWN_CONTAINERS[@]}"
                        do
                            STOPPING_ARRAY+=("$(echo "$CONTAINER" | awk -F ',' '{print $3}')")
                        done
                    echo -en "\n\n############################################\n#\n# Stopping \"${STOPPING_ARRAY[@]}\"\n#\n############################################\n\n\n"
                    docker container stop "${STOPPING_ARRAY[@]}" > /dev/null 2>&1
                    docker container prune --force
                    return 0
                else
                    for CONTAINER in "${LIST_OF_KNOWN_CONTAINERS[@]}"
                        do
                            CONTAINER_ID=$(echo "$CONTAINER" | awk -F ',' '{print $1}')
                            CONTAINER_IMAGE=$(echo "$CONTAINER" | awk -F ',' '{print $2}')
                            CONTAINER_NAME=$(echo "$CONTAINER" | awk -F ',' '{print $3}')
                            if [[ "$NORMALIZED_NAME" = "$CONTAINER_NAME" ]]
                                then
                                    echo -en "\n\n############################################\n#\n# Stopping \"$CONTAINER_NAME\"\n#\n############################################\n\n\n"
                                    docker compose -f "/opt/apps/${CONTAINER_NAME}/${CONTAINER_NAME}-compose.yml" down > /dev/null 2>&1
                                    docker container rm --force "$CONTAINER_NAME" > /dev/null 2>&1
                                    return 0
                            fi
                        done
            fi
    fi
}

# Start a docker container
function docstart(){
    ConfigList
    if [[ -n "$1" ]]
        then
            NORMALIZED_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
            if [[ "$NORMALIZED_NAME" = 'all' ]]
                then
                    for CONFIGNAME in "${LIST_OF_KNOWN_CONFIGURATIONS[@]}"
                        do
                            docker compose -f "/opt/apps/${CONFIGNAME}/${CONFIGNAME}-compose.yml" up --detach
                        done
                else
                    for CONFIGNAME in "${LIST_OF_KNOWN_CONFIGURATIONS[@]}"
                        do
                            if [[ "$NORMALIZED_NAME" = "$CONFIGNAME" ]]
                                then
                                    echo -en "\n\n############################################\n#\n# Starting \"${CONFIGNAME}\"\n#\n############################################\n\n\n"
                                    if docker compose -f "/opt/apps/${CONFIGNAME}/${CONFIGNAME}-compose.yml" up --detach > /dev/null 2>&1
                                        then
                                            docker logs "${CONFIGNAME}" --follow --details --tail 50 --timestamps
                                            return 0
                                        else
                                            echo -en "There was an error starting the ${CONFIGNAME} container.\n\n\n"
                                    fi
                            fi
                        done
            fi
    fi
}

# Re-Start a docker container
function docrestart(){
    ConfigList
    if [[ -n "$1" ]]
        then
            NORMALIZED_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
            if [[ "$NORMALIZED_NAME" = 'all' ]]
                then
                    for CONFIGNAME in "${LIST_OF_KNOWN_CONFIGURATIONS[@]}"
                        do
                            echo "Stopping ${CONFIGNAME} ..."
                            docker compose -f "/opt/apps/${CONFIGNAME}/${CONFIGNAME}-compose.yml" down > /dev/null 2>&1
                            echo "Forcibly Recreating ${CONFIGNAME} ..."
                            docker compose -f "/opt/apps/${CONFIGNAME}/${CONFIGNAME}-compose.yml" up --detach --force-recreate > /dev/null 2>&1
                        done
                else
                    for CONFIGNAME in "${LIST_OF_KNOWN_CONFIGURATIONS[@]}"
                        do
                            if [[ "$NORMALIZED_NAME" = "$CONFIGNAME" ]]
                                then
                                    echo -en "\n\n############################################[ Re-Starting \"${CONFIGNAME}\" ]############################################\n#\n#\n#\n"
                                    echo -en "# Stopping \"${CONFIGNAME}| ... "
                                    if docker compose -f "/opt/apps/${CONFIGNAME}/${CONFIGNAME}-compose.yml" down > /dev/null 2>&1
                                        then
                                            echo -en "success!\n#\n#\n"
                                            echo -en "# Forcibly Recreating \"${CONFIGNAME}\" ... "
                                            if docker compose -f "/opt/apps/${CONFIGNAME}/${CONFIGNAME}-compose.yml" up -d --force-recreate > /dev/null 2>&1
                                                then
                                                    echo -en "success!\n#\n#\n"
                                                    echo -en "########################################################################################\n\n\n"
                                                    docker logs "${CONFIGNAME}" --follow --details --tail 50 --timestamps
                                                else
                                                    echo -en "ERROR\n\n\n"
                                                    return 1
                                            fi
                                        else
                                            echo -en "ERROR\n\n\n"
                                            return 1
                                    fi
                                    return 0
                            fi
                        done
            fi
    fi
}

# Get stats of a running container
function docstats(){
    ContainerList
    if [[ -n "$1" ]]
        then
            NORMALIZED_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
            for CONTAINER in "${LIST_OF_KNOWN_CONTAINERS[@]}"
                do
                    CONTAINER_ID=$(echo "$CONTAINER" | awk -F ',' '{print $1}')
                    CONTAINER_IMAGE=$(echo "$CONTAINER" | awk -F ',' '{print $2}')
                    CONTAINER_NAME=$(echo "$CONTAINER" | awk -F ',' '{print $3}')
                    if [[ "$NORMALIZED_NAME" = "$CONTAINER_NAME" ]]
                        then
                            echo -en "##########################\n# Container Name: \"$CONTAINER_NAME\"\n##########################\n"
                            
                            # Get the stats for the container once
                            output=$(docker container stats "$CONTAINER_NAME" --no-stream)

                            # Read the output into an array
                            IFS=$'\n' read -r -d '' -a lines <<< "$output"

                            # Extract header and data
                            header="${lines[0]}"
                            data="${lines[1]}"
                            
                            # Use awk to split and print in the desired format
                            awk '
                              BEGIN {
                                FS="  +"  # Field separator is multiple spaces
                              }
                              NR==1 {
                                for (i=1; i<=NF; i++) {
                                  header[i] = $i
                                }
                              }
                              NR==2 {
                                for (i=1; i<=NF; i++) {
                                  printf "%s: %s\n", header[i], $i
                                }
                              }
                            ' <<< "$header"$'\n'"$data"
                    fi
                done
    fi
}

function PruneDocker() {
    if rpm -q docker-ce > /dev/null 2>&1
        then
            echo "Stopping all containers before hosue cleaning"
            docstop all
            for SERVICE in image container network volume
                do
                    if [[ "$SERVICE" =~ image|volume ]]
                        then
                            OPTIONS=('--all' '--force')
                        else
                            OPTIONS=('--force')  # Fixed to ensure it's an array
                    fi
                    # Show the command being run
                    echo "Running: docker $SERVICE prune ${OPTIONS[@]}"
                    docker "$SERVICE" prune "${OPTIONS[@]}" > /dev/null 2>&1
                done
                echo "Restarting Docker"
                systemctl restart docker.service
                docstart all
                return 0
        else
            echo -en "Docker is not installed."
            return 1
    fi
}
