// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {BaseInsuranceManagerTest, InsuranceManager} from "test/BaseInsuranceManagerTest.t.sol";

contract InsuranceManagerFuzzTest is BaseInsuranceManagerTest {
	function testFuzz_requestInsurance_savesTheInsuranceRequest(
		address[20] calldata insuranceScope,
		uint256[20] calldata insuranceChainId,
		uint256 insuranceAmount
	) external {
		(address[] memory _insuranceScope, uint256[] memory _insuranceChainIds) = _requestInsurance(
			"protocolName",
			"protocolWebsite",
			"contactInformation",
			insuranceAmount,
			insuranceScope,
			insuranceChainId
		);

		InsuranceManager.Insurance memory savedInsuranceRequest = cut.insuranceOf(address(this));

		assertEq(savedInsuranceRequest.token.insuranceAmount, insuranceAmount, "Insurance amount does not match with the one requested");
		assertEq(savedInsuranceRequest.token.tokenAddress, address(insuranceToken), "Token address does not match with the one requested");
		assertEq(savedInsuranceRequest.scope, _insuranceScope, "Scope does not match with the one requested");
		assertEq(savedInsuranceRequest.chainIds, _insuranceChainIds, "Chain ids does not match with the one requested");
	}

	function testFuzz_requestInsurance_revertsIfAlreadyRequested(
		address[20] calldata insuranceScope1,
		uint256[20] calldata insuranceChainId1,
		uint256 insuranceAmount1,
		address[20] calldata insuranceScope2,
		uint256[20] calldata insuranceChainId2,
		uint256 insuranceAmount2
	) external {
		vm.assume(insuranceAmount1 > 0 && insuranceAmount2 > 0);

		_requestInsurance("protocolName1", "protocolWebsite1", "contactInformation1", insuranceAmount1, insuranceScope1, insuranceChainId1);

		vm.expectRevert(InsuranceManager.InsuranceManager__InsuranceAlreadyRequested.selector);
		_requestInsurance("protocolName2", "protocolWebsite2", "contactInformation2", insuranceAmount2, insuranceScope2, insuranceChainId2);
	}

	function testFuzz_requestInsurance_revertsIfScopeAndChainIdshasDifferentSizes(
		address[5] calldata insuranceScope,
		uint256[10] calldata insuranceChainId,
		uint256 insuranceAmount
	) external {
		vm.assume(insuranceAmount > 0);

		address[] memory scope = new address[](insuranceScope.length);
		uint256[] memory chainIds = new uint256[](insuranceChainId.length);

		for (uint256 i = 0; i < insuranceScope.length; i++) {
			scope[i] = insuranceScope[i];
		}

		for (uint256 i = 0; i < insuranceChainId.length; i++) {
			chainIds[i] = insuranceChainId[i];
		}

		vm.expectRevert(
			abi.encodeWithSelector(InsuranceManager.InsuranceManager__ScopeAndChainIdSizeMismatch.selector, scope.length, chainIds.length)
		);
		cut.requestInsurance(
			"protocolName",
			"protocolWebsite",
			"contactInformation",
			InsuranceManager.InsuranceToken(insuranceAmount, address(insuranceToken)),
			scope,
			chainIds
		);
	}

	function testFuzz_requestInsurance_revertsIfInsuranceAmountIsGreaterThanAvailableLiquidity(
		uint256 insuranceAmount,
		uint256 availableLiquidity
	) external {
		vm.assume(availableLiquidity < insuranceAmount);

		ERC20Mock _insuranceToken = new ERC20Mock();

		_addLiquidity(_insuranceToken, availableLiquidity);

		vm.expectRevert(
			abi.encodeWithSelector(
				InsuranceManager.InsuranceManager__InsuranceAmountGreaterThanAvailable.selector,
				insuranceAmount,
				cut.getAvailableLiquidity(address(_insuranceToken)),
				address(_insuranceToken)
			)
		);
		cut.requestInsurance(
			"protocolName",
			"protocolWebsite",
			"contactInformation",
			InsuranceManager.InsuranceToken(insuranceAmount, address(_insuranceToken)),
			new address[](32),
			new uint256[](32)
		);
	}

	function testFuzz_requestInsurance_decreasesTheAvailableLiquidity(
		uint256 insuranceAmount,
		address[20] calldata insuranceScope,
		uint256[20] calldata insuranceChainId
	) external {
		uint256 availableLiquidityBeforeRequest = cut.getAvailableLiquidity(address(insuranceToken));
		_requestInsurance("protocolName", "protocolWebsite", "contactInformation", insuranceAmount, insuranceScope, insuranceChainId);
		uint256 availableLiquidityAfterRequest = cut.getAvailableLiquidity(address(insuranceToken));

		assertEq(availableLiquidityBeforeRequest - availableLiquidityAfterRequest, insuranceAmount);
	}

	function _requestInsurance(
		string memory protocolName,
		string memory protocolWebsite,
		string memory contactInformation,
		uint256 insuranceAmount,
		address[20] calldata insuranceScope,
		uint256[20] calldata insuranceChainId
	) private returns (address[] memory scope, uint256[] memory chainIds) {
		vm.assume(insuranceAmount > 0);

		address[] memory _scope = new address[](insuranceScope.length);
		uint256[] memory _chainIds = new uint256[](insuranceChainId.length);

		for (uint256 i = 0; i < insuranceScope.length; i++) {
			_scope[i] = insuranceScope[i];
			_chainIds[i] = insuranceChainId[i];
		}

		InsuranceManager.InsuranceToken memory token = InsuranceManager.InsuranceToken(insuranceAmount, address(insuranceToken));
		cut.requestInsurance(protocolName, protocolWebsite, contactInformation, token, _scope, _chainIds);

		return (_scope, _chainIds);
	}
}
