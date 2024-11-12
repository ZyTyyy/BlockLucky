// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "BlockLucky/node_modules/@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";

contract BlockLucky is VRFConsumerBase {
    address public owner;
    uint public ticketPrice;
    address[] public players;
    uint public endTimestamp;
    bytes32 internal keyHash;
    uint256 internal fee;
    address public winner;

    event TicketPurchased(address indexed buyer);
    event WinnerDeclared(address indexed winner, uint prize);

    constructor(
        uint _ticketPrice,
        uint _duration,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint _fee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        endTimestamp = block.timestamp + _duration;
        keyHash = _keyHash;
        fee = _fee;
    }

    function buyTicket() public payable {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(block.timestamp < endTimestamp, "Lotto has ended");

        players.push(msg.sender);
        emit TicketPurchased(msg.sender);
    }

    function drawWinner() public {
        require(block.timestamp >= endTimestamp, "Lotto is still ongoing");
        require(players.length > 0, "No players in the lotto");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");

        requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint randomIndex = randomness % players.length;
        winner = players[randomIndex];
        uint prize = address(this).balance;

        payable(winner).transfer(prize);
        emit WinnerDeclared(winner, prize);

        delete players;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
}
