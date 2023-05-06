#!/bin/bash
geth --exec "loadScript(\"$1\")" attach ipc:Node-0/data/geth.ipc