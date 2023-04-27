
struct Auction:
    beneficiary: address
    auctionStart: uint256
    auctionEnd: uint256
    highestBidder: address
    highestBid: uint256
    ended: bool

# External Interfaces
interface OpenAuction:
    def startAuction(_NFTid: uint256): nonpayable
    def bid(_NFTid: uint256): payable
    def endAuction(_NFTid: uint256) -> address: nonpayable
    def pendingReturns(arg0: uint256, arg1: address) -> uint256: view
    def AuctionMap(arg0: uint256) -> Auction: view
    def NFTIDToBidders(arg0: uint256, arg1: uint256) -> address: view

