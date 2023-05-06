#This file creates a first test network. It is suppose to work like byfn network of Hyperledger Fabric

#Parameters
read -p 'number of nodes: ' N
#
##source bashrc file to load the environment variable
#source ~/.bash_profile
source ~/.bashrc
source ~/.profile
#
echo "checking versions"
echo node -v
echo go version 
if [["$(node -v)" < "v16"]];
then
    echo "Please use the latest node version. ......Exiting"
    exit 0
else
     echo "node version installed is " 
     node -v
fi
if [ $? -eq 0 ]; then
  echo "All pre-requisite found"
else
  echo "unable to found pre-requisite.... exiting "
  exit 0
fi

echo "creating directory structure"
##exit 0
##Clean the previous deployment
if [[ -d IBFT-Network ]]
then 
	echo "Deleting material from previous deployment"
	rm -rf IBFT-Network
	mkdir IBFT-Network
else 
	mkdir IBFT-Network
fi
#
cd IBFT-Network
#
#Create directory structure
for ((i=0; i<$N; i++))
do 
   mkdir -p Node-$i/data/keystore
done 
#
#List the directory structure
echo "Following directories were created "
tree

#Generating artifacts
npx quorum-genesis-tool --consensus ibft --chainID 1337 --blockperiod 5 --requestTimeout 10 --epochLength 30000 --difficulty 1 --gasLimit '0xFFFFFF' --coinbase '0x0000000000000000000000000000000000000000' --validators $N --members 0 --bootnodes 0 --outputPath 'artifacts'

# #check whether this command was executed successfully
if [ $? -eq 0 ]; then
  echo OK
else
  echo "unable to generated artifacts .... exiting "
  exit 0
fi
#
#moving artifacts
mv artifacts/$(ls artifacts)/* artifacts/

echo "current directory structure"
tree

#Update IP and ports
cd artifacts/goQuorum

#update IP and port number
for ((i=0; i<$N; i++))
do 
   echo "----------- for $i ------------"    
   sed -i "$((i+2)) s/<HOST>/127.0.0.1/" static-nodes.json
   sed -i "$((i+2)) s/30303/3030$i/" static-nodes.json
   sed -i "$((i+2)) s/53000/5300$i/" static-nodes.json

done 

echo "updated static node file"
cat static-nodes.json
echo "not using permissioned node "
cp static-nodes.json permissioned-nodes.json
#
# #write forloop to shift all the files to given directory
# N=5
# cd IBFT-Network/artifacts/goQuorum
# echo "in go Quorum"
# echo "directories"
echo "displaying director structure. Currently in directory $PWD"
tree
sleep 5

for ((i=0; i<$N; i++))
do 
    echo "Shifting genesis file"
    cp static-nodes.json genesis.json ../../Node-$i/data/
done 
cd ..
#in goQuorum folder
echo "currently in folder $PWD"
sleep 5

echo "tree here is" 
tree

for ((i=0; i<$N; i++))
do 
    echo "Moving node data"
    cd validator$i
    cp nodekey* address ../../Node-$i/data
    cd ..
    ls
done 

cd validator0
echo "Changed to the validator0 directory. Currently in directory $PWD"
for ((i=0; i<$N; i++))
do 
   echo "copying data keystore"
   cd ../validator$i
   cp account* ../../Node-$i/data/keystore
done 

if [ $? -eq 0 ]; then
  echo "successfully moved validator directory "
else
  echo "unable to move Validator directory .... exiting "
  exit 0
fi
# initializing the nodes.
cd ../../Node-0
for ((i=0; i<$N; i++))
do 
    echo "installing node $i"
    cd ../Node-$i
    geth --datadir data init data/genesis.json
done 

# Starting nodes
for ((i=0; i<$N; i++))
do 
    echo "Starting Node $i"
    cd ../Node-$i
    echo "present directory is $PWD"
    export ADDRESS=$(grep -o '"address": *"[^"]*"' ./data/keystore/accountKeystore | grep -o '"[^"]*"$' | sed 's/"//g')
    export PRIVATE_CONFIG=ignore
    nohup geth --datadir data \
    --networkid 1337 --nodiscover --verbosity 5 \
    --syncmode full \
    --istanbul.blockperiod 5 --mine --miner.threads 1 --miner.gasprice 0 --emitcheckpoints \
    --http --http.addr 0.0.0.0 --http.port 2200$i --http.corsdomain "*" --http.vhosts "*" \
    --ws --ws.addr 0.0.0.0 --ws.port 3200$i --ws.origins "*" \
    --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
    --ws.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
    --unlock ${ADDRESS} --allow-insecure-unlock --password ./data/keystore/accountPassword \
    --port 3030$i 2>>${i}.log &
    sleep 5
    disown 

done 


