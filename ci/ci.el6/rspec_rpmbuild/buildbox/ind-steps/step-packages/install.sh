#!/bin/bash

for pkg in ${packages[@]} ; do
    install_package "${pkg}"
done
