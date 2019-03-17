#!/bin/bash

fatal() {
   >&2 echo "E: $1"
   exit 1
}

info() {
    >&2 echo "I: $1"
}
