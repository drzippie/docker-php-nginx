#!/usr/bin/env sh
set -e
apk --no-cache add curl

# Wait for the app container to be ready (depends_on doesn't wait for health)
i=0
until curl --silent --fail --output /dev/null http://app:8080/; do
  i=$((i + 1))
  [ "$i" -ge 30 ] && echo "FAIL: app not reachable" && exit 1
  sleep 1
done

# This container has no PHP, so check the app through its phpinfo page
page=$(curl --silent --fail http://app:8080)
echo "$page" | grep -q 'PHP Version 8.4' || { echo "FAIL: PHP 8.4 not found"; exit 1; }
echo "$page" | grep -q 'name="module_apcu"' || { echo "FAIL: apcu not loaded"; exit 1; }
echo "$page" | grep -q 'name="module_redis"' || { echo "FAIL: redis not loaded"; exit 1; }
echo "OK: $(echo "$page" | grep -o 'PHP Version 8\.4[^<]*' | head -1), apcu, redis"
