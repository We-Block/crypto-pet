// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PetAuction is ReentrancyGuard, Ownable {
    struct Auction {
        address seller;
        uint256 petId;
        uint256 startPrice;
        uint256 endBlock;
        address highestBidder;
        uint256 highestBid;
    }

    IERC721 public petContract;
    IERC20 public tokenContract;
    uint256 public auctionDuration;

    mapping(uint256 => Auction) public auctions;

    event AuctionCreated(uint256 petId, uint256 startPrice, uint256 endBlock);
    event AuctionCancelled(uint256 petId);
    event AuctionBid(uint256 petId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 petId, address winner, uint256 winningAmount);

    constructor(address _petContract, address _tokenContract, uint256 _auctionDuration) {
        petContract = IERC721(_petContract);
        tokenContract = IERC20(_tokenContract);
        auctionDuration = _auctionDuration;
    }

    function createAuction(uint256 _petId, uint256 _startPrice) external {
        require(petContract.ownerOf(_petId) == msg.sender, "Caller is not the pet owner");
        require(petContract.getApproved(_petId) == address(this), "Contract is not approved to transfer the pet");

        auctions[_petId] = Auction({
            seller: msg.sender,
            petId: _petId,
            startPrice: _startPrice,
            endBlock: block.number + auctionDuration,
            highestBidder: address(0),
            highestBid: 0
        });

        emit AuctionCreated(_petId, _startPrice, block.number + auctionDuration);
    }

    function cancelAuction(uint256 _petId) external {
        Auction storage auction = auctions[_petId];
        require(auction.seller == msg.sender, "Caller is not the pet seller");

        delete auctions[_petId];
        emit AuctionCancelled(_petId);
    }

    function bid(uint256 _petId, uint256 _bidAmount) external nonReentrant {
        Auction storage auction = auctions[_petId];
        require(block.number <= auction.endBlock, "Auction has already ended");
        require(_bidAmount >= auction.startPrice, "Bid amount is lower than the starting price");
        require(_bidAmount > auction.highestBid, "Bid amount must be higher than the current highest bid");

        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            tokenContract.transfer(auction.highestBidder, auction.highestBid);
        }

        // Transfer tokens from bidder to the auction contract
        tokenContract.transferFrom(msg.sender, address(this), _bidAmount);

        // Update auction with new highest bidder and highest bid
        auction.highestBidder = msg.sender;
        auction.highestBid = _bidAmount;

        emit AuctionBid(_petId, msg.sender, _bidAmount);
    }

    function endAuction(uint256 _petId) external nonReentrant {
        Auction storage auction = auctions[_petId];
        require(block.number
