# Open Auction
# Adapted from https://docs.vyperlang.org/en/stable/vyper-by-example.html
struct Auction:
    beneficiary: address        # who gets funds at the end of auction, basically our main contract
    auctionStart: uint256       # auction start time
    auctionEnd: uint256         # auction end time, bidders typically bid within this time
    highestBidder: address      # current highest bidder of the auction
    highestBid: uint256         # highest bidder's bid
    ended: bool                 # has the auction ended?

interface OpenAuction:
    def startAuction(_NFTid: uint256): nonpayable
    def bid(_NFTid: uint256): payable
    def endAuction(_NFTid: uint256) -> address: nonpayable
    def pendingReturns(arg0: uint256, arg1: address) -> uint256: view
    def AuctionMap(arg0: uint256) -> Auction: view
    def NFTIDToBidders(arg0: uint256, arg1: uint256) -> address: view

implements: OpenAuction

# tracks refunds for non-winners
pendingReturns: public(HashMap[uint256, HashMap[address, uint256]])

# list of submitted auctions, NFTID to auction template
AuctionMap : public(HashMap[uint256, Auction])

# List of bidders in a particular auction
NFTIDToBidders: public(HashMap[uint256, DynArray[address, 100]])

@external
def startAuction(_NFTid: uint256):
    # start aution on _NFTid
    self.AuctionMap[_NFTid] = Auction({
        beneficiary: msg.sender,
        auctionStart: block.timestamp,
        auctionEnd: block.timestamp + 600,        # ends 10 mins after start time
        highestBidder: empty(address),            # noone has bid yet
        highestBid: 0,
        ended: False
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

@external
@nonreentrant("lock")
def endAuction(_NFTid: uint256) -> address:
    assert block.timestamp >= self.AuctionMap[_NFTid].auctionEnd
    assert not self.AuctionMap[_NFTid].ended

    if self.AuctionMap[_NFTid].highestBidder == empty(address):
        self.AuctionMap[_NFTid].auctionEnd += 600
        return empty(address)

    self.AuctionMap[_NFTid].ended = True

    send(self.AuctionMap[_NFTid].beneficiary, self.AuctionMap[_NFTid].highestBid)

    # refund non-winners
    for i in range(100):
        # hack to avoid a random vyper error not allowing to iterate over array :/
        if self.NFTIDToBidders[_NFTid][i] == empty(address):
            break
        
        bidder: address =  self.NFTIDToBidders[_NFTid][i]
        if bidder != self.AuctionMap[_NFTid].highestBidder:
            pending_amount: uint256 = self.pendingReturns[_NFTid][bidder]
            self.pendingReturns[_NFTid][bidder] = 0
            send(bidder, pending_amount)
    
    # return winner so that main contract can transfer the NFT
    return self.AuctionMap[_NFTid].highestBidder