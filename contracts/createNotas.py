import json
import shlex
import subprocess
import sys
from time import time

from eth_abi import encode


def eth_call(command, error):
  result = subprocess.run(
      shlex.split(command), 
      stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
  if result.stderr:
    print(error)
    sys.exit(result.stderr)
  return result

if __name__ == "__main__":
  chain = sys.argv[2]; chain = chain if chain == "mumbai" else "local"
  key = sys.argv[1]; key = key if chain == "mumbai" else "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"  # load up from from the .env file directly?
  rpc = "https://polygon-mumbai-bor.publicnode.com" if (chain == "mumbai") else "http://127.0.0.1:8545"
  rpc_key_flags = f"--private-key {key} --rpc-url {rpc} --gas-price 30gwei"
  
  with open("contractAddresses.json", 'r') as f:
    existing_addresses = json.loads(f.read())


  registrar, directPay, dai, weth = [existing_addresses[chain][contract] for contract in 
                                     ["registrar", "directPay", "dai", "weth"]]

  # DIRECT PAY MODULE NOTAS # TODO create for loop with random values. Write using multiple modules
  toNotify, invoice_amount, timestamp, dappOperator, memoHash = ['0x70997970C51812dc3A010C7d01b50e0d17dc79C8', int(10e10), int(time()), '0x0000000000000000000000000000000000000000', web3.Web3.keccak(text='This is a hash')]
  moduleWriteData = encode(['address', 'uint256', 'uint256', 'address', 'string'], [toNotify, invoice_amount, timestamp, dappOperator, str(encode(['bytes32'], [memoHash]))])
  print(moduleWriteData); print(); print()
  # TODO how to encode the bytes data??
  # write_args = '" "'.join({
  #                        "currency": '"' + dai,
  #                        "escrowed": '0',
  #                        "instant": '0',
  #                        "owner": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  #                        "module": directPay,
  #                        "moduleWriteData": moduleWriteData#"b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00p\x99yp\xc5\x18\x12\xdc:\x01\x0c}\x01\xb5\x0e\r\x17\xdcy\xc8\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x17Hv\xe8\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00d\x0eBg\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xa0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00_b\'\\x8a\\xe7\\xb8\\xdd'"#str(moduleWriteData) + '"'
  #                       }.values())
  write_args = f"{dai} 0 0 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 {directPay} {moduleWriteData}"
  command = f'cast send {registrar} "write(address,uint256,uint256,address,address,bytes)" {write_args} {rpc_key_flags}'
  print(command)
  eth_call(command, "Write failed")
  
  # Transfer
  # transfer_args = 0
  # eth_call(f'cast send {registrar} "safeTransferFrom()" {transfer_args} {rpc_key_flags}', "Transfer failed")

  # Fund
  
  # Cash


"""
toNotify, invoice_amount, timestamp, dappOperator, memoHash
0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000249646174613a6170706c69636174696f6e2f6a736f6e3b6261736536342c65794a755957316c496a70446147567849484e6c636d6c6862434275645731695a584967497741414141414141414141414141414141414141414141414141414141414141414141414141414141414249697767496d563464475679626d46735833567962434936496d6c775a6e4d364c7939526257467a4e31425351575a30576d4e58656c42774e6e5a3252555a5659324a795755644557545654526e64586148564f5445784f526b6f3261566c4b4c43416959585230636d6c696458526c6379493649467437496e527959576c3058335235634755694f694169564739725a5734694c434a32595778315a534936786262416e635a5a58726c4a6335393831716a5651734b717630743965794a30636d4670644639306558426c496a6f67496b567a59334a766432566b49697769646d4673645755694f674141414141414141414141414141414141414141414141414141414141414141414141414141414141416658736964484a686158526664486c775a53493649434a45636d46335a5849694c483137496e527959576c3058335235634755694f69416951334a6c5958526c5a43424264434973496e5a686248566c496a6f414141414141414141414141414141414141414141414141414141414141414141414141415a417171746e3137496e527959576c3058335235634755694f6941695457396b6457786c49697769646d4673645755694f70355a724c74496c5a6e552f52302b752f745449506b593951385a665631390000000000000000000000000000000000000000000000
"""