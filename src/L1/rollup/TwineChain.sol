// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SP1Verifier} from "@sp1-contracts/v4.0.0-rc.3/SP1VerifierGroth16.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineChain} from "./ITwineChain.sol";
import {IL1MessageHandler} from "./IL1MessageHandler.sol";
import {ITwineDVN} from "../../lzdvn/interfaces/ITwineDVN.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {IL1ETHGateway} from "../gateways/interfaces/IL1ETHGateway.sol";
import {IL1ERC20Gateway} from "../gateways/interfaces/IL1ERC20Gateway.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";
import {TwineChainDecoder} from "../../libraries/decoders/TwineChainDecoder.sol";

/// @title TwineChain
/// @notice This contract maintains the data for Meta Rollup.
contract TwineChain is ContextUpgradeable, ITwineChain {
    using TypeConversionLib for string;

    /*************
     * Variables *
     *************/

    ///@notice The chai ID for the L1 where this contract is deployed
    uint64 public chainId;

    ///@notice total L1 messages Handled On Twine
    uint256 public totalMsgHandledOnTwine;

    /// @notice The latest committed batch number
    uint256 public override lastCommittedBatchNumber;

    /// @notice The latest finalized batch number
    uint256 public override lastFinalizedBatchNumber;

    /// @notice The verification key for finalize proof
    bytes32 public finalizeVKey;

    /// @notice The verification key for forced withdrawal proof
    bytes32 public forcedWithdrawalVKey;

    /// @notice The verification key for l2 initiated withdrawal proof
    bytes32 public l2WithdrawalVkey;

    /// @notice The verification key for refund proof.
    bytes32 public refundVKey;

    //@notice The last finalize batch hash
    bytes32 public lastFinalizedBatchHash;

    //gateway address of eth
    address public ethGateway;

    //gateway address of erc20 gateway
    address public ERC20Gateway;

    /// @notice The address of L1MessageHandler contract.
    address public messageHandler;

    /// @notice The address of RollupVerifier.
    address public verifier;

    /// @notice Address of the rolemanager contract
    address public roleManager;

    /// @notice status of genesis block
    bool public isGenesisBlockCommitted;

    /// @notice Skip zk Verification
    bool public skipVerification;

    /*************
     * Mappings  *
     *************/
    /// @notice The mapping of batchNumber => batchHash
    mapping(uint64 => bytes32) public committedBatch;
    /// @notice The mapping of batchNumber => batchHash
    mapping(uint64 => bytes32) public finalizedBatch;
    /// @notice Mapping of executed withdraw hash to a boolean value
    mapping(bytes32 => bool) public isL2WithdrawExecuted;
    /// @notice Mapping of executed withdraw hash to a boolean value
    mapping(bytes32 => bool) public isForcedWithdrawExecuted;
    /// @notice Mapping of executed refund hash to a boolean value
    mapping(bytes32 => bool) public isRefundExecuted;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of TwineChain.
    /// @param _messageHandler The address of `L1MessageHandler` contract.
    /// @param _verifier The address of zkevm verifier contract.
    function initialize(
        address _messageHandler,
        address _verifier,
        address _roleManager
    ) external initializer {
        messageHandler = _messageHandler;
        verifier = _verifier;
        roleManager = _roleManager;
        skipVerification = true;
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc ITwineChain
    function isBatchFinalized(
        uint256 batchNumber
    ) public view override returns (bool) {
        return batchNumber <= lastFinalizedBatchNumber;
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc ITwineChain
    function setChainId(
        uint64 _chainId
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        chainId = _chainId;
    }

    /// @inheritdoc ITwineChain
    function setRoleManagerAddress(
        address _roleManagerAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_roleManagerAddress == address(0)) {
            revert ErrorZeroAddress();
        }
        roleManager = _roleManagerAddress;
    }

    /// @inheritdoc ITwineChain
    function setMessageHandlerAddress(
        address _messageHandler
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_messageHandler == address(0)) {
            revert ErrorZeroAddress();
        }
        messageHandler = _messageHandler;
    }

    /// @inheritdoc ITwineChain
    function setVeriferAddress(
        address _verifier
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_verifier == address(0)) {
            revert ErrorZeroAddress();
        }
        verifier = _verifier;
    }

    /// @inheritdoc ITwineChain
    function setProgramVKey(
        bytes32 _finalizeVKey,
        bytes32 _refundVKey,
        bytes32 _forcedWithdrawalVKey,
        bytes32 _l2WithdrawalVkey
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (
            _finalizeVKey == bytes32(0) ||
            _refundVKey == bytes32(0) ||
            _forcedWithdrawalVKey == bytes32(0) ||
            _l2WithdrawalVkey == bytes32(0)
        ) {
            revert InvalidVerificationKeys();
        }

        finalizeVKey = _finalizeVKey;
        refundVKey = _refundVKey;
        forcedWithdrawalVKey = _forcedWithdrawalVKey;
        l2WithdrawalVkey = _l2WithdrawalVkey;
        emit SetProgramVkey(
            _finalizeVKey,
            _refundVKey,
            _forcedWithdrawalVKey,
            _l2WithdrawalVkey
        );
    }

    /// @inheritdoc ITwineChain
    function setGatewayAddress(
        address _ethGateway,
        address _ERC20Gateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_ethGateway == address(0) || _ERC20Gateway == address(0)) {
            revert ErrorZeroAddress();
        }
        ethGateway = _ethGateway;
        ERC20Gateway = _ERC20Gateway;
    }

    /// @inheritdoc ITwineChain
    function setZkVerifcationStatus(
        bool status
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        skipVerification = status;
    }

    /// @inheritdoc ITwineChain
    function commitGenesisBlock(
        bytes32 genesisBlockHash
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        if (isGenesisBlockCommitted) revert GenesisBlockAlreadyCommitted();
        if (lastFinalizedBatchNumber != 0) revert NotAtGenesis();
        committedBatch[0] = genesisBlockHash;
        lastFinalizedBatchHash = genesisBlockHash;
        lastCommittedBatchNumber = 0;
        isGenesisBlockCommitted = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                          Commit and Finalize Batch                         */
    /* -------------------------------------------------------------------------- */
    function commitAndFinalizeBatch(
        uint64 batchNumber,
        bytes calldata publicValues,
        bytes calldata executionProof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        // Commitment
        if (batchNumber != lastCommittedBatchNumber + 1) {
            revert InvalidBatchSequence();
        }
        (
            bytes32 previousBatchHash,
            bytes32 currentBatchHash,
            uint64 executedMessageCount
        ) = TwineChainDecoder.decodeBatchValues(publicValues);

        committedBatch[batchNumber] = currentBatchHash;
        lastCommittedBatchNumber = batchNumber;

        // Finalization
        if (lastFinalizedBatchNumber != batchNumber - 1) {
            revert BatchMustBeFinalizedSequentially();
        }
        if (committedBatch[batchNumber] != currentBatchHash) {
            revert CommittedBatchHashMismatch();
        }
        if (committedBatch[batchNumber - 1] != previousBatchHash) {
            revert PreviousBatchHashMismatch();
        }
        if (previousBatchHash != lastFinalizedBatchHash) {
            revert LastFinalizedBatchHashMismatch();
        }
        if (totalMsgHandledOnTwine > executedMessageCount) {
            revert InvalidMessageCount();
        }
        if (!skipVerification) {
            SP1Verifier(verifier).verifyProof(
                finalizeVKey,
                publicValues,
                executionProof
            );
        }

        lastFinalizedBatchNumber = batchNumber;
        totalMsgHandledOnTwine = executedMessageCount;
        lastFinalizedBatchHash = currentBatchHash;
        finalizedBatch[batchNumber] = currentBatchHash;

        emit FinalizedBatch(
            batchNumber,
            executedMessageCount,
            chainId,
            block.number,
            currentBatchHash
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                               Refund Deposit                               */
    /* -------------------------------------------------------------------------- */
    function refundDeposit(
        bytes calldata publicValues,
        bytes calldata refundProof
    ) external {
        if (isRefundExecuted[keccak256(publicValues)])
            revert RefundAlreadyProcessed();

        L1OriginTxPublicValues memory refundValues = TwineChainDecoder
            .decodeL1OriginTxnPublicValues(publicValues);

        if (refundValues.txnType != TransactionType.Deposit) {
            revert TransactionMustBeDepositType();
        }

        if (!isBatchFinalized(refundValues.batchNumber)) {
            revert BatchNotFinalizedYet();
        }

        if (
            refundValues.batchHash != finalizedBatch[refundValues.batchNumber]
        ) {
            revert BatchHashMismatch();
        }
        if (
            !checkMessageHash(
                refundValues.nonce,
                keccak256(bytes(publicValues[40:]))
            )
        ) {
            revert MessageHashNotFound();
        }

        if (!skipVerification) {
            SP1Verifier(verifier).verifyProof(
                refundVKey,
                publicValues,
                refundProof
            );
        }

        executeTokenWithdrawal(
            refundValues.nonce,
            refundValues.l1Token,
            refundValues.l2Token,
            refundValues.fromAddress,
            refundValues.amount
        );
        isRefundExecuted[keccak256(publicValues)] = true;

        emit RefundSuccessful(
            refundValues.nonce,
            refundValues.fromAddress,
            refundValues.l1Token,
            refundValues.chainId,
            refundValues.amount,
            uint64(block.number)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                               Execute Withdraw                             */
    /* -------------------------------------------------------------------------- */
    function executeForcedWithdrawal(
        bytes calldata publicValues,
        bytes calldata withdrawalProof
    ) external {
        if (isForcedWithdrawExecuted[keccak256(publicValues)])
            revert WithdrawalAlreadyProcessed();
        L1OriginTxPublicValues memory withdrawValues = TwineChainDecoder
            .decodeL1OriginTxnPublicValues(publicValues);
        if (withdrawValues.txnType != TransactionType.Withdraw) {
            revert TransactionMustBeWithdrawType();
        }
        if (!isBatchFinalized(withdrawValues.batchNumber)) {
            revert BatchNotFinalizedYet();
        }
        bytes32 cachedFinalizedBatch = finalizedBatch[
            withdrawValues.batchNumber
        ];
        if (withdrawValues.batchHash != cachedFinalizedBatch) {
            revert BatchHashMismatch();
        }
        if (
            !checkMessageHash(
                withdrawValues.nonce,
                computeTransactionHash(withdrawValues)
            )
        ) {
            revert MessageHashNotFound();
        }
        if (!skipVerification) {
            SP1Verifier(verifier).verifyProof(
                forcedWithdrawalVKey,
                publicValues,
                withdrawalProof
            );
        }

        executeTokenWithdrawal(
            withdrawValues.nonce,
            withdrawValues.l1Token,
            withdrawValues.l2Token,
            withdrawValues.fromAddress,
            withdrawValues.amount
        );
        isForcedWithdrawExecuted[keccak256(publicValues)] = true;

        emit ForcedWithdrawalSuccessful(
            withdrawValues.nonce,
            withdrawValues.fromAddress,
            withdrawValues.l1Token,
            withdrawValues.chainId,
            withdrawValues.amount,
            uint64(block.number)
        );
    }

    function executeL2Withdraw(
        bytes calldata publicValues,
        bytes calldata withdrawProof
    ) external {
        if (isL2WithdrawExecuted[keccak256(publicValues)])
            revert WithdrawalAlreadyProcessed();

        L2WithdrawValues memory withdrawValues = TwineChainDecoder
            .decodeL2WithdrawValues(publicValues);

        if (!isBatchFinalized(withdrawValues.batchNumber))
            revert BatchNotFinalizedYet();
        if (
            withdrawValues.batchHash !=
            finalizedBatch[withdrawValues.batchNumber]
        ) {
            revert BatchHashMismatch();
        }

        if (!skipVerification) {
            SP1Verifier(verifier).verifyProof(
                l2WithdrawalVkey,
                publicValues,
                withdrawProof
            );
        }
        executeTokenWithdrawal(
            withdrawValues.nonce,
            withdrawValues.l1Token,
            withdrawValues.l2Token,
            withdrawValues.to,
            withdrawValues.amount
        );
        isL2WithdrawExecuted[keccak256(publicValues)] = true;
        emit L2WithdrawExecuted(
            withdrawValues.nonce,
            withdrawValues.l1Token,
            withdrawValues.l2Token,
            withdrawValues.to,
            withdrawValues.amount,
            block.number
        );
    }

    /**********************
     * Internal Functions *
     **********************/

    function checkMessageHash(
        uint64 messageNonce,
        bytes32 particularMessageHash
    ) internal view returns (bool status) {
        if (
            IL1MessageHandler(messageHandler).getMessageHash(messageNonce) ==
            particularMessageHash
        ) {
            return true;
        } else {
            return false;
        }
    }

    function executeTokenWithdrawal(
        uint64 nonce,
        string memory l1Token,
        string memory l2Token,
        string memory receiver,
        string memory amount
    ) internal {
        if (l1Token.stringToAddress() == address(0)) {
            IL1ETHGateway(ethGateway).finalizeTokenWithdrawal(
                l1Token,
                l2Token,
                receiver,
                amount,
                nonce
            );
        } else {
            // ERC20 withdrawal
            IL1ERC20Gateway(ERC20Gateway).finalizeTokenWithdrawal(
                l1Token,
                l2Token,
                receiver,
                amount,
                nonce
            );
        }
    }

    function computeTransactionHash(
        L1OriginTxPublicValues memory transactionValues
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    transactionValues.txnType,
                    transactionValues.nonce,
                    transactionValues.chainId,
                    transactionValues.blockNumber,
                    transactionValues.messageHash,
                    transactionValues.fromAddress,
                    transactionValues.toAddress,
                    transactionValues.l1Token,
                    transactionValues.l2Token,
                    transactionValues.amount
                )
            );
    }

    function extractMessageHash(
        bytes memory data
    ) internal pure returns (bytes32) {
        require(data.length > 40, "Data too short");

        uint256 newLen = data.length - 40;
        bytes memory result = new bytes(newLen);

        for (uint256 i = 0; i < newLen; i++) {
            result[i] = data[i + 40];
        }

        return keccak256(result);
    }
}
