from web3 import Web3
import json
from web3.middleware import geth_poa_middleware

my_provider = Web3.IPCProvider('/users/Girish/FuseMnt/datadir/geth.ipc')
w3 =Web3(my_provider)
# w3= Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

with open('test.json', 'r') as f:
    abi = json.load(f)
    contract_address = '0xFbC40C43dfEea100B0a3BC91eC24D241dB1D737d'
    contract = w3.eth.contract(address=contract_address, abi=abi)
    result = contract.functions.getBalance().call()
    print(result)
    
    nonce = w3.eth.get_transaction_count(w3.eth.accounts[0])
    tx = {
        'nonce': nonce,
        'to': contract_address,
        'from': w3.eth.accounts[0],
        'value': 100,
        'gas': 10000000,
        'gasPrice': 0,
        'data': contract.functions.CreateAccount().buildTransaction({'value': 100, 'gas': 10000000,
        'gasPrice': 0})['data']
    }
    
    tx_hash = w3.eth.send_transaction(tx) 
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    nonce = w3.eth.get_transaction_count(w3.eth.accounts[0])
    tx = {
        'nonce': nonce,
        'to': contract_address,
        'from': w3.eth.accounts[0],
        'value': 0,
        'gas': 10000000,
        'gasPrice': 0,
        'data': contract.functions.NFTMint().buildTransaction({'nonce': nonce, 'value': 0, 'gas': 10000000,'gasPrice': 0})['data']
    }
    tx_hash = w3.eth.send_transaction(tx) 
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    nonce = w3.eth.get_transaction_count(w3.eth.accounts[0])
    tx = {
        'nonce': nonce,
        'to': contract_address,
        'from': w3.eth.accounts[0],
        'value': 1,
        'gas': 10000000,
        'gasPrice': 0,
        'data': contract.functions.bid(0).buildTransaction({'nonce': nonce,
        'value': 1,
        'gas': 10000000,
        'gasPrice': 0})['data']
    }
    tx_hash = w3.eth.send_transaction(tx) 
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(tx_receipt)

    # nonce = w3.eth.get_transaction_count(w3.eth.accounts[0])
    # tx = {
    #     'nonce': nonce,
    #     'to': contract_address,
    #     'from': w3.eth.accounts[0],
    #     'value': 0,
    #     'gas': 10000000,
    #     'gasPrice': 0,
    #     'data': contract.functions.NFTCheckAuctionEnd(1).buildTransaction({'value': 10, 'gas': 1000000000,
    #     'gasPrice': 0})['data']
    # }
    # tx_hash = w3.eth.send_transaction(tx) 
    # tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    # print(tx_receipt)

    # tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    # print(tx_receipt)
    # tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    # print(tx_receipt)
#     # result = contract.functions.AccountAddressesIndex().call()
#     # print(result)
#     result = contract.functions.NFTMint().call()
#     print(result)
    # nonce = w3.eth.get_transaction_count(w3.eth.accounts[0])
    # tx = {
    #     'nonce': nonce,
    #     'to': contract_address,
    #     'from': w3.eth.accounts[0],
    #     'value': 0,
    #     'gas': 10000000,
    #     'gasPrice': 0,
    #     'data': contract.functions.NFTMint().build_transaction({'nonce': nonce, 'value': 0, 'gas': 10000000,'gasPrice': 0})['data']
    # }
    # tx_hash = w3.eth.send_transaction(tx) 
    # tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    # print(tx_receipt)
    # result = contract.functions.NFTidCtr().call()
    # print(result)

# with open('auction.json', 'r') as f:
#     abi = json.load(f)
#     contract_address = '0x8fB89375Ae854FA5A7D0B5ec6Ab0cA3651724B4A'
#     contract = w3.eth.contract(address=contract_address, abi=abi)
#     nonce = w3.eth.get_transaction_count(w3.eth.accounts[0])
#     tx = {
#         'nonce': nonce,
#         'to': contract_address,
#         'from': w3.eth.accounts[0],
#         'value': 1,
#         'gas': 10000000,
#         'gasPrice': 0,
#         'data': contract.functions.bid(0).build_transaction({'nonce': nonce,
#         'value': 1,
#         'gas': 10000000,
#         'gasPrice': 0})['data']
#     }
#     tx_hash = w3.eth.send_transaction(tx) 
#     tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
#     print(tx_receipt)