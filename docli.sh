#!/usr/bin/env bash

version='1.0'
inventory_file='inventory'
context=()
all_flag=False
create_flag=False
up_flag=False
down_flag=False
stack_to_create=

if [[ ! -f "$inventory_file" ]]; then
    echo "Inventory file does not exist, exiting..."
    exit 1
fi

# shellcheck disable=SC2039
declare -A group_map

# Function to parse the file and populate the group map
parse_file() {
    # shellcheck disable=SC2039
    local current_group=""
    while IFS= read -r line; do
        if [[ $line =~ ^\[.* ]]; then
            # This is a group line
            current_group=${line//\[/}
            current_group=${current_group//\]/}
            group_map["$current_group"]=""
        elif [[ -n $line ]]; then
            # This is a stack line
            trimmed=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            group_map["$current_group"]+="$trimmed,"
        fi
    done < "$inventory_file"
}

# Usage
usage() {
    echo "
        NAME
            docli - manage docker-compose stacks centrally
        SYNOPSYS:
            docli [OPTION] ... [DIRECTORY] ...
        DESCRIPTION
          Manage multiple docker-compose stacks with a single command
        OPTIONS
          --all                 Apply the command to all groups in the inventory
          --context[=CTX]       Inventory group to apply the command
          --help                Display this help message and exit
          --version             Output version information and exit
          create                Create a new directory
          up                    Executes 'docker-compose up -d'
          down                  Executes 'docker-compose down'"
    exit 1
}

version(){
  echo $version
  exit 0
}

up_function() {
  echo "Starting containers for stack=$1"
  docker-compose -f "$1/docker-compose.yaml" up
}

down_function() {
  echo "Stopping containers for stack=$1"
  docker-compose -f "$1/docker-compose.yaml" down
}

create_function() {
  mkdir -p "$2" && touch "$2/docker-compose.yaml"

  if [[ ! -s "$2/docker-compose.yaml" ]]; then
    echo "
version: '3.8'
#change your config according to your specific use case
services:
  hello-world:
    image: hello-world" > "$2/docker-compose.yaml"
  fi

  group="$1"
  new_stack="$2"

  # Create a backup of the original file
  cp "$inventory_file" "$inventory_file.bak"

  awk -v group="$group" -v stack="$new_stack" '
  BEGIN {insert=0}
  $0=="["group"]" {insert=1}
  insert==1 && /^$/ {print stack; insert=0}
  1
  END { if (insert) print stack }' "$inventory_file" > tmpfile && mv tmpfile "$inventory_file"

  echo "Created stack '$new_stack' in group '$group'"
}

apply_action(){
  if [ $up_flag = "True" ]; then
    up_function "$1"
  elif [ $down_flag = "True" ]; then
    down_function "$1"
  fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
          version
          ;;
        --all)
        all_flag=True
        shift
        ;;
        --context=*)
        context=(${1#*=}) # get value after '='
        if [[ $2 != "up" && $2 != "down" ]]; then
          stack_to_create=$2
          shift
        fi
        shift
        ;;
        create)
            create_flag=True
        shift
        ;;
        up)
            up_flag=True
        shift
        ;;
        down)
            down_flag=True
        shift
        ;;
        --help)
        usage
        shift
        ;;
        *)
        # unknown option
        echo "unknown option: $1"
        usage
        ;;
    esac
done

parse_file
IFS=','

if [ $create_flag = "True"  ]; then
    if [ -z "$context" ]; then
      echo "Missing context information"
      exit 1
    fi
    if [ -z "${group_map[$context]}" ]; then
      echo "Group $context does not exist in inventory file"
      exit 1
    fi

    create_function "$context" "$stack_to_create"
else
  if [ "$all_flag" = "True" ]; then
    for key in "${!group_map[@]}"; do
        for stack in ${group_map[$key]}; do
          apply_action "$stack"
        done
    done
  else
    if [ -z "$context" ]; then
      echo "Missing context information"
      exit 1
    fi
    for stack in ${group_map[$context]}; do
          apply_action "$stack"
    done
  fi
fi