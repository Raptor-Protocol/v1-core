// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @author Raptor
 * @notice Contract used to Manage The insurance. Including Requests, Deletions and Payments
 *  */
contract InsuranceManager {
	/**
	 * @notice submit an Insurance request for review.
	 * @param contractAddress address of the contract to be insured
	 * @param admin address of the admin of the Insurance
	 * @param insuranceToken address of the Token that will be used for the Insurance
	 * @param insuranceAmount amount of the Insurance Token that will be used for the Insurance
	 * @param chainId id of the chain that the contract is on
	 * @custom:access anyone can perform this action
	 */
	function requestInsurance(
		address contractAddress,
		address admin,
		address insuranceToken,
		uint256 insuranceAmount,
		uint256 chainId
	) external {}

	/**
	 * @notice approve an Insurance request.
	 * @param contractAddress address of the approved contract
	 * @custom:access only wallets with the role "insurance auditor" can perform this action
	 */
	function approveInsurance(address contractAddress) external {}

	/**
	 * @notice Reject an Insurance Request.
	 * @param contractAddress address of the rejected contract
	 * @param reason why the contract was rejected
	 * @custom:access only wallets with the role "insurance auditor" can perform this action
	 */
	function rejectInsurance(address contractAddress, string memory reason) external {}

	/**
	 * @notice Request Cover for an Insurance.
	 * @param contractAddress address of the contract to be covered
	 * @param amount amount of the Insurance Token that will be used for the Cover
	 * @custom:access only the Insurance Admin can perform this action
	 */
	function requestCover(address contractAddress, uint256 amount) external {}

	/**
	 * @notice Approve Cover for an Insurance.
	 * @param contractAddress address of the contract to approve the Cover
	 * @custom:access only wallets with the role "Cover Auditor" can perform this action
	 */
	function approveCover(address contractAddress) external {}

	/**
	 * @notice Reject Cover for an Insurance.
	 * @param contractAddress address of the contract to reject
	 * @param reason why the contract was rejected
	 * @custom:access only wallets with the role "Cover Auditor" can perform this action
	 * */
	function rejectCover(address contractAddress, string memory reason) external {}

	/**
	 * @notice Unlock funds after a Cover request has been approved.
	 * @param contractAddress address of the exploited contract
	 * @custom:access only the Insurance Admin can perform this action
	 */
	function unlockFunds(address contractAddress) external {}

	/**
	 * @notice accept a cover rejection and revert to the original state.
	 * @param contractAddress address of the contract
	 * @custom:access only the Insurance Admin can perform this action
	 */
	function acceptCoverRejection(address contractAddress) external {}

	/**
	 * @notice delete an Insurance.
	 * @param contractAddress address of the contract to be deleted
	 * @custom:access only the Insurance Admin can perform this action if the insurance is not Expired.
	 * Once the Insurance is expired, anyone can delete it.
	 */
	function deleteInsurance(address contractAddress) external {}

	/**
	 * @notice Pays the monthly fee for an Insurance.
	 * @param contractAddress address of the contract to be paid
	 * @custom:info only insurances with the status Pending Payment can be paid
	 * @custom:access anyone can perform this action, letting 3rd parties pay their fees
	 */
	function payInsuranceFee(address contractAddress) external {}

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
	 * @notice Increase Insurance amount available for the given token.
	 * @param token address of the token to add liquidity
	 * @param amount amount to add
	 * @custom:access anyone can perform this action
	 */
	function addLiquidity(address token, uint256 amount) external {}

	/**
	 * @notice Decrease Insurance amount available for the given token.
	 * @param token address of the token to remove liquidity
	 * @param amount amount to remove
	 * @custom:access only the admin of this contract can perform this action
	 */
	function removeLiquidity(address token, uint256 amount) external {}

	/**
	 * @notice Get insurance info for a given contract.
	 * @param contractAddress address of the contract insured
	 */
	function getInsurance(address contractAddress) external view {}
}
