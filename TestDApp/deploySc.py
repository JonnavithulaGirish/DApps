from eth_account import Account
from web3 import Web3
import secrets
from web3.middleware import geth_poa_middleware

bytecode = open("test.bytecode", "r").read()
my_provider = Web3.IPCProvider('/users/Girish/FuseMnt/datadir/geth.ipc')
w3 =Web3(my_provider)
w3.middleware_onion.inject(geth_poa_middleware, layer=0)


tx_hash = w3.eth.send_transaction({
    "from":'0x44649853Fe6D3E1085B8A821DeECA343847B3bbD',
    "gasPrice": 0,
    "gas": 10000000,
    "data": bytecode,
    "chainId":16,
    "nonce": w3.eth.get_transaction_count('0x44649853Fe6D3E1085B8A821DeECA343847B3bbD')
})


print(tx_hash)

tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

contract_address = tx_receipt["contractAddress"]
print("contract_address",contract_address)
