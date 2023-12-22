# Solidity API

## AuctionsContract

### Contract
AuctionsContract : SolidityAuction/AuctionsContract.sol

 --- 
### Functions:
### createAuction

```solidity
function createAuction(string _auctionName, string _auctionDesc, uint256 _auctionStartDate, uint256 _auctionEndDate) public returns (uint256)
```

Creates an auction and returns auctionID so it can be looked up
for easy conversion of time use this calculator: https://www.unixtimestamp.com/  
    WARNING: If you use the calculator be mindful of timezones. Calculator uses your local timezone when you enter "Date and Time".

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _auctionName | string | The name of the auction, i.e. Honda Civic |
| _auctionDesc | string | Details, i.e. "used, 10 000km, excellent condition" |
| _auctionStartDate | uint256 | unix timestamp of the starting date. |
| _auctionEndDate | uint256 | unix timestamp of the end date. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the ID of the auction as an integer |

### bid

```solidity
function bid(uint256 _auctionID) external payable returns (uint256)
```

Creates a bid based on payment and returns the ID of the bid
    after the auction ends ether will be transfered on loss otherwise auction ownership
if a bid already exists, add the payment to existing bid instead

_check that the auction exists with require. ID starts counting from 1 so otherwise its default [0]_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _auctionID | uint256 | the ID of the auction to bid on |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the ID of the bid as an integer |

### retrieveAuction

```solidity
function retrieveAuction(uint256 _auctionID) public view returns (struct AuctionsContract.AUCTION)
```

_check that the auction exists with require. ID starts counting from 1 so otherwise its default zero_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct AuctionsContract.AUCTION | the auction (struct) with given _auction_ID. |

### retrieveBids

```solidity
function retrieveBids(uint256 _auctionID) public view returns (struct AuctionsContract.BID[])
```

_check that the auction exists with require. ID starts counting from 1 so otherwise its default zero_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct AuctionsContract.BID[] | an array of bids (struct) for the auction with given auction_ID. |

### claimAuction

```solidity
function claimAuction(uint256 _auctionID) external returns (string)
```

Iterates through the auctions bids to find the biggest.  
    After transfering ownership to the biggest bidder, returns caller's bid if elligible

_this implementation is not optimal, it is for simplicity. There are many thinigs to consider regarding gas. For example:  
    total gas spent to return all bids will be significantly higher, but if one were to return it for all then that one would be unfairly charged.  
    therefore the simplest implementation was followed since this is an assignment. Implement another one if gas is an issue._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _auctionID | uint256 | the ID of the auction to be claimed |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | a message or an error message regarding changes |

### getCurrentTime

```solidity
function getCurrentTime() external view returns (uint256)
```

returns current time if a double check is needed. ~314 gas

