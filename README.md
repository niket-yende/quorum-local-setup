# quorum-local-setup
This repo sets up a private local quorum network with IBFT consensus. Default number of nodes are 5, but they can be customized as per the requirements.

## Install the pre-requisites
### References:
1. https://docs.goquorum.consensys.net/tutorials/private-network/create-ibft-network#prerequisites
1. https://docs.goquorum.consensys.net/deploy/install/binaries
1. https://www.tutorialspoint.com/how-to-set-the-gopath-environment-variable-on-ubuntu
1. https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-22-04#option-3-installing-node-using-the

## Steps to setup enhanced permissioned local quorum network
1. Start the basic quorum network of 5 nodes: <br/>
```./byfn-ibft.sh 5```
1. Verify that the network has started: <br/>
`ps aux|grep geth`
1. Copy files to the IBFT-NETWORK directory: <br/>
`cp -r output/ runscript.sh start-permission.sh IBFT-Network`
1. Navigate to the IBFT-NETWORK directory & update the existing guardian accounts in the start-permission.sh script: <br/>
`echo -e "\t\"accounts\": [\"$guardianAccount\", \"0x999069dD75094B5C4AEE6D40E11f1D6076b4134b\", \"0x973448aa9C1bdA2F896854e273AAe01b9368332D\"]," >> ./permission-config.json`
1. Start enhanced permissioned network: (Make sure the existing n/w is running) <br/>
`./start-permission.sh --numNodes 5`
1. Stop the running network: <br/>
`sudo kill -9 $(ps aux|grep geth |awk {'print$2'})`
1. Copy permissioned-nodes.json in each nodes data directory: <br/>
`niket@niket-X555LAB:~/blockchain/quorum-deployer-files/IBFT-Network/Node-0/data$ cp static-nodes.json permissioned-nodes.json`  <br/>
`niket@niket-X555LAB:~/blockchain/quorum-deployer-files/IBFT-Network/Node-0/data$ cp permissioned-nodes.json ../../Node-1/data/` <br/>
`niket@niket-X555LAB:~/blockchain/quorum-deployer-files/IBFT-Network/Node-0/data$ cp permissioned-nodes.json ../../Node-2/data/` <br/>
`niket@niket-X555LAB:~/blockchain/quorum-deployer-files/IBFT-Network/Node-0/data$ cp permissioned-nodes.json ../../Node-3/data/` <br/>
`niket@niket-X555LAB:~/blockchain/quorum-deployer-files/IBFT-Network/Node-0/data$ cp permissioned-nodes.json ../../Node-4/data/` <br/>
1. Init & restart all the geth nodes: (Run these commands from all the Node-[id] folders) <br/>
```
# Below 3 lines are common for all the nodes 
geth --datadir data init data/genesis.json
export ADDRESS=$(grep -o '"address": *"[^"]*"' ./data/keystore/accountKeystore | grep -o '"[^"]*"$' | sed 's/"//g')
export PRIVATE_CONFIG=ignore

# Node-0
nohup geth --datadir data \
  --networkid 1337 --nodiscover --verbosity 5 \
  --syncmode full \
  --istanbul.blockperiod 5 --mine --miner.threads 1 --miner.gasprice 0 --emitcheckpoints \
  --http --http.addr 0.0.0.0 --http.port 22000 --http.corsdomain "*" --http.vhosts "*" \
  --ws --ws.addr 0.0.0.0 --ws.port 32000 --ws.origins "*" \
  --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --ws.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --unlock ${ADDRESS} --allow-insecure-unlock --password ./data/keystore/accountPassword --permissioned \
  --port 30300 2>>0.log &	

# Node-1
nohup geth --datadir data \
  --networkid 1337 --nodiscover --verbosity 5 \
  --syncmode full \
  --istanbul.blockperiod 5 --mine --miner.threads 1 --miner.gasprice 0 --emitcheckpoints \
  --http --http.addr 0.0.0.0 --http.port 22001 --http.corsdomain "*" --http.vhosts "*" \
  --ws --ws.addr 0.0.0.0 --ws.port 32001 --ws.origins "*" \
  --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --ws.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --unlock ${ADDRESS} --allow-insecure-unlock --password ./data/keystore/accountPassword --permissioned \
  --port 30301 2>>1.log &
  
# Node-2
nohup geth --datadir data \
  --networkid 1337 --nodiscover --verbosity 5 \
  --syncmode full \
  --istanbul.blockperiod 5 --mine --miner.threads 1 --miner.gasprice 0 --emitcheckpoints \
  --http --http.addr 0.0.0.0 --http.port 22002 --http.corsdomain "*" --http.vhosts "*" \
  --ws --ws.addr 0.0.0.0 --ws.port 32002 --ws.origins "*" \
  --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --ws.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --unlock ${ADDRESS} --allow-insecure-unlock --password ./data/keystore/accountPassword --permissioned \
  --port 30302 2>>2.log &

# Node-3
nohup geth --datadir data \
  --networkid 1337 --nodiscover --verbosity 5 \
  --syncmode full \
  --istanbul.blockperiod 5 --mine --miner.threads 1 --miner.gasprice 0 --emitcheckpoints \
  --http --http.addr 0.0.0.0 --http.port 22003 --http.corsdomain "*" --http.vhosts "*" \
  --ws --ws.addr 0.0.0.0 --ws.port 32003 --ws.origins "*" \
  --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --ws.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --unlock ${ADDRESS} --allow-insecure-unlock --password ./data/keystore/accountPassword --permissioned \
  --port 30303 2>>3.log &

# Node-4
nohup geth --datadir data \
  --networkid 1337 --nodiscover --verbosity 5 \
  --syncmode full \
  --istanbul.blockperiod 5 --mine --miner.threads 1 --miner.gasprice 0 --emitcheckpoints \
  --http --http.addr 0.0.0.0 --http.port 22004 --http.corsdomain "*" --http.vhosts "*" \
  --ws --ws.addr 0.0.0.0 --ws.port 32004 --ws.origins "*" \
  --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --ws.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
  --unlock ${ADDRESS} --allow-insecure-unlock --password ./data/keystore/accountPassword --permissioned \
  --port 30304 2>>4.log &
```

## Troubleshooting the common issues
1. gcc issue: <br/>
`apt-get install build-essential`
1. gopath issue: <br/>
`export GOROOT=/usr/local/go` <br/>
`export GOPATH=/home/niket/blockchain/go_projects` <br/>
1. Issue of missing requirement while running make test: <br/>
`go get google.golang.org/protobuf/types/known/timestamppb@v1.28.0`


## YouTube video:
https://youtu.be/ZMlSSSGtoPo
