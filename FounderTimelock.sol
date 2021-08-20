// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FounderTimelock {
    address admin;
    uint256 public totalAllocated = 0;

    struct Founder {
        uint256 amountWithdrawn;
        uint256 totalAmountLocked;
        bool founderIsExecutive;
    }

    mapping(address => Founder) public founders;

    uint256 public immutable start;

    uint256 public immutable totalAmountTimelocked = 50000000000000;
    uint256 public totalAmountWithdrawn = 0;

    mapping(uint256 => uint256) private executivePercentageAvailableByDays;
    mapping(uint256 => uint256) private percentageAvailableByDays;

    constructor() {
        start = block.timestamp;
        admin = msg.sender;
        _setWithdrawalSchedule();
    }

    function _setWithdrawalSchedule() internal {
        uint256 currentPercentage = 0;
        uint256 startDay = 30;

        // Define mapping for executive withdrawal schedule
        while (currentPercentage <= 100) {
            executivePercentageAvailableByDays[
                startDay
            ] = currentPercentage += 2;
            startDay += 7;
        }

        currentPercentage = 0;
        startDay = 7;

        while (currentPercentage <= 100) {
            percentageAvailableByDays[startDay] = currentPercentage += 10;
            startDay += 7;
        }
    }

    function addFounder(
        address _founderAddress,
        uint256 _amountLocked,
        bool _founderIsExecutive
    ) external {
        require(msg.sender == admin, "Caller must be admin");

        require(
            founders[_founderAddress].totalAmountLocked == 0,
            "Address has already been added"
        );

        require(_founderAddress != address(0), "Cannot add address(0)");

        require(
            (totalAllocated + _amountLocked) <= totalAmountTimelocked,
            "Suggested allocation exceeds amount in timelock"
        );

        founders[_founderAddress].totalAmountLocked = _amountLocked;
        founders[_founderAddress].founderIsExecutive = _founderIsExecutive;
        founders[_founderAddress].amountWithdrawn = 0;

        totalAllocated += _amountLocked;
    }

    receive() external payable {}

    function withdraw(address token) external {
        require(
            founders[msg.sender].totalAmountLocked > 0,
            "only founder accessible"
        );

        require(token != address(0));

    bool ownerIsExecutive = founders[msg.sender].founderIsExecutive;

        require(
            ((block.timestamp >= start + 30 days) && ownerIsExecutive) ||
                ((block.timestamp >= start + 7 days) && !ownerIsExecutive),
            "should not be able to withdraw yet"
        );

        address owner = msg.sender;
        uint256 currentElapsedTime = block.timestamp - start;
        uint256 currentElapsedDays = (currentElapsedTime / 86400); // ********************** Check this line **********************

        uint256 executiveWithdrawalDay;
        uint256 standardWithdrawalDay;
        if (ownerIsExecutive) {
            executiveWithdrawalDay =
                (currentElapsedDays - (30)) -
                ((currentElapsedDays - (30)) % 7) +
                (30);
        } else {
            standardWithdrawalDay =
                (currentElapsedDays - (7)) -
                ((currentElapsedDays - (7)) % 7) +
                (7);
        }

        uint256 percentageAvailableToOwner = ownerIsExecutive
            ? executivePercentageAvailableByDays[executiveWithdrawalDay]
            : percentageAvailableByDays[standardWithdrawalDay];

        uint256 amountAvailableToOwner = ((percentageAvailableToOwner) *
            founders[msg.sender].totalAmountLocked) / 100;

        uint256 amountAvailableForWithdrawal = amountAvailableToOwner -
            founders[msg.sender].amountWithdrawn;

        require(
            amountAvailableForWithdrawal > 0,
            "Nothing available for withdrawal"
        );

        require(
            (amountAvailableForWithdrawal + totalAmountWithdrawn) <
                totalAmountTimelocked,
            "Claim more than amount designated for withdrawal"
        );

        IERC20(token).transfer(owner, amountAvailableForWithdrawal);
        totalAmountWithdrawn += amountAvailableForWithdrawal;
        founders[owner].amountWithdrawn += amountAvailableForWithdrawal;

    }

    // Functions for testing
    function checkFounderAllocation(address _founder)
        external
        view
        returns (uint256)
    {
        return founders[_founder].totalAmountLocked;
    }

    function checkAvailability(bool _isExecutive, uint256 _daysElapsed)
        external
        view
        returns (uint256)
    {
        if (_isExecutive) {
            uint256 executiveWithdrawalDay = (_daysElapsed - (30)) -
                ((_daysElapsed - (30)) % 7) +
                (30);

            return executivePercentageAvailableByDays[executiveWithdrawalDay];
        } else {
            uint256 standardWithdrawalDay = (_daysElapsed - (7)) -
                ((_daysElapsed - (7)) % 7) +
                (7);
            return percentageAvailableByDays[standardWithdrawalDay];
        }
    }

    function checkAmountAvailable(uint256 _percentAvailable)
        external
        view
        returns (uint256)
    {
        return
            (_percentAvailable * founders[msg.sender].totalAmountLocked) / 100;
    }

    function checkAmountWithdrawn() external view returns (uint256) {
        return founders[msg.sender].amountWithdrawn;
    }
}
