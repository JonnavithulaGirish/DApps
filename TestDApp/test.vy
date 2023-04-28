# from vyper.interfaces import ERC20

# implements: ERC20

# balanceOf: public(HashMap[address, uint256])
# allowance: public(HashMap[address, HashMap[address, uint256]])

# import auctioninterface as OpenAuction
struct Auction:
    beneficiary: address
    auctionStart: uint256
    auctionEnd: uint256
    highestBidder: address
    highestBid: uint256
    ended: bool

interface OpenAuction:
    def startAuction(_NFTid: uint256): nonpayable
    def bid(_NFTid: uint256): payable
    def endAuction(_NFTid: uint256) -> address: nonpayable
    def pendingReturns(arg0: uint256, arg1: address) -> uint256: view
    def AuctionMap(arg0: uint256) -> Auction: view
    def NFTIDToBidders(arg0: uint256, arg1: uint256) -> address: view

#auction_instance : public(OpenAuction)

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
    currStake: uint256
    approverList: DynArray[address, 100]
    requestMsg: String[128] 
    NFTid: uint256
    isNotEmpty : bool
    uid: uint256
    hasRepaid: bool

struct PaymentPlan:
    amount: uint256
    time: uint256

LoanAccounts: HashMap[address, HashMap[uint256, DynArray[PaymentPlan, 12]]]     # loan account address -> [unique loan id -> payment plan]

ProposalsMap: HashMap[uint256, Proposal]        # unique loan id -> proposal information
ProposalCtr : uint256

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

NFTidCtr : uint256
NFTidToOwner : public(HashMap[uint256, address])
NFTidToActualOwner : public(HashMap[uint256, address])
NFTminter : address
NFTownerToTokenCount : public(HashMap[address, uint256])

@external
def __init__():
    self.totalFunds = 0
    self.fixedDepositMaturityPeriod = 600
    self.NFTminter = msg.sender
    self.ProposalCtr = 0

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
        pricipal: decimal = convert(_value, decimal)
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

@external
def NFTMint() -> bool:
    nftID : uint256 = self.NFTidCtr
    self.NFTidToOwner[nftID] = self
    self.NFTidToActualOwner[nftID] = self
    self.NFTidCtr += 1
    self.NFTownerToTokenCount[self] += 1
    OpenAuction(0x8340eB33A1483c421d1D2E80488a01523143921B).startAuction(nftID)
    return True

@external
@nonreentrant("lock")
def NFTCheckAuctionEnd(_NFTid: uint256): 
    assert _NFTid < self.NFTidCtr
    winner: address = OpenAuction(0x8340eB33A1483c421d1D2E80488a01523143921B).endAuction(_NFTid)
    assert winner != empty(address), "Auction not done yet"
    self._transferNFT(self, winner, _NFTid)

@internal
def _transferNFT(_from: address, _to: address, _tokenId: uint256):
    assert self.NFTidToOwner[_tokenId] == _from
    assert _to != empty(address)

    self.NFTidToOwner[_tokenId] = _to
    self.NFTidToActualOwner[self.NFTidCtr] = _to
    self.NFTownerToTokenCount[_from] -= 1
    self.NFTownerToTokenCount[_to] += 1

@view
@external
def NFTbalanceOf(_owner: address) -> uint256:
    assert _owner != empty(address)
    return self.NFTownerToTokenCount[_owner]

@view
@external
def NFTownerOf(_tokenId: uint256) -> address:
    owner: address = self.NFTidToOwner[_tokenId]
    assert owner != empty(address)
    return owner

@external
def NFTtransfer(_to: address, _tokenId: uint256):
    # only owner can transfer
    self._transferNFT(msg.sender, _to, _tokenId)

@external
@nonpayable
@nonreentrant("lock")
def createProposal(_recipient: address, _amount: uint256, _msg: String[128], _collateral: uint256):
    assert self.NFTidToOwner[_collateral] == msg.sender, "Using someone else's NFT as collateral!!"
    assert _amount > 0, "Can request loan for 0 amount!"
    _uid: uint256 = self.ProposalCtr
    self.ProposalCtr += 1
    self.ProposalsMap[_uid] = Proposal({
        recipient: _recipient, amount: _amount, approved: False, currStake: 0, approverList: [],
        requestMsg: _msg, NFTid: _collateral, isNotEmpty: True, uid: _uid, hasRepaid: False
        })
    # return _uid
    pass

@external
@nonpayable
@nonreentrant("lock")
def approveProposal(_uid: uint256):
    for approver in self.ProposalsMap[_uid].approverList:
        if msg.sender == approver:
            raise "Cannot approve twice!"
    
    # someone who has a fixed deposit with us can only approve
    flag : bool = False
    stakeHolders: DynArray[address, 100] = []
    totalStake: uint256 = 0
    for key in self.AccountAddresses:
        if self.Accounts[key].fixedBalance > 0:
            stakeHolders.append(key)
            totalStake += self.Accounts[key].fixedBalance

    for stkhldr in stakeHolders:
        if msg.sender == stkhldr:
            flag = True
    
    if flag == False:
        raise "Not a stake holder, cannot approve!"
    
    self.ProposalsMap[_uid].currStake += self.Accounts[msg.sender].fixedBalance
    self.ProposalsMap[_uid].approverList.append(msg.sender)

    if self.ProposalsMap[_uid].currStake*2 > totalStake and self.ProposalsMap[_uid].approved == False:
        #raw_call(self.ProposalsMap[_uid].recipient, b'', value=self.ProposalsMap[_uid].amount)
        self.ProposalsMap[_uid].approved = True

        # send Funds to recipient
        self.Accounts[self.ProposalsMap[_uid].recipient].loanRequests.append(self.ProposalsMap[_uid])
        # create loan account plan
        paymentplan : DynArray[PaymentPlan, 12] = []
        totalAmount: decimal = convert(self.ProposalsMap[_uid].amount, decimal)
        perUnit : decimal = totalAmount/12.0
        for i in range(1, 13):
            paymentplan.append(PaymentPlan({
                amount: convert(perUnit+totalAmount*1.1,uint256),
                time: block.timestamp + convert(600.0*  convert(i,decimal), uint256)
                }))

            totalAmount -= perUnit

        self.LoanAccounts[self.ProposalsMap[_uid].recipient][_uid] = paymentplan
        self.NFTidToOwner[self.ProposalsMap[_uid].NFTid] = self

        self.NFTownerToTokenCount[self] += 1
        self.NFTownerToTokenCount[self.ProposalsMap[_uid].recipient] -= 1

        send(self.ProposalsMap[_uid].recipient, self.ProposalsMap[_uid].amount)
    return

@external
@payable
def payLoanInstallment(_proposalid: uint256, _term: uint256):
    # assert self.LoanAccounts[msg.sender][_proposalid] != convert([],DynArray[PaymentPlan,12]), "Why service a loan that you have not taken?"
    assert self.LoanAccounts[msg.sender][_proposalid][_term].amount == msg.value, "payment plan of term doesnt match"

    self.LoanAccounts[msg.sender][_proposalid][_term].amount = 0
    return

# TODO checkLoanDefaults
@external
def checkLoanDefaults():
    for adrss in self.AccountAddresses:
        for proposal in self.Accounts[adrss].loanRequests:
            ctr : uint256 = 0
            for idx in range(12):
                pp: PaymentPlan = self.LoanAccounts[adrss][proposal.uid][idx]
                if block.timestamp >= pp.time and pp.amount != 0:
                    # default
                    # sell their collateral
                    OpenAuction(0x8340eB33A1483c421d1D2E80488a01523143921B).startAuction(proposal.NFTid)
                    self.NFTidToActualOwner[proposal.NFTid] = empty(address)
                elif block.timestamp >= pp.time and pp.amount == 0:
                    ctr += 1
            if ctr == 12 and self.ProposalsMap[proposal.uid].hasRepaid == False:
                self.ProposalsMap[proposal.uid].hasRepaid = True
                self.NFTidToOwner[proposal.NFTid] = proposal.recipient
