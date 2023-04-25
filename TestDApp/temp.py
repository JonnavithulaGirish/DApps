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

# private_key = '0098bda9553da396a530a6521adbb856e63733ebeeee7ef56b86e2f887e26d98'
# acct = Account.from_key(private_key)
# print(acct.address)

# print(w3.eth.get_transaction_count(acct.address))
# print(w3.eth.send_raw_transaction(signed_txn.rawTransaction))