#!/bin/bash

LOCUST="/opt/venv/bin/locust"
LOCUS_OPTS="-f /locust/tasks.py --host=$TARGET_HOST --users=$LOCUST_USERS"
LOCUST_MODE=${LOCUST_MODE:-standalone}

if [[ "$LOCUST_MODE" = "master" ]]; then
    LOCUS_OPTS="$LOCUS_OPTS --master"
elif [[ "$LOCUST_MODE" = "worker" ]]; then
    LOCUS_OPTS="$LOCUS_OPTS --worker --master-host=$LOCUST_MASTER"
fi

echo "$LOCUST $LOCUS_OPTS"

$LOCUST $LOCUS_OPTS
