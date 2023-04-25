from web3 import Web3
import json
from web3.middleware import geth_poa_middleware

my_provider = Web3.IPCProvider('/users/Girish/FuseMnt/datadir/geth.ipc')
w3 =Web3(my_provider)
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

with open('test.json', 'r') as f:
    abi = json.load(f)
    contract_address = '0x7a5891862F5F8c2c80e661387A786C6233ff9712'
    contract = w3.eth.contract(address=contract_address, abi=abi)
    result = contract.functions.getBalance().call()
    print(result)
    print("accounts:: ", w3.eth.accounts[0])
    result = contract.functions.CreateAccount(w3.eth.accounts[0],100).call()
    print(result)
    nonce = w3.eth.get_transaction_count(w3.eth.accounts[0])
    tx = {
        'nonce': nonce,
        'to': contract_address,
        'from': w3.eth.accounts[0],
        'value': 0,
        'gas': 10000000,
        'gasPrice': 0,
        'data': contract.functions.CreateAccount(w3.eth.accounts[0],100).build_transaction({'nonce': nonce})['data']
    }
    
    tx_hash = w3.eth.send_transaction(tx) 
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(tx_receipt)
    result = contract.functions.getBalance().call()
    print(result)