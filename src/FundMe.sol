// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {PriceFeed} from "contracts/PriceFeed.sol";
import {Ownable} from "contracts/Ownable.sol";
import {console2} from "forge-std/console2.sol";

error FundMe__FundRequirementNotMet(address, uint256, uint256, uint256);
error FundMe__RetreiveError(uint256);
error FundMe__GoalAmountNotMet(uint256, uint256);
error FundMe__Fallback(bytes message);

abstract contract FundMe is PriceFeed {
    event FundMe__Funded(
        address indexed funderAddress,
        uint256 indexed fundedAmount
    );
    event FundMe__DonationsCollected(uint256 indexed amount);

    enum Status {
        Open,
        Closed,
        Finished
    }

    address[] private s_funders;
    mapping(address => uint256) private s_fundersMapping;
    Status private s_status = Status.Open;

    uint256 private immutable i_minimumFund;

    constructor(
        uint256 _minimumFund,
        address _priceFeedAddress
    ) PriceFeed(_priceFeedAddress) {
        i_minimumFund = _minimumFund;
    }

    receive() external payable virtual {}

    fallback() external payable {
        revert FundMe__Fallback(msg.data);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) public payable virtual;

    function fund() public payable {
        uint256 fundedValueInUSD = convertToUSD(msg.value);
        bool isMinimumFundNotMet = i_minimumFund != 0 &&
            fundedValueInUSD < i_minimumFund * 10 ** 18;

        if (msg.value == 0 || isMinimumFundNotMet || s_status != Status.Open) {
            revert FundMe__FundRequirementNotMet(
                msg.sender,
                uint256(s_status),
                fundedValueInUSD,
                msg.value
            );
        }

        emit FundMe__Funded(msg.sender, fundedValueInUSD);

        if (s_fundersMapping[msg.sender] == 0) {
            s_funders.push(msg.sender);
        }

        s_fundersMapping[msg.sender] += msg.value;
    }

    function getMinimumFund() public view returns (uint256) {
        return i_minimumFund;
    }

    function getFunder(uint256 _index) public view returns (address) {
        return s_funders[_index];
    }

    function getNumberOfFunders() public view returns (uint256) {
        return s_funders.length;
    }

    function getFundersAmount(
        address _funderAddress
    ) public view returns (uint256) {
        return s_fundersMapping[_funderAddress];
    }

    function getStatus() public view returns (Status) {
        return s_status;
    }

    function setStatus(Status _status) public {
        s_status = _status;
    }
}
