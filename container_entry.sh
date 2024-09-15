#!/bin/bash

sudo apt-get update
rosdep update
exec "$@"