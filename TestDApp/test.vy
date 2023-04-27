# from vyper.interfaces import ERC20

# implements: ERC20

# balanceOf: public(HashMap[address, uint256])
# allowance: public(HashMap[address, HashMap[address, uint256]])
totalFunds: public(uint256)
fixedDepositMaturityPeriod: public(uint256)

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

struct History:
    amount: uint256
    time: uint256
    isDeposit : bool

struct Account:
    savingBalance : uint256
    fixedBalance : uint256
    loanRequests: DynArray[Proposal, 100]
    isNotEmpty: bool
    savingBalanceHistory: DynArray[History, 100]
    fixedDepositCounter: uint256

Accounts: public(HashMap[address, Account])

fixedDepositsMap: public(HashMap[address, HashMap[uint256, History]])

AccountAddresses: public(DynArray[address,1000])
AccountAddressesIndex: public(uint256)


@external
def __init__():
    self.totalFunds = 0
    self.fixedDepositMaturityPeriod = 600

@external
@payable
@nonreentrant("lock")
def CreateAccount():
    assert self.Accounts[msg.sender].isNotEmpty == False, "Account already exits" 
    newAccount: Account = Account(
        {
            savingBalance : msg.value,
            fixedBalance: 0,
            loanRequests: [],
            isNotEmpty: True,
            savingBalanceHistory: [History({ amount:  msg.value, time: block.timestamp, isDeposit: True })],
            fixedDepositCounter: 0
        })
    self.AccountAddresses.append(msg.sender)
    self.AccountAddressesIndex+=1
    self.Accounts[msg.sender] = newAccount
    pass

@external
@payable
@nonreentrant("lock")
def Deposit(_type:uint256):
    assert self.Accounts[msg.sender].isNotEmpty == True, "Account doesn't exits" 
    if(_type == 0):
        self.Accounts[msg.sender].savingBalance +=  msg.value
        self.Accounts[msg.sender].savingBalanceHistory.append(History({ amount:  msg.value, time: block.timestamp, isDeposit: True }))
    else:
        self.Accounts[msg.sender].fixedBalance +=  msg.value
        self.fixedDepositsMap[msg.sender][self.Accounts[msg.sender].fixedDepositCounter]= History({ amount:  msg.value, time: block.timestamp, isDeposit: True })
        self.Accounts[msg.sender].fixedDepositCounter += 1
    pass

@external
@nonreentrant("lock")
def WithDraw(_value : uint256, _type: uint256, _fixedDepositMapIndex: uint256 = empty(uint256)):
    assert self.Accounts[msg.sender].isNotEmpty == True, "Account doesn't exits" 
    if(_type == 0):
        assert self.Accounts[msg.sender].savingBalance >= _value, "Account doesn't have enough savings"
        self.Accounts[msg.sender].savingBalanceHistory.append(History({ amount:  _value, time: block.timestamp, isDeposit: False }))
    else:
        assert block.timestamp - self.fixedDepositsMap[msg.sender][_fixedDepositMapIndex].time >= self.fixedDepositMaturityPeriod, "The fixed deposit transaction is not Matured yet."
        assert self.fixedDepositsMap[msg.sender][_fixedDepositMapIndex].amount >= _value, "The fixed deposit transaction doesn't have enough funds."
        self.Accounts[msg.sender].fixedBalance -= _value
        self.fixedDepositsMap[msg.sender][_fixedDepositMapIndex].amount -= _value
        pricipal: decimal = convert(_value * 10**18, decimal)
        compoundTerms: decimal = convert((block.timestamp - self.fixedDepositsMap[msg.sender][_fixedDepositMapIndex].time)/300, decimal)
        total : uint256 = convert(pricipal * 1.07 * compoundTerms, uint256)
        send(msg.sender, total)
    pass

@external
@nonpayable
@nonreentrant("lock")
def getBalance() -> uint256:
    return self.balance

@external
@payable
@nonreentrant("lock")
def distributeSavingsInterest():
    for key in self.AccountAddresses:
        value: decimal= 0.0
        for index in self.Accounts[key].savingBalanceHistory:
            pricipal: decimal = convert(index.amount * 10**18, decimal)
            compoundTerms: decimal = convert((block.timestamp - index.time)/300, decimal)
            total: decimal =pricipal * 1.07 * compoundTerms 
            if(index.isDeposit == True):
                value+= total
            else:
                value -= total
            index.time= block.timestamp  
        send(key, convert(value,uint256))
    pass

