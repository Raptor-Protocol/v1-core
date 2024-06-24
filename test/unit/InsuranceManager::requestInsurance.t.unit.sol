// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {InsuranceManager} from "src/contracts/InsuranceManager.sol";
import {BaseInsuranceManagerTest} from "test/BaseInsuranceManagerTest.t.sol";

contract InsuranceManagerRequestInsuranceUnitTest is BaseInsuranceManagerTest {
	function testUnit_requestInsurance_EmitsEventCorrectly() external {
		address user = makeAddr("sender");
		string memory protocolName = "ProtocolName";
		string memory protocolWebsite = "ProtocolWebsite";
		string memory contactInformation = "ContactInformation";
		address[] memory scope = new address[](2);
		uint256[] memory chainIds = new uint256[](2);
		uint256 insuranceAmount = 100;
		InsuranceManager.InsuranceToken memory token = InsuranceManager.InsuranceToken(insuranceAmount, address(insuranceToken));
		scope[0] = address(1);
		scope[1] = address(2);
		chainIds[0] = 1;
		chainIds[1] = 2;

		vm.startPrank(user);
		vm.expectEmit(address(cut));
		emit InsuranceManager.InsuranceManager__InsuranceRequested({
			owner: user,
			protocolName: protocolName,
			protocolWebsite: protocolWebsite,
			contactInformation: contactInformation,
			insuranceScope: scope,
			chainIds: chainIds,
			insuranceToken: token
		});

		cut.requestInsurance(protocolName, protocolWebsite, contactInformation, token, scope, chainIds);
		vm.stopPrank();
	}

	function testUnit__requestInsurance_revertsIfScopeIsEmpty() external {
		vm.expectRevert(InsuranceManager.InsuranceManager__EmptyInsuranceScope.selector);
		cut.requestInsurance(
			"ProtocolName",
			"ProtocolWebsite",
			"ContactInformation",
			InsuranceManager.InsuranceToken(100, address(insuranceToken)),
			new address[](0),
			new uint256[](19)
		);
	}

	function testUnit__requestInsurance_revertsIfContactInformationIsEmpty() external {
		vm.expectRevert(InsuranceManager.InsuranceManager__EmptyContactInformation.selector);
		cut.requestInsurance(
			"ProtocolName",
			"ProtocolWebsite",
			"",
			InsuranceManager.InsuranceToken(100, address(insuranceToken)),
			new address[](19),
			new uint256[](19)
		);
	}

	function testUnit__requestInsurance_revertsIfInsuranceAmountIsZero() external {
		vm.expectRevert(abi.encodeWithSelector(InsuranceManager.InsuranceManager__ZeroInsuranceAmount.selector, insuranceToken));
		cut.requestInsurance(
			"ProtocolName",
			"ProtocolWebsite",
			"ContactInformation",
			InsuranceManager.InsuranceToken(0, address(insuranceToken)),
			new address[](19),
			new uint256[](19)
		);
	}

	function _requestInsurance() private {
		string memory protocolName = "ProtocolName";
		string memory protocolWebsite = "ProtocolWebsite";
		string memory contactInformation = "ContactInformation";
		address[] memory scope = new address[](2);
		uint256[] memory chainIds = new uint256[](2);
		uint256 insuranceAmount = 100;
		InsuranceManager.InsuranceToken memory token = InsuranceManager.InsuranceToken(insuranceAmount, address(insuranceToken));
		scope[0] = address(1);
		scope[1] = address(2);
		chainIds[0] = 1;
		chainIds[1] = 2;

		cut.requestInsurance(protocolName, protocolWebsite, contactInformation, token, scope, chainIds);
	}
}
