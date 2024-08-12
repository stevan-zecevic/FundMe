// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

error Ownable__NotOwner(address);

contract Ownable {
    address immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Ownable__NotOwner(msg.sender);
        }

        _;
    }
}
