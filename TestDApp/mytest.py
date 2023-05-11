#pylint: disable=missing-docstring,redefined-outer-name

import pytest
from eth_tester.exceptions import TransactionFailed
from web3 import Web3
from web3.middleware import geth_poa_middleware
import time

@pytest.fixture
def madefi_contract(w3, get_vyper_contract):
    with open("test.vy", encoding='utf-8') as infile:
        contract_code = infile.read()

    args = [w3.eth.accounts[0], w3.eth.accounts[1]]
    # account0 = w3.eth.account[0]
    return get_vyper_contract(contract_code)

@pytest.fixture
def madefi_contract1(w3, madefi_contract):
    account0 = w3.eth.accounts[0]
    account1 = w3.eth.accounts[1]

# def test_initial_state(w3, madefi_contract):
#     #assert madefi_contract.AccountAddressesIndex() == 0
#     #account0 = w3.eth.accounts[0]
#     #print(w3.eth.accounts[0])
#     madefi_contract.NFTMint(transact={'gas': 10000000, 'from': w3.eth.accounts[0], 'value': 100, 'gas_price': 0})
#     assert madefi_contract.NFTidCtr() == 1
#     madefi_contract.bid(0, transact={'from':  w3.eth.accounts[1], 'value': 1})
#     print(str(madefi_contract.AuctionMap(0)))
#     assert madefi_contract.AuctionMap(0)[3] == w3.eth.accounts[1]
#     assert madefi_contract.AuctionMap(0)[4] == 1
#     time.sleep(5)
#     madefi_contract.NFTCheckAuctionEnd(0, transact={'gas': 10000000, 'from': w3.eth.accounts[0], 'value': 100})
#     print(str(madefi_contract.AuctionMap(0)))
#     assert madefi_contract.AuctionMap(0)[3] == w3.eth.accounts[1]
#     assert madefi_contract.AuctionMap(0)[5] == True

def test_initial_state2(w3, madefi_contract):
    madefi_contract.CreateAccount(transact={'gas': 10000000, 'from': w3.eth.accounts[0], 'value': 100, 'gas_price': 0})
    assert madefi_contract.Accounts(w3.eth.accounts[0])[0] == 100
    madefi_contract.Deposit(1, transact={'gas': 10000000, 'from': w3.eth.accounts[0], 'value': 100, 'gas_price': 0})
    assert madefi_contract.Accounts(w3.eth.accounts[0])[1] == 100
    time.sleep(5)
    madefi_contract.WithDraw(100, 1, 0, transact={'gas': 10000000, 'from': w3.eth.accounts[0], 'gas_price': 0})
    assert madefi_contract.Accounts(w3.eth.accounts[0])[1] == 0
    # madefi_contract.bid(0, transact={'from':  w3.eth.accounts[1], 'value': 1})
    # print(str(madefi_contract.AuctionMap(0)))
    # assert madefi_contract.AuctionMap(0)[3] == w3.eth.accounts[1]
    # assert madefi_contract.AuctionMap(0)[4] == 1
    # time.sleep(5)
    # madefi_contract.NFTCheckAuctionEnd(0, transact={'gas': 10000000, 'from': w3.eth.accounts[0], 'value': 100})
    # print(str(madefi_contract.AuctionMap(0)))
    # assert madefi_contract.AuctionMap(0)[3] == w3.eth.accounts[1]
    # assert madefi_contract.AuctionMap(0)[5] == True
    
# @pytest.fixture
# def battleship_board2(w3, battleship_contract):
#     account0 = w3.eth.accounts[0]
#     account1 = w3.eth.accounts[1]

#     assert not battleship_contract.has_winner()

#     # Each player sets 5 game pieces
#     battleship_contract.set_field(4,4, transact={"from": account0})
#     battleship_contract.set_field(4,0, transact={"from": account1})

#     battleship_contract.set_field(3,3, transact={"from": account0})
#     battleship_contract.set_field(3,0, transact={"from": account1})

#     battleship_contract.set_field(2,2, transact={"from": account0})
#     battleship_contract.set_field(3,2, transact={"from": account1})

#     battleship_contract.set_field(0,0, transact={"from": account0})
#     battleship_contract.set_field(2,2, transact={"from": account1})

#     battleship_contract.set_field(1,1, transact={"from": account0})
#     battleship_contract.set_field(1,3, transact={"from": account1})

#     assert not battleship_contract.has_winner()

#     return battleship_contract

# def test_initial_state(battleship_contract):
#     assert not battleship_contract.has_winner()

# def test_cannot_set_field_twice(w3, battleship_contract):
#     account = w3.eth.accounts[0]

#     battleship_contract.set_field(1,1, transact={"from": account})

#     # Should not be allowed
#     with pytest.raises(TransactionFailed):
#         battleship_contract.set_field(1,1, transact={"from": account})

# def test_cannot_set_too_many_fields(w3, battleship_contract):
#     account = w3.eth.accounts[0]

#     # set 5 field like usual
#     battleship_contract.set_field(4,4, transact={"from": account})
#     battleship_contract.set_field(3,3, transact={"from": account})
#     battleship_contract.set_field(2,2, transact={"from": account})
#     battleship_contract.set_field(1,1, transact={"from": account})
#     battleship_contract.set_field(0,0, transact={"from": account})

#     # Should not be allowed
#     with pytest.raises(TransactionFailed):
#         battleship_contract.set_field(1,2, transact={"from": account})

# def test_third_party_cannot_set_field(w3, battleship_contract):
#     # not a player
#     account = w3.eth.accounts[3]

#     # Should not be allowed
#     with pytest.raises(TransactionFailed):
#         battleship_contract.set_field(1,1, transact={"from": account})

# def test_cannot_shoot_at_beginning(w3, battleship_contract):
#     account = w3.eth.accounts[0]

#     # Should not be allowed
#     with pytest.raises(TransactionFailed):
#         battleship_contract.shoot(1,1, transact={"from": account})

# def test_player1_wins_on_board1(w3, battleship_board1):
#     account0 = w3.eth.accounts[0]
#     account1 = w3.eth.accounts[1]

#     battleship_contract = battleship_board1

#     battleship_contract.shoot(2,1, transact={"from": account0})
#     battleship_contract.shoot(1,1, transact={"from": account1})

#     # both miss
#     battleship_contract.shoot(0,0, transact={"from": account0})
#     battleship_contract.shoot(0,0, transact={"from": account1})

#     battleship_contract.shoot(1,1, transact={"from": account0})
#     battleship_contract.shoot(1,2, transact={"from": account1})

#     battleship_contract.shoot(1,2, transact={"from": account0})
#     battleship_contract.shoot(0,1, transact={"from": account1})

#     battleship_contract.shoot(1,3, transact={"from": account0})
#     battleship_contract.shoot(2,1, transact={"from": account1})

#     assert not battleship_contract.has_winner()

#     battleship_contract.shoot(4,1, transact={"from": account0})

#     assert battleship_contract.has_winner()
#     assert battleship_contract.get_winner() == account0

# def test_player2_wins_on_board1(w3, battleship_board1):
#     account0 = w3.eth.accounts[0]
#     account1 = w3.eth.accounts[1]

#     battleship_contract = battleship_board1

#     battleship_contract.shoot(2,1, transact={"from": account0})
#     battleship_contract.shoot(1,1, transact={"from": account1})

#     # player1 misses
#     battleship_contract.shoot(0,0, transact={"from": account0})
#     battleship_contract.shoot(1,2, transact={"from": account1})

#     battleship_contract.shoot(1,1, transact={"from": account0})
#     battleship_contract.shoot(2,1, transact={"from": account1})

#     battleship_contract.shoot(1,2, transact={"from": account0})
#     battleship_contract.shoot(3,1, transact={"from": account1})

#     battleship_contract.shoot(1,3, transact={"from": account0})
#     assert not battleship_contract.has_winner()

#     battleship_contract.shoot(4,2, transact={"from": account1})

#     assert battleship_contract.has_winner()
#     assert battleship_contract.get_winner() == account1

# def test_player2_wins_on_board2(w3, battleship_board2):
#     account0 = w3.eth.accounts[0]
#     account1 = w3.eth.accounts[1]

#     battleship_contract = battleship_board2

#     battleship_contract.shoot(2,1, transact={"from": account0})
#     battleship_contract.shoot(1,1, transact={"from": account1})

#     # player1 misses
#     battleship_contract.shoot(0,0, transact={"from": account0})
#     battleship_contract.shoot(0,0, transact={"from": account1})

#     battleship_contract.shoot(1,1, transact={"from": account0})
#     battleship_contract.shoot(2,2, transact={"from": account1})

#     battleship_contract.shoot(1,2, transact={"from": account0})
#     battleship_contract.shoot(3,3, transact={"from": account1})

#     battleship_contract.shoot(1,3, transact={"from": account0})
#     assert not battleship_contract.has_winner()

#     battleship_contract.shoot(4,4, transact={"from": account1})

#     assert battleship_contract.has_winner()
#     assert battleship_contract.get_winner() == account1

# def test_wrong_player_starts(w3, battleship_board1):
#     account1 = w3.eth.accounts[1]

#     battleship_contract = battleship_board1

#     # Should not be allowed
#     with pytest.raises(TransactionFailed):
#         battleship_contract.shoot(1,1, transact={"from": account1})

# def test_cannot_shoot_after_winning(w3, battleship_board2):
#     account0 = w3.eth.accounts[0]
#     account1 = w3.eth.accounts[1]

#     battleship_contract = battleship_board2

#     battleship_contract.shoot(2,1, transact={"from": account0})
#     battleship_contract.shoot(1,1, transact={"from": account1})
#     battleship_contract.shoot(0,0, transact={"from": account0})
#     battleship_contract.shoot(0,0, transact={"from": account1})
#     battleship_contract.shoot(1,1, transact={"from": account0})
#     battleship_contract.shoot(2,2, transact={"from": account1})
#     battleship_contract.shoot(1,2, transact={"from": account0})
#     battleship_contract.shoot(3,3, transact={"from": account1})
#     battleship_contract.shoot(1,3, transact={"from": account0})
#     battleship_contract.shoot(4,4, transact={"from": account1})

#     # Should not be allowed from either player
#     with pytest.raises(TransactionFailed):
#         battleship_contract.shoot(4,3, transact={"from": account0})
#     with pytest.raises(TransactionFailed):
#         battleship_contract.shoot(4,3, transact={"from": account1})