#!/bin/bash

PROG=AtomFpgaRtc

ca65 -l${PROG}.lst  -o ${PROG}.o ${PROG}.asm 
ld65 ${PROG}.o -o ${PROG}.run  -C atom.cfg 
