#!/bin/sh
set -e
mkdir -p ./firebase-data
exec firebase emulators:start \
  --project finflow-local \
  --only auth,firestore,database,ui \
  --import=./firebase-data \
  --export-on-exit=./firebase-data