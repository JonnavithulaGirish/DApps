from eth_account import Account
from web3 import Web3
import secrets
from web3.middleware import geth_poa_middleware
#from ethereum.transactions import Transaction
import rlp


# private_key = '0098bda9553da396a530a6521adbb856e63733ebeeee7ef56b86e2f887e26d98'
# acct = Account.from_key(private_key)
# print(acct.address)

bytecode = open("test.bytecode", "r").read()
my_provider = Web3.IPCProvider('/users/Girish/FuseMnt/datadir/geth.ipc')
#w3 = Web3(Web3.HTTPProvider('http://10.10.1.2:30306'))
w3 =Web3(my_provider)
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

# signed_txn = w3.eth.account.sign_transaction(dict({
#     'nonce': w3.eth.get_transaction_count(acct.address),
#     'gasPrice':20000000000,
#     'gas':9000000,
#     'from': acct.address,
#     'value':0,
#     'data':bytecode,
#     'chainId':5,
#     'to': None
#   }),
#   private_key,
# )
#print(w3.eth)
# tx = Transaction(
#     nonce=w3.eth.get_transaction_count(acct.address),
#     gasprice=web3.eth.gasPrice,
#     gas=900000,
#     from='0xd3cda913deb6f67967b99d67acdfa1712c293601',
#     data=bytecode,
#     chainId=
# )

tx_hash = w3.eth.send_transaction({
    "from":'0x44649853Fe6D3E1085B8A821DeECA343847B3bbD',
    "gasPrice": 0,
    "gas": 10000000,
    "data": bytecode,
    "chainId":16,
    "nonce": w3.eth.get_transaction_count('0x44649853Fe6D3E1085B8A821DeECA343847B3bbD')
})
# print(w3.eth.get_transaction_count(acct.address))
# print(w3.eth.send_raw_transaction(signed_txn.rawTransaction))

print(tx_hash)

tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

contract_address = tx_receipt["contractAddress"]
print("contract_address",contract_address)
