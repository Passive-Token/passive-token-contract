// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PasvToken.sol";

contract PasvDeployer {
    uint256 public TOTAL_SUPPLY = 1000000000000000 * 10**6;
    uint256 public marketingAllocation = TOTAL_SUPPLY / 20;
    uint256 public founderAllocation = TOTAL_SUPPLY / 20;
    uint256 public liquidityAllocation = TOTAL_SUPPLY / 2;
    uint256 public presaleAllocation = 75000000000000 * 10**6;
    uint256 public burnAmount = ((TOTAL_SUPPLY * 3) / 10);
    uint256 public pubcoAllocation = TOTAL_SUPPLY / 40;

    event Transfer(address indexed _from, address indexed _id, uint256 _value);

    address public _token;
    PasvToken public PasvTokenRef;

    constructor(address _MarketingWallet, address _FounderTimelockContract, address _PresaleContract, address _PubcoWallet) {
        PasvToken PasvTokenInstance = new PasvToken();
        PasvTokenRef = PasvTokenInstance;
        _token = PasvTokenInstance.getPasvAddress();

        PasvTokenInstance.setExcludedFromFee(msg.sender, true);
        PasvTokenInstance.setExcludedFromFee(_MarketingWallet, true);
        PasvTokenInstance.setExcludedFromFee(_FounderTimelockContract, true);
        PasvTokenInstance.setExcludedFromFee(_PresaleContract, true);
        PasvTokenInstance.setExcludedFromFee(_PubcoWallet, true);

        // Burn tokens - 30%
        PasvTokenInstance.burn(burnAmount);

        // Transfer to marketing wallet - 5%
        PasvTokenInstance.transfer(_MarketingWallet, marketingAllocation);

        // Transfer to founder timelock contract - 5%
        PasvTokenInstance.transfer(_FounderTimelockContract, founderAllocation);

        // Transfer to presale contract - 7.5%
        PasvTokenInstance.transfer(
            _PresaleContract,
            presaleAllocation
        );
        // Transfer to liquidity contract - 50%
        PasvTokenInstance.transfer(
            _PresaleContract,
            liquidityAllocation
        );
        // Transfer to Pub Co wallet - 2.5%
        PasvTokenInstance.transfer(
            _PubcoWallet,
            pubcoAllocation
        );
    }

    /* Testing Functions */
    function getPasvAddress() external view returns (address) {
        return _token;
    }

    function getPasvBalance(address _holder) external view returns (uint256) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(_holder);
    }

    function transferPasv(address _recipient, uint256 _amount) external {
        PasvTokenRef.transferFrom(msg.sender, _recipient, _amount);
        emit Transfer(msg.sender, _recipient, _amount);
    }

    function getPasvRef() external view returns (PasvToken) {
        return PasvTokenRef;
    }
}
