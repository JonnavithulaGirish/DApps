from web3.auto import w3
import binascii
with open("/users/Girish/FuseMnt/datadir/keystore/UTC--2023-04-20T01-14-55.975607830Z--44649853fe6d3e1085b8a821deeca343847b3bbd") as keyfile:
    encrypted_key = keyfile.read()
    private_key = w3.eth.account.decrypt(encrypted_key, '')
    print(binascii.b2a_hex(private_key))