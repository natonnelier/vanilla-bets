pragma solidity ^0.7.0;

/**
 * This contract includes methods to manage basic authorization control
 * and user permissions.
 */

contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    //constructor sets the original `owner` of the contract to the sender
    constructor() public {
        owner = msg.sender;
    }

    //throw error if called by any account other than the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //set a new owner for the current contract.
    //params newOwner The address to transfer ownership to
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}