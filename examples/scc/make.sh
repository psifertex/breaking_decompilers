#!/bin/bash
#
# TODO: use lastrun in BN_USER_DIR to find path and call scc from there
# 

/Applications/Binary\ Ninja-4.0.app/Contents/MacOS/plugins/scc --stack-reg rbx -o base.elf --arch x86 -m32 --format elf base.c
