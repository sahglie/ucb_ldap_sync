#!/bin/bash
set -e

rm -f tmp/pids/server.pid
yarn build --watch &
yarn build:css --watch &
rails s -b 0.0.0.0
wait -n
exit $?

