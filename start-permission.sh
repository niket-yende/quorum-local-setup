#!/usr/bin/env bash

##source bashrc file to load the environment variable
source ~/.bashrc
#Parameters
# read -p 'number of nodes: ' N
# #
# #
# echo "No. of nodes $N"

localPath=$(pwd)
roles="NONE"
voter="NONE"
accounts="NONE"
nodes="NONE"
org="NONE"
permImpl="NONE"
permInterface="NONE"
upgr="NONE"
nwAdminOrg=""
nwAdminRole=""
orgAdminRole=""
subOrgDepth=0
subOrgBreadth=0
sleepTime=1

function usage() {
  echo ""
  echo "Usage:"
  echo "    $0 [raft | istanbul | clique] [tessera | constellation] [--tesseraOptions \"options for Tessera start script\"] [--numNodes numberOfNodes] [--blockPeriod blockPeriod] [--verbosity verbosity]"
  echo ""
  echo "Where:"
  echo "    raft | istanbul | clique : specifies which consensus algorithm to use"
  echo "    tessera | constellation (default = tessera): specifies which privacy implementation to use"
  echo "    --tesseraOptions: allows additional options as documented in tessera-start.sh usage which is shown below:"
  echo "    numberOfNodes is the number of nodes to initialise (default = $numNodes)"
  echo "    --blockPeriod: block period default is 5 seconds for IBFT and 50ms for Raft"
  echo "    --verbosity: verbosity for logging default is 3"
  echo ""
  ./tessera-start.sh --help
  exit -1
}

buildFiles(){
    contract=$1
    data=$2

    # echo "Compiling $1.sol"
    #compile and generate solc output in abi
    # solc --bin --abi --optimize --overwrite -o ./output ./perm-contracts/${permissionModel}/$1.sol
    cd ./output

    deployFile="deploy-$contract.js"
    loadFile="load-$contract.js"

    rm $deployFile $loadFile 2>>/dev/null

    abi=`cat ./$contract.abi`
    bc=`cat ./$contract.bin`
    echo -e "ac = eth.accounts[0];" >> ./$deployFile
    echo -e "web3.eth.defaultAccount = ac;" >> ./$deployFile
    echo -e "var abi = $abi;">> ./$deployFile
    echo -e "var bytecode = \"0x$bc\";">> ./$deployFile
    echo -e "var simpleContract = web3.eth.contract(abi);">> ./$deployFile
    echo "data $data"
    if [ "$data" == "NONE" ]
    then
        echo -e "var a = simpleContract.new(web3.eth.accounts[0],{from:web3.eth.accounts[0], data: bytecode, gas: 9200000}, function(e, contract) {">> ./$deployFile
    elif [ "$data" == "IMPL" ]
    then
        echo -e "var a = simpleContract.new(\"$upgr\", \"$org\", \"$roles\", \"$accounts\", \"$voter\", \"$nodes\", {from:web3.eth.accounts[0], data: bytecode, gas: 9200000}, function(e, contract) {">> ./$deployFile
    else
        echo -e "var a = simpleContract.new(\"$data\", {from:web3.eth.accounts[0], data: bytecode, gas: 9200000}, function(e, contract) {">> ./$deployFile
    fi
    echo -e "\tif (e) {">> ./$deployFile
    echo -e "\t\tconsole.log(\"err creating contract\", e);">> ./$deployFile
    echo -e "\t} else {">> ./$deployFile
    echo -e "\t\tif (!contract.address) {">> ./$deployFile
    echo -e "\t\t\tconsole.log(\"Contract transaction send: TransactionHash: \" + contract.transactionHash + \" waiting to be mined...\");">> ./$deployFile
    echo -e "\t\t} else {">> ./$deployFile
    echo -e "\t\t\tconsole.log(\"Contract mined! Address: \" + contract.address);">> ./$deployFile
    echo -e "\t\t\tconsole.log(contract);">> ./$deployFile
    echo -e "\t\t}">> ./$deployFile
    echo -e "\t}">> ./$deployFile
    echo -e "});">> ./$deployFile
    cd ..
}

createLoadFile(){
    contract=$1
    addr=$2
    intr=$3
    impl=$4
    loadFile="load-$contract.js"

    cd ./output

    abi=`cat ./$contract.abi`
    echo -e "ac = eth.accounts[0];">> ./$loadFile
    echo -e "web3.eth.defaultAccount = ac;">> ./$loadFile
    echo -e "var abi = $abi;">> ./$loadFile
    echo -e "var upgr = web3.eth.contract(abi).at(\"$addr\");">> ./$loadFile
    echo -e "var impl = \"$permImpl\"">>./$loadFile
    echo -e "var intr = \"$permInterface\"">> ./$loadFile

    cd ..
}
getContractAddress(){
    txid=$1
    x=$(geth attach ipc:$localPath/Node-0/data/geth.ipc <<EOF
    var addr=eth.getTransactionReceipt("$txid").contractAddress;
    console.log("contarct address number is :["+addr+"]");
    exit;
EOF
    )
    contaddr=`echo $x| tr -s " "| cut -f2 -d "[" | cut -f1 -d"]"`
    echo $contaddr
}

createPermConfig(){
    rm -f ./permission-config.json
    guardianAccount=$(cat ./Node-0/data/keystore/accountAddress)
    echo "Guardian account"
    echo $guardianAccount
    echo -e "{" >> ./permission-config.json
    echo -e "\t\"permissionModel\": \"$permissionModel\"," >> ./permission-config.json
    echo -e "\t\"upgrdableAddress\": \"$upgr\"," >> ./permission-config.json
    echo -e "\t\"interfaceAddress\": \"$permInterface\"," >> ./permission-config.json
    echo -e "\t\"implAddress\": \"$permImpl\"," >> ./permission-config.json
    echo -e "\t\"nodeMgrAddress\": \"$nodes\"," >> ./permission-config.json
    echo -e "\t\"accountMgrAddress\": \"$accounts\"," >> ./permission-config.json
    echo -e "\t\"roleMgrAddress\": \"$roles\"," >> ./permission-config.json
    echo -e "\t\"voterMgrAddress\": \"$voter\"," >> ./permission-config.json
    echo -e "\t\"orgMgrAddress\": \"$org\"," >> ./permission-config.json
    echo -e "\t\"nwAdminOrg\": \"$nwAdminOrg\"," >> ./permission-config.json
    echo -e "\t\"nwAdminRole\": \"$nwAdminRole\"," >> ./permission-config.json
    echo -e "\t\"orgAdminRole\": \"$orgAdminRole\"," >> ./permission-config.json
    echo -e "\t\"accounts\": [\"$guardianAccount\", \"0xa421ba62a835c5cac8e7edde8382e41c85ea5d49\", \"0x06f587df91e1bd74a2a900f781098603178f2e45\"]," >> ./permission-config.json
    echo -e "\t\"subOrgBreadth\": $subOrgBreadth," >> ./permission-config.json
    echo -e "\t\"subOrgDepth\": $subOrgDepth" >> ./permission-config.json
    echo -e "}" >> ./permission-config.json
}

deployContract(){
    file=$1
    op=`./runscript.sh ./output/$file`
    tx=`echo $op | head -1 | tr -s " "| cut -f5 -d " "`
    sleep $sleepTime
    contAddr=`getContractAddress $tx`
    echo "$contAddr"
}

permissionInit(){
   for i in {0..4}
   do
        cp ./permission-config.json Node-$i/data
   done
}

runInit(){
    cd ./output/
    x=$(geth attach ipc:$localPath/Node-0/data/geth.ipc <<EOF
    loadScript("load-PermissionsUpgradable.js");
    var tx = upgr.init(intr, impl, {from: eth.accounts[0], gas: 4500000});
    console.log("Init transaction id :["+tx+"]");
    exit;
EOF
    )
    cd ..
}

displayMsg(){
    torq=`tput setaf 14`
    reset=`tput sgr0`
    msg=$1
    echo -e "${torq}---------------------------------------------------------------------"
    echo -e "$msg"
    echo -e "---------------------------------------------------------------------${reset}"
}

getInputs(){
    blockPeriod=$1
    read -p "Enter Permission model to use [v1/v2]: "  permissionModel
    while [[ "$permissionModel" != "v1" && "$permissionModel" != "v2" ]];
    do
        echo "Invalid input for permissions model. Enter v1 or v2"
        read -p "Enter Permission model to use [v1/v2]: "  permissionModel
    done
    read -p "Enter Network Admin Org Name: "  nwAdminOrg
    read -p "Enter Network Admin Role Name: "  nwAdminRole
    read -p "Enter Org Admin Role Name: "  orgAdminRole
    echo "For Sub Orgs"
    read -p "Enter Allowed Breadth [numeric]: "  subOrgBreadth
    read -p "Enter Allowed Depth [numeric]: "  subOrgDepth
    if [ "$consensus" == "istanbul" ] && [ "$blockPeriod" == "" ]
    then
        read -p "Enter Block period as in geth start script: " blockPeriod
    elif [ "$consensus" == "clique" ]
    then
        read -p "Enter Block period as given in genesis.json: " blockPeriod
    fi

    if [ "$consensus" != "raft" ]; then
        sleepTime=$(( $blockPeriod + 2 ))
    fi
}

privacyImpl=tessera
tesseraOptions=
consensus=istanbul
numNodes=7
blockPeriod=
verbosity=3
permissionModel=
while (( "$#" )); do
    case "$1" in
        raft)
            consensus=raft
            shift
            ;;
        istanbul)
            consensus=istanbul
            shift
            ;;
        clique)
            consensus=clique
            shift
            ;;
        tessera)
            privacyImpl=tessera
            shift
            ;;
        constellation)
            privacyImpl=constellation
            shift
            ;;
        --tesseraOptions)
            tesseraOptions=$2
            shift 2
            ;;
        --numNodes)
            re='^[0-9]+$'
            if ! [[ $2 =~ $re ]] ; then
                echo "ERROR: numberOfNodes value must be a number"
            fi
            numNodes=$2
            shift 2
            ;;
        --blockPeriod)
            blockPeriod=$2
            shift 2
            ;;
        --verbosity)
            verbosity=$2
            shift 2
            ;;

        --help)
            shift
            ;;
        *)
            echo "Error: Unsupported command line parameter $1"
            ;;
    esac
done

if [ "$consensus" == "" ]; then
    echo "Error: consensus not selected"
    exit 1
fi

if [ "$blockPeriod" == "" ]; then
    if [ "$consensus" == "raft" ]; then
        blockPeriod=50
    elif [ "$consensus" == "istanbul" ]; then
        blockPeriod=5
    fi
fi

# check solc  & geth version if it is below 0.5.3 throw error
displayMsg "Checking solidity and geth version compatibility"
# checkSolidityVersion
# checkQuorumVersion

displayMsg "Input Permissions Specific parameters"
getInputs $blockPeriod

# create deployment files upgradable contract and deploy the contract
displayMsg "Building permissions deployables"
buildFiles PermissionsUpgradable $upgr
upgr=`deployContract "deploy-PermissionsUpgradable.js"`

buildFiles "OrgManager" $upgr
buildFiles "RoleManager" $upgr
buildFiles "NodeManager" $upgr
buildFiles "VoterManager" $upgr
buildFiles "AccountManager" $upgr

org=`deployContract "deploy-OrgManager.js"`
roles=`deployContract "deploy-RoleManager.js"`
nodes=`deployContract "deploy-NodeManager.js"`
voter=`deployContract "deploy-VoterManager.js"`
accounts=`deployContract "deploy-AccountManager.js"`

buildFiles "PermissionsImplementation" "IMPL"
buildFiles "PermissionsInterface" $upgr

permImpl=`deployContract "deploy-PermissionsImplementation.js"`
permInterface=`deployContract "deploy-PermissionsInterface.js"`

# create the permissions config file
displayMsg "Creating permission config file and copying to data directories"
createPermConfig
echo "created permission-config.json"
cat ./permission-config.json

#copy the permission config file to Node-$i/data folders
permissionInit

displayMsg "Creating load script for upgradable contract and initializing"
# initialize the upgradable contracts with custodian address and link interface and implementation contarcts
createLoadFile "PermissionsUpgradable" $upgr $permInterface $permImpl
runInit
echo "Network initialization completed"
sleep 10

echo "current directory is $PWD"

# displayMsg "Restarting the network with permissions"
# # Bring down the network wait for all time wait connections to close
# echo "Bringing down geth nodes"
# ps aux|grep geth |awk {'print$2'}
# sudo kill -9 $(ps aux|grep geth |awk {'print$2'})

# # Bring the netowrk back up
# #cd Node-0
# # Starting nodes
# for ((i=0; i<5; i++))
# do 
#     echo "Starting Node $i"
#     cd Node-$i
#     echo "present directory is $PWD"
#     export ADDRESS=$(grep -o '"address": *"[^"]*"' ./data/keystore/accountKeystore | grep -o '"[^"]*"$' | sed 's/"//g')
# 	echo "ADDRESS $ADDRESS"
#     export PRIVATE_CONFIG=ignore
#     nohup geth --datadir Node-$i/data \
#     --networkid 1337 --nodiscover --verbosity 5 \
#     --syncmode full \
#     --istanbul.blockperiod 5 --mine --miner.threads 1 --miner.gasprice 0 --emitcheckpoints \
#     --http --http.addr 0.0.0.0 --http.port 2200$i --http.corsdomain "*" --http.vhosts "*" \
#     --ws --ws.addr 0.0.0.0 --ws.port 3200$i --ws.origins "*" \
#     --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
#     --ws.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
#     --unlock ${ADDRESS} --allow-insecure-unlock --password ./data/keystore/accountPassword \
#     --port 3030$i \
#     --permissioned 2>>${i}.log &
#     sleep 5
#     disown 
#     cd ..
# done 

echo "All nodes configured."

exit 0
