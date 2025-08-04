// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/console.sol";

import {SP1Verifier} from "@sp1-contracts/v4.0.0-rc.3/SP1VerifierGroth16.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineChain} from "./ITwineChain.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";
import {ITwineDVN} from "../../lzdvn/interfaces/ITwineDVN.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TwineChainDecoder} from "../../libraries/decoders/TwineChainDecoder.sol";
import {IL1ETHGateway} from "../gateways/interfaces/IL1ETHGateway.sol";
import {IL1ERC20Gateway} from "../gateways/interfaces/IL1ERC20Gateway.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";

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
    uint256 totalMsgHandledOnTwine;

    /// @notice The latest committed batch number
    uint256 public override lastCommittedBatchNumber;

    /// @notice The latest finalized batch number
    uint256 public override lastFinalizedBatchNumber;

    /// @notice The verification key for finalize proof
    bytes32 public finalizeVKey;

    /// @notice The verification key for withdrawal proof
    bytes32 public withdrawalVKey;

    /// @notice The verification key for refund proof.
    bytes32 public refundVKey;

    //@notice The last finalize batch hash
    bytes32 public lastFinalizedBatchHash;

    //gateway address of eth
    address public ethGateway;

    //gateway address of erc20 gateway
    address public ERC20Gateway;

    /// @notice The address of L1MessageQueue contract.
    address public messageQueue;

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
    mapping(bytes32 => bool) public isWithdrawExecuted;

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
    /// @param _messageQueue The address of `L1MessageQueue` contract.
    /// @param _verifier The address of zkevm verifier contract.
    function initialize(
        address _messageQueue,
        address _verifier,
        address _roleManager
    ) external initializer {
        messageQueue = _messageQueue;
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
    function setMessengerQueueAddress(
        address _messageQueue
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_messageQueue == address(0)) {
            revert ErrorZeroAddress();
        }
        messageQueue = _messageQueue;
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
        bytes32 _withdrawalVKey
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(
            _finalizeVKey != bytes32(0) &&
                _refundVKey != bytes32(0) &&
                _withdrawalVKey != bytes32(0),
            "Keys can not be zero"
        );
        finalizeVKey = _finalizeVKey;
        refundVKey = _refundVKey;
        withdrawalVKey = _withdrawalVKey;

        emit SetProgramVkey(_finalizeVKey, _refundVKey, _withdrawalVKey);
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
        require(!isGenesisBlockCommitted, "Genesis Block already committed");
        require(lastFinalizedBatchNumber == 0, "Not at genesis");
        committedBatch[0] = genesisBlockHash;
        lastFinalizedBatchHash = genesisBlockHash;
        lastCommittedBatchNumber = 0;
        isGenesisBlockCommitted = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                COMMIT BATCH                                */
    /* -------------------------------------------------------------------------- */
    function commitBatch(
        uint64 batchNumber,
        bytes32 batchHash
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        require(
            batchNumber == lastCommittedBatchNumber + 1,
            "Invalid batch sequence or message count"
        );
        committedBatch[batchNumber] = batchHash;
        lastCommittedBatchNumber = batchNumber;
        emit CommitedBatch(batchNumber, chainId, block.number, batchHash);
    }

    /* -------------------------------------------------------------------------- */
    /*                               FINALIZE BATCH                               */
    /* -------------------------------------------------------------------------- */
    function finalizeBatch(
        uint64 batchNumber,
        bytes calldata publicValues,
        bytes calldata executionProof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        (
            bytes32 previousBatchHash,
            bytes32 currentBatchHash,
            uint64 executedMessageCount
        ) = TwineChainDecoder.decodeBatchValues(publicValues);

        require(
            lastFinalizedBatchNumber == batchNumber - 1,
            "Batch must be finalized sequencially"
        );
        require(
            committedBatch[batchNumber] == currentBatchHash,
            "Batch Hash Mismatch: commited batch"
        );
        require(
            committedBatch[batchNumber - 1] == previousBatchHash,
            "Batch Hash Mismatch: prev comited batch"
        );
        require(
            previousBatchHash == lastFinalizedBatchHash,
            "Batch Hash mismatch: last finalized batch hash"
        );
        require(
            totalMsgHandledOnTwine <= executedMessageCount,
            "Invalid message count"
        );
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
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        (
            uint64 batchNumber,
            bytes32 batchHash,
            TransactionType txnType,
            uint64 messageNonce
        ) = abi.decode(
                publicValues,
                (uint64, bytes32, TransactionType, uint64)
            );
        require(isBatchFinalized(batchNumber), "Batch is not finalized yet");
        require(
            batchHash == finalizedBatch[batchNumber],
            "Given Batch hash mismatch"
        );

        require(
            txnType == TransactionType.Deposit,
            "Transaction must be deposit type"
        );
        // message hash of the particular trandaction is checked
        require(
            checkMessageHash(messageNonce, keccak256(bytes(publicValues[40:]))),
            "Message hash doesn't exist"
        );

        if (!skipVerification) {
            SP1Verifier(verifier).verifyProof(
                refundVKey,
                publicValues,
                refundProof
            );
        }
        (
            ,
            ,
            ,
            ,
            ,
            ,
            string memory fromAddress,
            ,
            string memory l1Token,
            string memory l2Token,
            string memory amount,

        ) = abi.decode(
                publicValues,
                (
                    uint64,
                    bytes32,
                    TransactionType,
                    uint64,
                    uint64,
                    uint64,
                    string,
                    string,
                    string,
                    string,
                    string,
                    bytes
                )
            );
        _executeTokenWithdrawal(
            messageNonce,
            l1Token,
            l2Token,
            fromAddress,
            amount
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                               Execute Withdraw                             */
    /* -------------------------------------------------------------------------- */
    function executeL2Withdraw(
        bytes calldata publicValues,
        bytes calldata withdrawProof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        L2WithdrawValues memory withdrawValues = TwineChainDecoder
            .decodeL2WithdrawValues(publicValues);
        isBatchFinalized(withdrawValues.batchNumber);
        if (!skipVerification) {
            SP1Verifier(verifier).verifyProof(
                refundVKey,
                publicValues,
                withdrawProof
            );
        }
        _executeTokenWithdrawal(
            withdrawValues.nonce,
            withdrawValues.l1Token,
            withdrawValues.l2Token,
            withdrawValues.to,
            withdrawValues.amount
        );
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
    function _finalizeWithdrawal(RefundValues memory refundValues) internal {
        if (refundValues.l1Token.stringToAddress() == address(0)) {
            IL1ETHGateway(ethGateway).finalizeTokenWithdrawal(
                refundValues.l1Token,
                refundValues.l2Token,
                refundValues.toAddress,
                refundValues.amount,
                refundValues.nonce
            );
        } else {
            IL1ERC20Gateway(ERC20Gateway).finalizeTokenWithdrawal(
                refundValues.l1Token,
                refundValues.l2Token,
                refundValues.toAddress,
                refundValues.amount,
                refundValues.nonce
            );
        }
    }

    function checkMessageHash(
        uint64 messageNonce,
        bytes32 particularMessageHash
    ) internal view returns (bool status) {
        bytes32 finalHashedMessage = keccak256(
            abi.encodePacked(
                particularMessageHash,
                IL1MessageQueue(messageQueue).getMessageHash(messageNonce - 1)
            )
        );
        if (
            IL1MessageQueue(messageQueue).getMessageHash(messageNonce) ==
            finalHashedMessage
        ) {
            return true;
        } else {
            return false;
        }
    }

    function _executeTokenWithdrawal(
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
}
