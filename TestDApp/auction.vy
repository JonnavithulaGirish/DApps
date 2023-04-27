# Open Auction
# Adapted from https://docs.vyperlang.org/en/stable/vyper-by-example.html

struct Auction:
    beneficiary: address
    auctionStart: uint256
    auctionEnd: uint256
    highestBidder: address
    highestBid: uint256
    ended: bool

pendingReturns: public(HashMap[uint256, HashMap[address, uint256]])

AuctionMap : public(HashMap[uint256, Auction])

NFTIDToBidders: public(HashMap[uint256, DynArray[address, 100]])

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
def endAuction(_NFTid: uint256):
    assert block.timestamp >= self.AuctionMap[_NFTid].auctionEnd
    assert not self.AuctionMap[_NFTid].ended

    if self.AuctionMap[_NFTid].highestBidder == empty(address):
        self.AuctionMap[_NFTid].auctionEnd += 600
        return empty(address)

    self.AuctionMap[_NFTid].ended = True

    send(self.AuctionMap[_NFTid].beneficiary, self.AuctionMap[_NFTid].highestBid)

    for bidder in self.NFTIDToBidders[_NFTid]:
        pending_amount: uint256 = self.pendingReturns[_NFTid][msg.sender]
        self.pendingReturns[_NFTid][msg.sender] = 0
        send(msg.sender, pending_amount)
        
    return self.AuctionMap[_NFTid].highestBidder