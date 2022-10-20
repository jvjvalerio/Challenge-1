// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;

    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display)
    event Stake(address sender, uint256 value);

    function stake() public payable deadlinePassed(false) notCompleted {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call
    // `exampleExternalContract.complete{value: address(this).balance}()`

    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw;
    bool public executed;

    modifier deadlinePassed(bool requireDeadlinePassed) {
        uint256 timeRemaining = timeLeft();
        if (requireDeadlinePassed) {
            require(timeRemaining <= 0, "Deadline has not been passed yet");
        } else {
            require(
                timeRemaining > 0,
                "Deadline has already passed you're too late!"
            );
        }
        _;
    }

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Staking period has completed!");
        _;
    }

    function execute() public notCompleted {
        uint256 contractBalance = address(this).balance;
        if (contractBalance >= threshold) {
            exampleExternalContract.complete{value: contractBalance}();
        } else {
            openForWithdraw = true;
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public deadlinePassed(true) notCompleted {
        require(openForWithdraw, "Can't withdraw yet! Wait for time to end");
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "The users balance is 0");
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: userBalance}("");
        require(sent, "Unfortunately we could not send to address");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
