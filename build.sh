#!/bin/bash

SCRIPT=$(realpath "$0")
SP=$(dirname "$SCRIPT")

docker run --rm \
	-v "$SP":/slides \
	-v "$SP"/images:/_assets/images \
	webpronl/reveal-md:latest /slides --static build \
	--glob './*.md';
