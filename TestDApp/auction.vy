# Open Auction
# Adapted from https://docs.vyperlang.org/en/stable/vyper-by-example.html
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

implements: OpenAuction

pendingReturns: public(HashMap[uint256, HashMap[address, uint256]])

AuctionMap : public(HashMap[uint256, Auction])

NFTIDToBidders: public(HashMap[uint256, DynArray[address, 100]])

@external
def startAuction(_NFTid: uint256):
    self.AuctionMap[_NFTid] = Auction({
        beneficiary: msg.sender,
        auctionStart: block.timestamp,
        auctionEnd: block.timestamp+600,
        highestBidder: empty(address),
        highestBid: 0,
        ended: False
    })

@external
@payable
def bid(_NFTid: uint256):
    assert block.timestamp >= self.AuctionMap[_NFTid].auctionStart
    assert block.timestamp < self.AuctionMap[_NFTid].auctionEnd
    assert msg.value > self.AuctionMap[_NFTid].highestBid
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

    for i in range(100):
        if self.NFTIDToBidders[_NFTid][i] == empty(address):
            break
        bidder: address =  self.NFTIDToBidders[_NFTid][i]
        if bidder != self.AuctionMap[_NFTid].highestBidder:
            pending_amount: uint256 = self.pendingReturns[_NFTid][bidder]
            self.pendingReturns[_NFTid][bidder] = 0
            send(bidder, pending_amount)
        
    return self.AuctionMap[_NFTid].highestBidder