// SPDX-License-Identifier: MIT
/// @title An auction managing smart contract
/// @author Georgios Pappas
/// @author Christakis Georgiou
/// @author Stavri Metaxa
/// @notice This smart contract will hold information about auctions, bidders (and ammount).
///     When the auction ends the users can either get ownership of the auction or their ETH returned
pragma solidity 0.8.23;

contract AuctionsContract {
    uint256 lastAuctionID = 0;
    uint256 lastBidID = 0;

    struct AUCTION {
        uint256 auctionID;
        string auctionName;
        string auctionDesc;
        uint256 auctionStartDate;
        uint256 auctionEndDate;
        address auctionOwner;
    }

    struct BID {
        uint256 bidID;
        address bidder;
        uint256 ammount;
        bool returned;
    }

    /// @dev key = auctionID
    /// @dev item = auction struct
    mapping(uint256 => AUCTION) private auctions;

    /// @dev key = auctionID
    /// @dev item = bidders
    mapping(uint256 => BID[]) private bidsInAuction;

    /// @notice Creates an auction and returns auctionID so it can be looked up
    /// @notice for easy conversion of time use this calculator: https://www.unixtimestamp.com/  
    ///     WARNING: If you use the calculator be mindful of timezones. Calculator uses your local timezone when you enter "Date and Time".
    /// @param _auctionName The name of the auction, i.e. Honda Civic
    /// @param _auctionDesc Details, i.e. "used, 10 000km, excellent condition"
    /// @param _auctionStartDate unix timestamp of the starting date.
    /// @param _auctionEndDate unix timestamp of the end date.
    /// @return the ID of the auction as an integer
    function createAuction(
        string calldata _auctionName,
        string calldata _auctionDesc,
        uint256 _auctionStartDate,
        uint256 _auctionEndDate
    ) public returns (uint256) {
        require(
            _auctionStartDate < _auctionEndDate,
            "Start date can't be smaller than end date"
        );
        require(
            block.timestamp <= _auctionStartDate,
            "Start date can't be sooner than current"
        );
        lastAuctionID = lastAuctionID + 1;
        AUCTION memory newAuction = AUCTION({
            auctionID: lastAuctionID,
            auctionName: _auctionName,
            auctionDesc: _auctionDesc,
            auctionStartDate: _auctionStartDate,
            auctionEndDate: _auctionEndDate,
            auctionOwner: msg.sender
        });
        auctions[lastAuctionID] = newAuction;
        return lastAuctionID;
    }

    /// @dev check that the auction exists with require. ID starts counting from 1 so otherwise its default [0]
    /// @notice Creates a bid based on payment and returns the ID of the bid
    ///     after the auction ends ether will be transfered on loss otherwise auction ownership
    /// @notice if a bid already exists, add the payment to existing bid instead
    /// @param _auctionID the ID of the auction to bid on
    /// @return the ID of the bid as an integer
    function bid(uint256 _auctionID) external payable returns (uint256) {
        require(
            auctions[_auctionID].auctionID != 0,
            "The auction with the given ID doesn't exist"
        );
        require(msg.value > 0, "Bidding is not allowed without an ammount");
        for (uint256 i = 0; i < bidsInAuction[_auctionID].length; i++){
            if(bidsInAuction[_auctionID][i].bidder == msg.sender){
                bidsInAuction[_auctionID][i].ammount += msg.value;
                return bidsInAuction[_auctionID][i].bidID;
            }
        }
        lastBidID = lastBidID + 1;
        BID memory newBid = BID({
            bidID: lastBidID,
            bidder: msg.sender,
            ammount: msg.value,
            returned: false
        });
        bidsInAuction[_auctionID].push(newBid);
        return lastBidID;
    }

    /// @dev check that the auction exists with require. ID starts counting from 1 so otherwise its default zero
    /// @return the auction (struct) with given _auction_ID.
    function retrieveAuction(uint256 _auctionID)
        public
        view
        returns (AUCTION memory)
    {
        require(
            auctions[_auctionID].auctionID != 0,
            "The auction with the given ID doesn't exist"
        );
        return auctions[_auctionID];
    }

    /// @dev check that the auction exists with require. ID starts counting from 1 so otherwise its default zero
    /// @return an array of bids (struct) for the auction with given auction_ID.
    function retrieveBids(uint256 _auctionID)
        public
        view
        returns (BID[] memory)
    {
        require(
            auctions[_auctionID].auctionID != 0,
            "The auction with the given ID doesn't exist"
        );
        return bidsInAuction[_auctionID];
    }

    /// @notice Iterates through the auctions bids to find the biggest.  
    ///     After transfering ownership to the biggest bidder, returns caller's bid if elligible
    /// @dev this implementation is not optimal, it is for simplicity. There are many thinigs to consider regarding gas. For example:  
    ///     total gas spent to return all bids will be significantly higher, but if one were to return it for all then that one would be unfairly charged.  
    ///     therefore the simplest implementation was followed since this is an assignment. Implement another one if gas is an issue.
    /// @param _auctionID the ID of the auction to be claimed
    /// @return a message or an error message regarding changes
    function claimAuction(uint256 _auctionID) external returns (string memory) {
        require(
            auctions[_auctionID].auctionID != 0,
            "The auction with the given ID doesn't exist"
        );
        AUCTION memory auction = auctions[_auctionID];
        require(
            block.timestamp >= auction.auctionEndDate,
            "The auction is still ongoing"
        );
        BID[] storage bids = bidsInAuction[_auctionID];
        if (bids.length == 0) return "There were no bidders for given auction.";

        BID memory biggestBid; 
        BID storage senderBid = bids[0]; /// @dev This is force assignment for pointer. Be very careful if you change it, you might return ETH to a non bidder.
        bool hasSenderBidded;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].bidder == msg.sender) {
                senderBid = bids[i];
                hasSenderBidded = true;
            }
            else if (biggestBid.bidID != 0 && bids[i].ammount > biggestBid.ammount) 
                biggestBid = bids[i];
        }
        auctions[_auctionID].auctionOwner = biggestBid.bidder;

        if (hasSenderBidded && auction.auctionOwner != senderBid.bidder && !senderBid.returned){
            payable(msg.sender).transfer(senderBid.ammount);
            senderBid.returned = true;
            return "Your bid has been returned";
        }
        //could print a message to let the caller know if the owner remains the same but it's unnecessary gas
        return "The auction owner has been updated"; 
    }

    /// @notice returns current time if a double check is needed. ~314 gas
    function getCurrentTime() external view returns(uint){
        return block.timestamp;
    }
}
