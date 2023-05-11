# Our main contract that handles 
# 1. Setting up an savings account
# 2. Start a fixed deposit
# 3. Purchase NFT through an auction
# 4. Request a loan proposal 

# Auction interface for the NFT marketplace
# check auction.vy

event Transfer:
    amount : uint256
    depositType: uint256
    index: uint256

event myString:
    message : String[100]

struct Auction:
    beneficiary: address
    auctionStart: uint256
    auctionEnd: uint256
    highestBidder: address
    highestBid: uint256
    ended: bool
    biddersCtr: uint256

# interface OpenAuction:
#     def startAuction(_NFTid: uint256): nonpayable
#     def bid(_NFTid: uint256): payable
#     def endAuction(_NFTid: uint256) -> address: nonpayable
#     def pendingReturns(arg0: uint256, arg1: address) -> uint256: view
#     def AuctionMap(arg0: uint256) -> Auction: view
#     def NFTIDToBidders(arg0: uint256, arg1: uint256) -> address: view

# Time until a fixed deposit matures
fixedDepositMaturityPeriod: public(uint256)

# Loan proposal template
struct Proposal:
    recipient : address     # loan requestor
    amount : uint256        # loan amount
    approved: bool          # has the proposal been approved?
    currStake: uint256      # current stake of acceptors
    approverList: DynArray[address, 100]    # list of approvers
    requestMsg: String[128]     # special message to approvers to accept loan
    NFTid: uint256          # ID of the NFT used as collateral
    isNotEmpty : bool       # check if proposal object is empty
    uid: uint256            # loan proposal's unique id
    hasRepaid: bool         # has the requestor repaid the loan?

# Contains loan amount(with interest) to be repaid by time (deadline)
struct PaymentPlan:
    amount: uint256
    time: uint256

# Loan must be repaid in 12 installments.
# Below hashmap tracks installments of all the loans of a particular user
LoanAccounts: public(HashMap[address, HashMap[uint256, DynArray[PaymentPlan, 12]]])     # loan account address -> [unique loan proposal id -> payment plan]

# Below variables track the issued loan proposals
ProposalsMap: public(HashMap[uint256, Proposal])        # unique loan id -> proposal information
ProposalCtr : public(uint256)                       # generates unique loan id

# transaction history
struct History:
    amount: uint256     # transacted amount
    time: uint256       # timestamp of transaction
    isDeposit : bool    # deposit/withdrawal?

# the account template
struct Account:
    savingBalance : uint256                             # savings account balance
    fixedBalance : uint256                              # fixed account balance = sum of fixed deposits
    loanRequests: DynArray[uint256, 100]               # list of loan requests
    isNotEmpty: bool                                    # check if Account object is empty
    savingBalanceHistory: DynArray[History, 100]        # savings account transaction history
    fixedDepositCounter: uint256                        # tracks fixed deposits id in fixedDepositsMap

Accounts: public(HashMap[address, Account])             # list of accounts created on this smart contract

fixedDepositsMap: public(HashMap[address, HashMap[uint256, History]])   # account address -> fixed deposit id -> transcation history

AccountAddresses: public(DynArray[address,1000])        # list of account addresses, used to iterate Accounts hashmap
AccountAddressesIndex: public(uint256)                  # tracks # unique accounts, needed?       


# NFT member variables
NFTidCtr : public(uint256)                                  # tracks unique NFT IDs
NFTidToOwner : public(HashMap[uint256, address])            # tracks NFT ownership
NFTownerToTokenCount : public(HashMap[address, uint256])    # Not really needed, but tracks # NFT owned by an user


# tracks refunds for non-winners
pendingReturns: public(HashMap[uint256, HashMap[address, uint256]])

# list of submitted auctions, NFTID to auction template
AuctionMap : public(HashMap[uint256, Auction])

# List of bidders in a particular auction
NFTIDToBidders: public(HashMap[uint256, DynArray[address, 100]])


@external
def __init__():
    self.fixedDepositMaturityPeriod = 600           # 10 minutes
    self.ProposalCtr = 0
    self.NFTidCtr = 0

@external
@payable
@nonreentrant("lock")
def CreateAccount():
    # create a new account on sender's address
    assert self.Accounts[msg.sender].isNotEmpty == False, "Account already exits"
    assert msg.value >= 100, "Minimum balance not met"
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
    self.AccountAddressesIndex += 1
    self.Accounts[msg.sender] = newAccount
    return

@external
@payable
@nonreentrant("lock")
def Deposit(_type: uint256):
    # deposit money into the contract
    assert self.Accounts[msg.sender].isNotEmpty == True, "Account doesn't exist"
    assert msg.value > 0, "Cannot deposit 0 funds" 
    if(_type == 0):
        # savings
        self.Accounts[msg.sender].savingBalance +=  msg.value
        self.Accounts[msg.sender].savingBalanceHistory.append(History({ amount:  msg.value, time: block.timestamp, isDeposit: True }))
    else:
        # fixed
        self.Accounts[msg.sender].fixedBalance +=  msg.value
        self.fixedDepositsMap[msg.sender][self.Accounts[msg.sender].fixedDepositCounter] = History({ amount:  msg.value, time: block.timestamp, isDeposit: True })
        self.Accounts[msg.sender].fixedDepositCounter += 1
    return

@external
@payable
@nonreentrant("lock")
def WithDraw(_value : uint256, _type: uint256, _fixedDepositMapIndex: uint256 = empty(uint256)):
    # withdraw money from contract
    assert self.Accounts[msg.sender].isNotEmpty == True, "Account doesn't exits"
    assert _value > 0, "Cannot withdraw 0 funds"
    if(_type == 0):
        # savings
        assert self.Accounts[msg.sender].savingBalance >= _value, "Account doesn't have enough savings"
        self.Accounts[msg.sender].savingBalanceHistory.append(History({ amount:  _value, time: block.timestamp, isDeposit: False }))
        self.Accounts[msg.sender].savingBalance -= _value
    else:
        # fixed
        log myString("In fixed deposit logic -a")
        # assert block.timestamp - self.fixedDepositsMap[msg.sender][_fixedDepositMapIndex].time >= self.fixedDepositMaturityPeriod, "The fixed deposit transaction has not matured yet."
        log myString("In fixed deposit logic -b")
        assert self.fixedDepositsMap[msg.sender][_fixedDepositMapIndex].amount >= _value, "The fixed deposit transaction doesn't have enough funds."
        log myString("In fixed deposit logic -c")
        self.Accounts[msg.sender].fixedBalance -= _value
        log myString("In fixed deposit logic -d")
        self.fixedDepositsMap[msg.sender][_fixedDepositMapIndex].amount -= _value
        log myString("In fixed deposit logic -e")
        
        # calculate interest
        pricipal: decimal = convert(_value, decimal)
        log myString("In fixed deposit logic -f")
        log Transfer(_value, _type, _fixedDepositMapIndex)
        numTerms: decimal = convert((block.timestamp - self.fixedDepositsMap[msg.sender][_fixedDepositMapIndex].time)/300, decimal)
        log myString("In fixed deposit logic -g")
        total : decimal = pricipal * 1.07 * numTerms    # principal guaranteed to be large enough to not cause underflow
        log myString("In fixed deposit logic -h")
        send(msg.sender, convert(total,uint256))
        log myString("In fixed deposit logic -i")
    return

@external
@nonpayable
def getBalance() -> uint256:
    # get smart contract wei balance, needed?
    return self.balance

@external
@payable
@nonreentrant("lock")
def distributeSavingsInterest():
    # called periodically by web server to distribute savings interest to account holders
    for adrs in self.AccountAddresses:
        value: decimal = 0.0
        for hist in self.Accounts[adrs].savingBalanceHistory:
            pricipal: decimal = convert(hist.amount, decimal)
            numTerms: decimal = convert((block.timestamp - hist.time)/300, decimal)
            total: decimal = pricipal * .07 * numTerms 
            if(hist.isDeposit == True):
                value += total
            else:
                value -= total
            hist.time= block.timestamp           # update to avoid repaying interest for the same period again
        send(adrs, convert(value, uint256))      # distribute interest
    return

@external
@payable
def NFTMint():
    # create NFT and start auction
    nftID : uint256 = self.NFTidCtr
    self.NFTidToOwner[nftID] = self             # set contract as owner until auction is complete
    self.NFTidCtr += 1
    self.NFTownerToTokenCount[self] += 1
    self.startAuction(nftID)
    return

@external
@payable
@nonreentrant("lock")
def NFTCheckAuctionEnd(_NFTid: uint256):
    # check periodically from webserver to identify owner of NFT after auction ends
    assert _NFTid < self.NFTidCtr , "modda kudu"
    winner: address = self.endAuction(_NFTid)
    # assert winner != empty(address), "Auction not done yet"
    if(winner == empty(address)):
        return
    self._transferNFT(self, winner, _NFTid)
    return

@internal
@payable
def _transferNFT(_from: address, _to: address, _tokenId: uint256):
    assert self.NFTidToOwner[_tokenId] == _from
    assert _to != empty(address)

    self.NFTidToOwner[_tokenId] = _to
    self.NFTownerToTokenCount[_from] -= 1
    self.NFTownerToTokenCount[_to] += 1
    return

@view
@external
def NFTbalanceOf(_owner: address) -> uint256:
    assert _owner != empty(address)
    # returns # of NFTs owned by _owner, needed?
    return self.NFTownerToTokenCount[_owner]

@view
@external
def NFTownerOf(_tokenId: uint256) -> address:
    # return owner of _tokenid, needed?
    owner: address = self.NFTidToOwner[_tokenId]
    assert owner != empty(address)
    return owner

@external
@payable
def NFTtransfer(_to: address, _tokenId: uint256):
    assert _tokenId < self.NFTidCtr, "cannot transfer non-existent NFT"
    # only owner can transfer
    self._transferNFT(msg.sender, _to, _tokenId)
    return

@external
@payable
@nonreentrant("lock")
def createProposal(_recipient: address, _amount: uint256, _msg: String[128], _collateral: uint256):
    # submit a loan proposal to the contract
    assert _recipient != empty(address), "recipient cannot be empty"
    assert _recipient in self.AccountAddresses, "not an account holder!"
    assert self.NFTidToOwner[_collateral] == msg.sender, "Using someone else's NFT as collateral!!"
    assert _amount > 0, "Can request loan for 0 amount!"

    _uid: uint256 = self.ProposalCtr
    self.ProposalCtr += 1
    self.ProposalsMap[_uid] = Proposal({
        recipient: _recipient, amount: _amount, approved: False, currStake: 0, approverList: [],
        requestMsg: _msg, NFTid: _collateral, isNotEmpty: True, uid: _uid, hasRepaid: False
        })
    return

@external
@payable
@nonreentrant("lock")
def approveProposal(_uid: uint256):
    assert _uid < self.ProposalCtr, "proposal doesn't exist"
    for approver in self.ProposalsMap[_uid].approverList:
        if msg.sender == approver:
            raise "Cannot approve twice!"
    
    # someone who has a fixed deposit with us can only approve
    flag : bool = False
    
    #create stakeHolders list
    stakeHolders: DynArray[address, 100] = []
    totalStake: uint256 = 0
    for adrs in self.AccountAddresses:
        if self.Accounts[adrs].fixedBalance > 0:
            stakeHolders.append(adrs)
            totalStake += self.Accounts[adrs].fixedBalance

    for stkhldr in stakeHolders:
        if msg.sender == stkhldr:
            flag = True
    
    if flag == False:
        raise "Not a stake holder, cannot approve!"
    
    self.ProposalsMap[_uid].currStake += self.Accounts[msg.sender].fixedBalance
    self.ProposalsMap[_uid].approverList.append(msg.sender)

    # loan approved if current approvers' stake > majority of stake
    if self.ProposalsMap[_uid].currStake * 2 > totalStake and self.ProposalsMap[_uid].approved == False:
        self.ProposalsMap[_uid].approved = True

        # send funds to recipient
        
        self.Accounts[self.ProposalsMap[_uid].recipient].loanRequests.append(_uid)
        
        # create loan payment plan
        installments : DynArray[PaymentPlan, 12] = []
        totalAmount: decimal = convert(self.ProposalsMap[_uid].amount, decimal)
        perUnit : decimal = totalAmount/12.0
        for i in range(1, 13):
            installments.append(PaymentPlan({
                amount: convert(perUnit + totalAmount * 1.1 , uint256),
                time: block.timestamp + convert(600.0 * convert(i, decimal), uint256)
                }))

            totalAmount -= perUnit

        self.LoanAccounts[self.ProposalsMap[_uid].recipient][_uid] = installments
        self.NFTidToOwner[self.ProposalsMap[_uid].NFTid] = self
        
        # claim collateral
        self.NFTownerToTokenCount[self] += 1
        self.NFTownerToTokenCount[self.ProposalsMap[_uid].recipient] -= 1

        # disburse funds
        send(self.ProposalsMap[_uid].recipient, self.ProposalsMap[_uid].amount)
    return

@external
@payable
def payLoanInstallment(_proposalid: uint256, _term: uint256):
    # payback installment
    assert _proposalid < self.ProposalCtr, "loan id incorrect"
    assert _term >= 1 and _term < 13, "incorrect term"
    assert _proposalid in self.Accounts[msg.sender].loanRequests, "why paying someone else's loan bruh?"
    assert self.LoanAccounts[msg.sender][_proposalid][_term].amount == msg.value, "payment plan of term doesnt match with sent value"
    assert self.LoanAccounts[msg.sender][_proposalid][_term].time >= block.timestamp, "already defaulted, cant save your nft now"

    self.LoanAccounts[msg.sender][_proposalid][_term].amount = 0
    return

@external
@payable
def checkLoanDefaults():
    # periodically called to check if someone defaulted their loan
    for adrss in self.AccountAddresses:
        for proposalid in self.Accounts[adrss].loanRequests:
            ctr : uint256 = 0
            for idx in range(12):
                pp: PaymentPlan = self.LoanAccounts[adrss][proposalid][idx]
                if block.timestamp >= pp.time and pp.amount != 0:
                    # this user has defaulted on his loan
                    # sell their collateral
                    self.startAuction(self.ProposalsMap[proposalid].NFTid)
                elif block.timestamp >= pp.time and pp.amount == 0:
                    ctr += 1
            # if a loan is repaid, reassign NFT back to loan requestor
            if ctr == 12 and self.ProposalsMap[proposalid].hasRepaid == False:
                self.ProposalsMap[proposalid].hasRepaid = True
                self._transferNFT(self, self.ProposalsMap[proposalid].recipient, self.ProposalsMap[proposalid].NFTid)
    return



@internal
@payable
def startAuction(_NFTid: uint256):
    # start aution on _NFTid
    self.AuctionMap[_NFTid] = Auction({
        beneficiary: msg.sender,
        auctionStart: block.timestamp,
        auctionEnd: block.timestamp + 600,        # ends 10 mins after start time
        highestBidder: empty(address),            # noone has bid yet
        highestBid: 0,
        ended: False,
        biddersCtr: 0
    })

@external
@payable
def bid(_NFTid: uint256):
    # bid for _NFTid
    assert block.timestamp >= self.AuctionMap[_NFTid].auctionStart
    assert block.timestamp < self.AuctionMap[_NFTid].auctionEnd
    assert msg.value > self.AuctionMap[_NFTid].highestBid
    # track refund of prev highest bidder
    self.pendingReturns[_NFTid][self.AuctionMap[_NFTid].highestBidder] += self.AuctionMap[_NFTid].highestBid
    self.AuctionMap[_NFTid].highestBidder = msg.sender
    self.AuctionMap[_NFTid].highestBid = msg.value

    if msg.sender not in self.NFTIDToBidders[_NFTid]:
        self.NFTIDToBidders[_NFTid].append(msg.sender)
        self.AuctionMap[_NFTid].biddersCtr += 1

@internal
@payable
def endAuction(_NFTid: uint256) -> address:
    # assert block.timestamp >= self.AuctionMap[_NFTid].auctionEnd, "Auction Still in progress"
    # if block.timestamp < self.AuctionMap[_NFTid].auctionEnd:
    #     return empty(address)
    assert not self.AuctionMap[_NFTid].ended, "Auction already ended"

    if self.AuctionMap[_NFTid].highestBidder == empty(address):
        self.AuctionMap[_NFTid].auctionEnd += 600
        return empty(address)

    self.AuctionMap[_NFTid].ended = True

    send(self.AuctionMap[_NFTid].beneficiary, self.AuctionMap[_NFTid].highestBid)

    # refund non-winners
    for i in range(100):
        # hack to avoid a random vyper error not allowing to iterate over array :/
        if i >= self.AuctionMap[_NFTid].biddersCtr:
            break
        
        bidder: address =  self.NFTIDToBidders[_NFTid][i]
        if bidder != self.AuctionMap[_NFTid].highestBidder:
            pending_amount: uint256 = self.pendingReturns[_NFTid][bidder]
            self.pendingReturns[_NFTid][bidder] = 0
            send(bidder, pending_amount)
    
    # return winner so that main contract can transfer the NFT
    return self.AuctionMap[_NFTid].highestBidder