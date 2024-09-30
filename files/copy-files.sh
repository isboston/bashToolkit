#!/bin/bash

# Переменные
LOCAL_DIR="/path/to/local/dir"
REMOTE_USER="username"
REMOTE_HOST="hostname"
REMOTE_DIR="/path/to/remote/dir"

# Копирование с сохранением структуры
scp -r "$LOCAL_DIR" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"
