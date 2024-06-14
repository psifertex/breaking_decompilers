#!/bin/bash

SCRIPT=$(realpath "$0")
SP=$(dirname "$SCRIPT")

docker run --rm -p 1948:1948 -p 35729:35729 \
	-v "$SP":/slides \
	-v "$SP"/images:/_assets/images \
	webpronl/reveal-md:latest /slides --watch \
	--glob './*.md';
