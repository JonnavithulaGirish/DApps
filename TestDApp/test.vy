# from vyper.interfaces import ERC20

# implements: ERC20

# balanceOf: public(HashMap[address, uint256])
# allowance: public(HashMap[address, HashMap[address, uint256]])
totalFunds: public(uint256)

# TODO add state that tracks proposals here
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

struct Proposal:
    recipient : address
    amount : uint256
    approved: bool
    approversTotalStake: uint256
    requestMsg: String[128] 
    isNotEmpty : bool
    

PendingProposals: HashMap[uint256, Proposal]
ProposalApprovalMap: HashMap[uint256, HashMap[address,bool]]

struct Account:
    accountBalance : uint256
    loanRequests: Proposal[100]
    isNotEmpty: bool

Accounts: HashMap[address, Account]
    


@external
def __init__():
    self.totalFunds = 0

@external
@payable
@nonreentrant("lock")
def CreateAccount(_from : address, _value : uint256):
    assert self.Accounts[_from].isNotEmpty == False, "Account already exits" 
    newAccount: Account = Account({accountBalance : _value, loanRequests: empty(Proposal[100]), isNotEmpty: True})
    self.Accounts[_from] = newAccount
    self.totalFunds += _value
    pass

@external
@payable
@nonreentrant("lock")
def Deposit(_from : address, _value : uint256):
    assert self.Accounts[_from].isNotEmpty == True, "Account doesn't exits" 
    self.Accounts[_from].accountBalance += _value
    self.totalFunds += _value
    pass

@external
@payable
@nonreentrant("lock")
def WithDraw(_from : address, _value : uint256):
    assert self.Accounts[_from].isNotEmpty == True, "Account doesn't exits" 
    assert self.Accounts[_from].accountBalance >= _value, "Account doesn't have enough funds"
    self.Accounts[_from].accountBalance -= _value
    self.totalFunds -= _value
    pass

@external
@nonpayable
@nonreentrant("lock")
def getBalance() -> uint256:
    return self.totalFunds

# @external
# @nonpayable
# @nonreentrant("lock")
# def sellToken(_value: uint256):
#     # TODO implement
#     assert self.balanceOf[msg.sender] >= _value, "Not enough funds available"
#     send(msg.sender, _value)
#     self.totalSupply -= _value
#     self.balanceOf[msg.sender] -= _value
#     pass

# @external
# def transfer(_to : address, _value : uint256) -> bool:
#     self.balanceOf[msg.sender] -= _value
#     self.balanceOf[_to] += _value
    
    
#     log Transfer(msg.sender, _to, _value)
#     return True


# @external
# def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
#     self.balanceOf[_from] -= _value
#     self.balanceOf[_to] += _value
#     self.allowance[_from][msg.sender] -= _value
#     log Transfer(_from, _to, _value)
#     return True

# @external
# def approve(_spender : address, _value : uint256) -> bool:
#     """
#     @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
#          Beware that changing an allowance with this method brings the risk that someone may use both the old
#          and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
#          race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
#          https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
#     @param _spender The address which will spend the funds.
#     @param _value The amount of tokens to be spent.
#     """
#     self.allowance[msg.sender][_spender] = _value
#     log Approval(msg.sender, _spender, _value)
#     return True

# @external
# @nonpayable
# @nonreentrant("lock")
# def createProposal(_uid: uint256, _recipient: address, _amount: uint256):
#     # TODO implement
#     assert self.Proposals[_uid].isNotEmpty == False, "Proposal Already exists with same id"
#     newProposal: Proposal = Proposal({recipient : _recipient, amount : _amount, approved: False, approversTotalStake: 0, isNotEmpty: True})
#     self.Proposals[_uid] = newProposal
#     pass

# @external
# @nonpayable
# @nonreentrant("lock")
# def approveProposal(_uid: uint256):
#     # TODO implement
#     assert self.Proposals[_uid].isNotEmpty == True, "No such Proposal exits with given id"
#     assert self.ProposalApprovalMap[_uid][msg.sender] != True, "Already Approved"
#     assert self.balanceOf[msg.sender] > 0, "No Sufficient stake available to vote"
#     self.Proposals[_uid].approversTotalStake +=self.balanceOf[msg.sender]
#     self.ProposalApprovalMap[_uid][msg.sender]= True
#     if(self.Proposals[_uid].approversTotalStake >  self.totalSupply/2 and self.Proposals[_uid].approved == False):
#         self.Proposals[_uid].approved = True
#         send(self.Proposals[_uid].recipient,self.Proposals[_uid].amount)
#     pass
