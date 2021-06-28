pragma solidity ^0.7.0;

import "./Ownable.sol";

/**
 * This contract includes methods for contract's owner to enable and disable features
 */

contract Disableable is Ownable {
    bool disabled = false; 

    // throw error if function is disabled
    modifier notDisabled() {
        require(!disabled);
        _;
    }

    function Disable() external onlyOwner {
        disabled = true; 
    }

    function Enable() external onlyOwner {
        disabled = false; 
    }
}
