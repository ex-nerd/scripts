#!/bin/bash

# On MacOS, ensure that ssh keys are properly loaded into the agent
if [[ "$OSTYPE" == darwin* ]]; then
    ssh-add -l &>/dev/null || ssh-add --apple-load-keychain
fi