#!/bin/bash

echo "☢ Testing device registration..."

curl -H "Content-Type: application/json" -H "User-Agent: THiNX-Client" \
-X POST -d '{ "registration" : { "mac" : "00:00:00:00:00:00", "firmware" : "EAV-App-0.4.0-beta:2017/04/08", "hash" : "e58fa9bf7f478442c9d34593f0defc78718c8732", "push" : "registration-token-optional", "alias" : "test", "owner": "admin" } }' \
http://localhost:7442/api/login

echo "☢ Testing builder..."

curl -H "User-Agent: THiNX-Client" -H "Content-Type: application/json" -X POST -d '{ "build" : { "mac" : "ANY", "owner" : "test", "git" : "https://github.com/suculent/thinx-firmware-esp8266", "dryrun" : true } }' http://localhost:7442/api/build