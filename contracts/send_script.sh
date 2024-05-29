#!/bin/zsh
# Make sure you are running bash >=4.0 and on macOS
source .env

PRIVATE_KEY=${PRIVATE_KEY}
externalURLDefault="https://app.denota.xyz/"
DEPLOY_RPC_URL="${POLYGON_RPC_URL}"
if [ -z "$DEPLOY_RPC_URL" ]; then
    echo "RPC URL is not set. Please set the POLYGON_RPC_URL environment variable or directly assign DEPLOY_RPC_URL in the script."
    exit 1
fi

currency=""
selectCurrency() {
    # Define the currencies and their addresses in an associative array
    declare -A currencies=(
        ["CircleUSDC"]="0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"
        ["DAI"]="0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"
        ["WETH"]="0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"
        ["USDT"]="0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
    )

    # Display the menu
    echo "Select a currency:"
    local i=1
    for currency in "${!currencies[@]}"; do
        echo "$i) $currency"
        let i++
    done

    # Read user choice
    read -p "Enter the index of the currency: " choice

    # Validate input
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#currencies[@]} ]; then
        echo "Invalid selection. Please enter a number between 1 and ${#currencies[@]}."
        return 1
    fi

    # Convert choice to currency name
    local selectedCurrencyName=$(echo "${!currencies[@]}" | tr ' ' '\n' | sed -n "${choice}p")

    # Output the selected currency and its address
    echo "Selected currency: $selectedCurrencyName"
    currency="${currencies[$selectedCurrencyName]}" # Update global currency variable
    echo "Address: $currency"
}

# Function to convert relative date formats (e.g., "7 days") into epoch on macOS
convertToEpoch() {
    input=$1
    
    # Parse the input for number and unit
    number=$(echo $input | awk '{print $1}')
    unit=$(echo $input | awk '{print $2}')
    
    # Determine the date adjustment parameter for macOS date command
    case $unit in
        "minute"|"minutes")
            adjustment="${number}M"
            ;;
        "hour"|"hours")
            adjustment="${number}H"
            ;;
        "day"|"days")
            adjustment="${number}d"
            ;;
        "week"|"weeks")
            adjustment="${number}w"
            ;;
        "month"|"months")
            adjustment="${number}m"
            ;;
        *)
            echo "Invalid date format."
            exit 1
            ;;
    esac
    
    # Use date command with adjustment to get future date in epoch time
    epoch=$(date -v+${adjustment} +%s)
    echo $epoch
}

# Function to convert duration to seconds
convert_to_seconds() {
    local input="$1"
    local number=$(echo $input | awk '{print $1}')
    local unit=$(echo $input | awk '{print $2}')

    case $unit in
        day|days)
            echo $(($number * 86400))
            ;;
        month|months)
            # Assuming an average month length of 30 days
            echo $(($number * 30 * 86400))
            ;;
        hour|hours)
            echo $(($number * 3600))
            ;;
        minute|minutes)
            echo $(($number * 60))
            ;;
        *)
            echo "Unsupported unit: $unit"
            exit 1
            ;;
    esac
}

# Ask for transaction type
echo "Select the type of transaction:"
echo "0. CashBeforeDateDrip"
echo "1. CashBeforeDate"
echo "2. ReversibleByBeforeDate"
echo "3. ReversibleRelease"
echo "4. SimpleCash"
echo "5. DirectSend"
echo "6. BalanceOf"
read -p "Enter your choice (0/1/2/etc): " transactionType

# Get registrar address
registrarAddress=$(cat salts/registrarSalt.txt | grep "Address: " | awk '{print $2}')

# Get inputs
selectCurrency
read -p "Enter escrow (default 0): " escrow
escrow=${escrow:-0}
read -p "Enter instant (default 0): " instant
instant=${instant:-0}
while true; do
    read -p "Enter owner address: " owner
    if [[ -n "$owner" ]]; then
        break
    else
        echo "Owner address is required. Please enter a valid address."
    fi
done

read -p "Enter external URL (default $externalURLDefault): " externalURL
externalURL=${externalURL:-$externalURLDefault}
read -p "Enter image URL (default ipfs://): " imageURL
imageURL=${imageURL:-"ipfs://"}

# Module and ABI setup
writeSelector="write(address,uint256,uint256,address,address,bytes)"
case $transactionType in
    0)
        module="0x00000000e8c13602e4d483a90af69e7582a43373"

        # uint256 epoch parameter
        read -p "Enter expirationDate (e.g., '7 days', '1 minute', '2 months'): " userInput
        expirationDate=$(convertToEpoch "$userInput")
        if [ -z "$expirationDate" ]; then
            echo "Invalid date format."
            exit 1
        else
            echo "- expirationDate (epoch time): $expirationDate"
        fi

        # uint256 number parameter
        read -p "Enter dripAmount: " dripAmount

        # uint256 seconds parameter
        read -p "Enter dripPeriod (e.g., '7 days', '1 minute', '2 months'): " userInput

        dripPeriod=$(convert_to_seconds "$userInput")
        if [ -z "$dripPeriod" ]; then
            echo "Invalid date format."
            exit 1
        else
            echo "- dripPeriod (in seconds): $dripPeriod"
        fi
        ;;
    1)
        module="0x000000005891889951D265d6d7ad3444B68f8887"
        
        # uint256 epoch parameter
        read -p "Enter cashByDate (e.g., '7 days', '1 minute', '2 months'): " userInput
        cashByDate=$(convertToEpoch "$userInput")

        if [ -z "$cashByDate" ]; then
            echo "Invalid date format."
            exit 1
        else
            echo "- cashByDate (epoch time): $cashByDate"
        fi ;;
    2)
        module="0x00000000115e79ea19439db1095327acbd810bf7"
        
        # uint256 epoch parameter
        read -p "Enter reversibleByBeforeDate (e.g., '7 days', '1 minute', '2 months'): " userInput
        cashByDate=$(convertToEpoch "$userInput")

        if [ -z "$cashByDate" ]; then
            echo "Invalid date format."
            exit 1
        else
            echo "- reversibleByBeforeDate (epoch time): $cashByDate"
        fi 

        # address parameter
        read -p "Enter inspector address: " inspector 
        ;;
    3)
        module="0x0000000078E1A913Ee98c64CEc34fe813872eF79"
        read -p "Enter inspector address: " inspector
        ;;
    4) module="0x000000000AE1D0831c0C7485eAcc847D2F57EBb9" ;;
    5) module="0x00000003672153a114583fa78c3d313d4e3cae40" ;;
    6) 
        module="0x00000000373Cbb1B1dfFbaB531Ea4EdB297A6182"

        # address parameter
        read -p "Enter NFTAddress: " NFTAddress

        # uint8 parameter
        read -p "Enter ConditionType: " ConditionType

        # uint96 epoch parameter
        read -p "Enter expirationDate (e.g., '7 days', '1 minute', '2 months'): " userInput
        expirationDate=$(convertToEpoch "$userInput")
        if [ -z "$expirationDate" ]; then
            echo "Invalid date format."
            exit 1
        else
            echo "- expirationDate (epoch time): $expirationDate"
        fi

        # uint256 value parameter
        read -p "Enter threshold: " threshold
        ;;

    *)
        echo "Invalid option selected."
        exit 1
        ;;
esac

read -p "These values correct?" userInput

# Generate moduleBytes based on transaction type
if [[ "$transactionType" == "0" ]]; then
    moduleBytes=$(cast abi-encode "f(uint256,uint256,uint256,string,string)" "${expirationDate}" "${dripAmount}" "${dripPeriod}" "${externalURL}" "${imageURL}")
elif [[ "$transactionType" == "1" ]]; then
    moduleBytes=$(cast abi-encode "f(uint256,string,string)" "${cashByDate}" "${externalURL}" "${imageURL}")
elif [[ "$transactionType" == "2" ]]; then
    moduleBytes=$(cast abi-encode "f(address,uint256,string,string)" "${inspector}" "${cashByDate}" "${externalURL}" "${imageURL}")
elif [[ "$transactionType" == "3" ]]; then
    moduleBytes=$(cast abi-encode "f(address,string,string)" "${inspector}" "${externalURL}" "${imageURL}")
elif [[ "$transactionType" == "4" ]]; then
    moduleBytes=$(cast abi-encode "f(string,string)" "${externalURL}" "${imageURL}")
elif [[ "$transactionType" == "5" ]]; then
    moduleBytes=$(cast abi-encode "f(string,string)" "${externalURL}" "${imageURL}")
elif [[ "$transactionType" == "6" ]]; then
    moduleBytes=$(cast abi-encode "f(address,uint8,uint96,uint256,string,string)" "${NFTAddress}" "${ConditionType}" "${expirationDate}" "${threshold}" "${externalURL}" "${imageURL}")
else
    echo "Invalid option selected."
    exit 1
fi

# Execute the transaction
cast send ${registrarAddress} ${writeSelector} ${currency} ${escrow} ${instant} ${owner} ${module} ${moduleBytes} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} --gas-price 90000000000