#!/usr/bin/env bash

# Filters Firebase Test Lab logs. Use by running `./filter-firebase-logs.sh <logs_url>`
# where `<logs_url>` is the url to the full Firebase Test Lab logs.
# Will drop the logs into a local file called firebase.log
curl "$1" | grep -E 'flutter:? ' | sed -E 's/.*flutter[: ]+//g' | tee firebase.log
