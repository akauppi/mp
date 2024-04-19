#!/bin/bash
set -e

# Environment setup

# Directs Chokidar (that Vite uses) to detect changes; VM mounts don't support change notifications.
export CHOKIDAR_USEPOLLING=1
