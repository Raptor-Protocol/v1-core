// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {InsuranceManager} from "src/contracts/InsuranceManager.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

abstract contract BaseInsuranceManagerTest is Test {
	InsuranceManager internal immutable cut = new InsuranceManager(address(this));
	ERC20Mock internal immutable insuranceToken = new ERC20Mock();

	function setUp() public {
		_addLiquidity(insuranceToken, UINT256_MAX);
		cut.grantRole(cut.INSURANCE_AUDITOR_ROLE(), address(this));
	}

	function _addLiquidity(uint256 amount) internal {
		_addLiquidity(insuranceToken, amount);
	}

	function _addLiquidity(ERC20Mock token, uint256 amount) internal {
		token.mint(address(this), amount);

		cut.grantRole(cut.LIQUIDITY_PROVIDER_ROLE(), address(this));
		token.approve(address(cut), amount);
		cut.addLiquidity(token, amount);
	}
}
