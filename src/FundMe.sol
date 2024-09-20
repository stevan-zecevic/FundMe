// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {PriceFeed} from "contracts/PriceFeed.sol";
import {Ownable} from "contracts/Ownable.sol";
import {console2} from "forge-std/console2.sol";
import {Ownable} from "contracts/Ownable.sol";

error FundMe__FundRequirementNotMet(address, uint256, uint256, uint256);
error FundMe__RetreiveError(uint256);
error FundMe__GoalAmountNotMet(uint256, uint256);
error FundMe__Fallback(bytes message);

/// @title FundMe
/// @notice This abstract contract is used to create fundations and collect funds from funders
abstract contract FundMe is PriceFeed, Ownable {
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

    bytes32 private immutable i_name;
    bytes32 private immutable i_description;
    uint256 private immutable i_minimumFund;

    /// @notice Creates a new fundation based on the given parameters
    /// @param _name The name of the fundation
    /// @param _description The description of the fundation
    /// @param _minimumFund The minimum fund amount, in USD
    /// @param _priceFeedAddress The address of the price feed contract
    constructor(
        bytes32 _name,
        bytes32 _description,
        uint256 _minimumFund,
        address _priceFeedAddress
    ) PriceFeed(_priceFeedAddress) {
        i_minimumFund = _minimumFund;
        i_name = _name;
        i_description = _description;
    }

    /// @notice Fallback function to handle incoming funds, should be overridden by child contracts
    receive() external payable virtual {}

    /// @notice Fallback function to handle incoming funds
    fallback() external payable {
        revert FundMe__Fallback(msg.data);
    }

    /// @notice Performs upkeep on the fundation and collects the funds, should be overridden by child contracts
    function performUpkeep(
        bytes calldata /* performData */
    ) public payable virtual;

    /// @notice Funds the fundation
    /// @dev This function is called when a funder wants to send ETH to the fundation
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

        console.log(
            "Funded value in wei: %s",
            msg.value,
            address(this).balance
        );

        emit FundMe__Funded(msg.sender, fundedValueInUSD);

        if (s_fundersMapping[msg.sender] == 0) {
            s_funders.push(msg.sender);
        }

        s_fundersMapping[msg.sender] += msg.value;
    }

    /// @notice Gets the name of the fundation
    function getName() public view returns (string memory) {
        string memory name = string(abi.encodePacked(i_name));

        return name;
    }

    /// @notice Gets the description of the fundation
    function getDescription() public view returns (string memory) {
        string memory description = string(abi.encodePacked(i_description));

        return description;
    }

    /// @notice Gets the minimum fund amount, in USD
    function getMinimumFund() public view returns (uint256) {
        return i_minimumFund;
    }

    /// @notice Gets the funder at the given index
    function getFunder(uint256 _index) public view returns (address) {
        return s_funders[_index];
    }

    /// @notice Gets the number of funders
    function getNumberOfFunders() public view returns (uint256) {
        return s_funders.length;
    }

    /// @notice Gets the amount of funds the given funder has sent
    function getFundersAmount(
        address _funderAddress
    ) public view returns (uint256) {
        return s_fundersMapping[_funderAddress];
    }

    /// @notice Gets the current status of the fundation
    function getStatus() public view returns (Status) {
        return s_status;
    }

    /// @notice Sets the status of the fundation
    /// @dev This function is only callable by the owner
    function setStatus(Status _status) public onlyOwner {
        s_status = _status;
    }
}
