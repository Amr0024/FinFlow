#!/bin/sh
set -e
mkdir -p ./firebase-data
exec firebase emulators:start \
  --project fin-flow-26m8k6 \
  --only auth,firestore,database,ui \
  --import=./firebase-data \
  --export-on-exit=./firebase-data