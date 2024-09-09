// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

error Ownable__NotOwner(address);

contract Ownable {
    address internal s_owner;

    constructor() {
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert Ownable__NotOwner(msg.sender);
        }
        _;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }

    function setOwner(address _newOwner) public onlyOwner {
        s_owner = _newOwner;
    }
}
