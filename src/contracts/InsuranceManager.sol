// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

contract InsuranceManager is AccessControlDefaultAdminRules {
	using SafeERC20 for IERC20;

	/**
	 * @notice struct that defines the data of an insurance
	 *
	 * @param scope the scope of the insurance (the smart contracts addresses that will be covered)
	 *
	 * @param scss the scss(Smart Contract Security Score) for each contract in the scope.
	 * note that the array must be in the same order as the scope to assign the right SCSS for each contract
	 *
	 * @param chainId the chainId for each contract in the scope.
	 * note that the array must be in the same order as the scope to assign the right chainId for each contract
	 *
	 * @param token InsuranceToken struct containing information about the insurance token such as the token address and the amount
	 *
	 * @param payment Payment struct containing information about the payment such as the price and the deadline
	 *  */
	struct Insurance {
		address[] scope;
		uint8[] scss;
		uint256[] chainIds;
		InsuranceToken token;
		InsurancePayment payment;
	}

	/**
	 * @notice struct that defines the information of an insurance token
	 * @param insuranceAmount the amount being covered by the insurance
	 * @param tokenAddress the address of the token used as coverage
	 */
	struct InsuranceToken {
		uint256 insuranceAmount;
		address tokenAddress;
	}

	/**
	 * @notice struct that defines the information of an insurance payment
	 * @param insurancePrice the yearly price of the insurance
	 * @param paymentDeadline the deadline of the monthly payment before the user get uncovered
	 * */
	struct InsurancePayment {
		uint256 insurancePrice;
		uint256 paymentDeadline;
	}

	bytes32 public constant INSURANCE_AUDITOR_ROLE = "INSURANCE_AUDITOR";
	bytes32 public constant LIQUIDITY_PROVIDER_ROLE = "LIQUIDITY_PROVIDER";

	mapping(address owner => Insurance insurance) private s_insurances;
	mapping(address token => uint256 availableAmount) private s_availableLiquidity;

	/**
	 * @notice emitted once an insurance is sucessfully requested
	 * @param owner the sender of the request
	 * @param protocolName name of the protocol being insured
	 * @param protocolWebsite website of the protocol being insured (empty don't have one)
	 * @param contactInformation contact information for the protocol, can be either email address or any other supported contact
	 * @param insuranceToken the insurance token that will be used as coverage
	 * */
	event InsuranceManager__InsuranceRequested(
		address indexed owner,
		string protocolName,
		string protocolWebsite,
		string contactInformation,
		address[] insuranceScope,
		uint256[] chainIds,
		InsuranceToken indexed insuranceToken
	);

	/**
	 * @notice emitted once an insurance is approved
	 * @param owner the owner of the insurance
	 */
	event InsuranceManager__InsuranceApproved(address indexed owner);

	/**
	 * @notice emitted once liquidity has been added for insurances
	 * @param token the token address that was added
	 * @param amount the amount of liquidity added
	 */
	event InsuranceManager__LiquidityAdded(address token, uint256 amount);

	/**
	 * @notice thrown when an insurance has already been requested by the sender
	 */
	error InsuranceManager__InsuranceAlreadyRequested();

	/**
	 * @notice thrown when the requested insurance amount is greater than the available funds for the insurance token
	 * @param insuranceAmount the requested amount for the insurance
	 * @param availableLiquidity the available funds for the insurance
	 */
	error InsuranceManager__InsuranceAmountGreaterThanAvailable(uint256 insuranceAmount, uint256 availableLiquidity, address insuranceToken);

	/**
	 * @notice thrown if the contaact information passed is Empty
	 */
	error InsuranceManager__EmptyContactInformation();

	/**
	 * @notice thrown if the insurance scope array passed is empty
	 */
	error InsuranceManager__EmptyInsuranceScope();

	/**
	 * @notice thrown if the requested insurance amount is zero for the given token
	 */
	error InsuranceManager__ZeroInsuranceAmount(address insuranceToken);

	/**
	 * @notice thrown when trying to request an insurance passing a scope array with a size different from the chainId array
	 */
	error InsuranceManager__ScopeAndChainIdSizeMismatch(uint256 scopeSize, uint256 chainIdSize);

	/**
	 * @notice thrown when trying to approve an insurance passing a SCSSs array with a size different from the scope array
	 * @param sccssSize the size of the passed SCSSs array
	 * @param scopeSize the size of the scope array
	 */
	error InsuranceManager__ScopeAndScssSizeMismatch(uint256 sccssSize, uint256 scopeSize);

	/**
	 * @notice thrown when trying to interact with an insurance that has not been requested (e.g approve or reject)
	 * @param owner the owner of the insurance
	 */
	error InsuranceManager__InsuranceNotRequested(address owner);

	/**
	 * @notice thrown when trying to approve an insurance that has already been approved
	 * @param owner the owner of the insurance
	 */
	error InsuranceManager__InsuranceAlreadyApproved(address owner);

	constructor(address admin) AccessControlDefaultAdminRules(3 days, admin) {}

	/**
	 * @notice submit an insurance request for review
	 * @param protocolName name of the protocol being insured
	 * @param protocolWebsite website of the protocol being insured (empty don't have one)
	 * @param contactInformation contact information for the protocol, can be either email address or any other supported contact
	 * @param insuranceToken the insurance token that will be used as coverage
	 * @param scope the smart contracts that will be covered by the insurance
	 * @param chainIds the chain id of the smart contracts in the scope.
	 * @custom:warning Note that the scope and chainIds arrays must have the same size and be in the same order to add
	 * the information correctly
	 * */
	function requestInsurance(
		string calldata protocolName,
		string calldata protocolWebsite,
		string calldata contactInformation,
		InsuranceToken calldata insuranceToken,
		address[] calldata scope,
		uint256[] calldata chainIds
	) external {
		uint256 availableLiquidity = s_availableLiquidity[insuranceToken.tokenAddress];

		if (s_insurances[msg.sender].token.tokenAddress != address(0)) revert InsuranceManager__InsuranceAlreadyRequested();
		if (scope.length == 0) revert InsuranceManager__EmptyInsuranceScope();
		if (bytes32(bytes(contactInformation)) == 0x0) revert InsuranceManager__EmptyContactInformation();
		if (insuranceToken.insuranceAmount == 0) revert InsuranceManager__ZeroInsuranceAmount(insuranceToken.tokenAddress);
		if (scope.length != chainIds.length) {
			revert InsuranceManager__ScopeAndChainIdSizeMismatch({scopeSize: scope.length, chainIdSize: chainIds.length});
		}
		if (insuranceToken.insuranceAmount > availableLiquidity) {
			revert InsuranceManager__InsuranceAmountGreaterThanAvailable({
				insuranceAmount: insuranceToken.insuranceAmount,
				availableLiquidity: availableLiquidity,
				insuranceToken: insuranceToken.tokenAddress
			});
		}

		s_availableLiquidity[insuranceToken.tokenAddress] = availableLiquidity - insuranceToken.insuranceAmount;
		s_insurances[msg.sender] = Insurance({
			token: insuranceToken,
			scope: scope,
			chainIds: chainIds,
			payment: InsurancePayment(0, 0),
			scss: new uint8[](0)
		});

		emit InsuranceManager__InsuranceRequested({
			owner: msg.sender,
			protocolName: protocolName,
			protocolWebsite: protocolWebsite,
			contactInformation: contactInformation,
			insuranceScope: scope,
			chainIds: chainIds,
			insuranceToken: insuranceToken
		});
	}

	/**
	 * @notice Changes the Insurance Admin of an Insurance.
	 * @param contractAddress address of the Insurance to change the admin
	 * @param newAdmin new admin of the Insurance
	 * @custom:access only the Current Insurance Admin can perform this action
	 */
	function changeInsuranceAdmin(address contractAddress, address newAdmin) external {}

	/**
	 * @notice Change the insurance amount of an Insurance. It will also update the Insurance Price.
	 * @param contractAddress address of the Insurance to change the amount
	 * @param newAmount new amount of the Insurance
	 * @custom:info It will only work if the new amount is lower or equal to the available amount
	 * @custom:access only the Insurance Admin can perform this action
	 */
	function changeInsuranceAmount(address contractAddress, uint256 newAmount) external {}

	/**
	 * @notice add liquidity for the given token. This liquidity will be immediately available for use as insurance amount
	 * @param token the token address to add liquidity
	 * @param amount the amount of liquidity to add (with decimals)
	 */
	function addLiquidity(IERC20 token, uint256 amount) external onlyRole(LIQUIDITY_PROVIDER_ROLE) {
		s_availableLiquidity[address(token)] += amount;
		token.safeTransferFrom(msg.sender, address(this), amount);

		emit InsuranceManager__LiquidityAdded(address(token), amount);
	}

	/**
	 * @notice get the insurance info of an user
	 * @param owner the current owner of the insurance
	 * @return insurance tuple containing all relevant insurance info
	 */
	function insuranceOf(address owner) external view returns (Insurance memory insurance) {
		return s_insurances[owner];
	}

	/**
	 * @notice get the available liquidity to be used as insurance amount by someone for the given token
	 * @param token the token to get the available liquidity
	 * @return availableLiquidity the available liquidity for the given token (with decimals)
	 */
	function getAvailableLiquidity(address token) external view returns (uint256 availableLiquidity) {
		return s_availableLiquidity[token];
	}
}
