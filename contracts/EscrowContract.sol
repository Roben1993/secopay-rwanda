// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EscrowContract
 * @dev Secure escrow contract for P2P transactions using USDT/USDC on Polygon
 * @notice This contract holds buyer funds until delivery confirmation
 * Perfect for Rwanda & Global markets - Low fees on Polygon!
 */
contract EscrowContract is ReentrancyGuard, Ownable {

    // ============================================================================
    // STATE VARIABLES
    // ============================================================================

    /// Platform fee percentage (in basis points: 200 = 2%)
    uint256 public platformFee = 200; // 2% default fee

    /// Fee recipient address
    address payable public feeRecipient;

    /// Escrow counter for generating unique IDs
    uint256 private escrowCounter;

    // ============================================================================
    // ENUMS
    // ============================================================================

    enum EscrowStatus {
        Created,      // Escrow created, waiting for funding
        Funded,       // Buyer has funded the escrow
        Shipped,      // Seller marked as shipped
        Delivered,    // Buyer confirmed delivery
        Completed,    // Funds released to seller
        Disputed,     // Dispute raised
        Cancelled     // Escrow cancelled
    }

    // ============================================================================
    // STRUCTS
    // ============================================================================

    struct Escrow {
        uint256 id;                    // Unique escrow ID
        address buyer;                 // Buyer address
        address seller;                // Seller address
        address tokenAddress;          // USDT/USDC contract address
        uint256 amount;                // Escrow amount (in smallest unit)
        uint256 platformFeeAmount;     // Platform fee amount
        EscrowStatus status;           // Current status
        uint256 createdAt;             // Creation timestamp
        uint256 fundedAt;              // Funding timestamp
        uint256 deliveredAt;           // Delivery confirmation timestamp
        uint256 completedAt;           // Completion timestamp
        bool buyerConfirmed;           // Buyer confirmation
        bool sellerConfirmed;          // Seller confirmation
        string metadata;               // Additional data (IPFS hash)
    }

    // ============================================================================
    // MAPPINGS
    // ============================================================================

    /// Mapping from escrow ID to Escrow struct
    mapping(uint256 => Escrow) public escrows;

    /// Mapping to track user's escrows
    mapping(address => uint256[]) public userEscrows;

    // ============================================================================
    // EVENTS
    // ============================================================================

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        address tokenAddress,
        uint256 amount,
        uint256 timestamp
    );

    event EscrowFunded(
        uint256 indexed escrowId,
        address indexed buyer,
        uint256 amount,
        uint256 timestamp
    );

    event EscrowShipped(
        uint256 indexed escrowId,
        address indexed seller,
        uint256 timestamp
    );

    event EscrowDelivered(
        uint256 indexed escrowId,
        address indexed buyer,
        uint256 timestamp
    );

    event EscrowCompleted(
        uint256 indexed escrowId,
        address indexed seller,
        uint256 amount,
        uint256 platformFee,
        uint256 timestamp
    );

    event EscrowDisputed(
        uint256 indexed escrowId,
        address indexed disputedBy,
        uint256 timestamp
    );

    event EscrowCancelled(
        uint256 indexed escrowId,
        address indexed cancelledBy,
        uint256 timestamp
    );

    event DisputeResolved(
        uint256 indexed escrowId,
        address winner,
        uint256 timestamp
    );

    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);

    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    // ============================================================================
    // MODIFIERS
    // ============================================================================

    modifier onlyBuyer(uint256 _escrowId) {
        require(escrows[_escrowId].buyer == msg.sender, "Not the buyer");
        _;
    }

    modifier onlySeller(uint256 _escrowId) {
        require(escrows[_escrowId].seller == msg.sender, "Not the seller");
        _;
    }

    modifier onlyParticipant(uint256 _escrowId) {
        require(
            escrows[_escrowId].buyer == msg.sender ||
            escrows[_escrowId].seller == msg.sender,
            "Not a participant"
        );
        _;
    }

    modifier escrowExists(uint256 _escrowId) {
        require(escrows[_escrowId].id == _escrowId, "Escrow does not exist");
        _;
    }

    modifier inStatus(uint256 _escrowId, EscrowStatus _status) {
        require(escrows[_escrowId].status == _status, "Invalid escrow status");
        _;
    }

    // ============================================================================
    // CONSTRUCTOR
    // ============================================================================

    constructor(address payable _feeRecipient) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
        escrowCounter = 0;
    }

    // ============================================================================
    // CORE ESCROW FUNCTIONS
    // ============================================================================

    /**
     * @dev Create new escrow
     * @param _seller Seller address
     * @param _tokenAddress USDT/USDC contract address
     * @param _amount Escrow amount in smallest unit (e.g., 1 USDT = 1000000)
     * @param _metadata Additional metadata (IPFS hash)
     * @return escrowId The created escrow ID
     */
    function createEscrow(
        address _seller,
        address _tokenAddress,
        uint256 _amount,
        string memory _metadata
    ) external returns (uint256) {
        require(_seller != address(0), "Invalid seller address");
        require(_seller != msg.sender, "Cannot create escrow with yourself");
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than 0");

        // Increment counter
        escrowCounter++;
        uint256 escrowId = escrowCounter;

        // Calculate platform fee
        uint256 feeAmount = (_amount * platformFee) / 10000;

        // Create escrow
        Escrow storage newEscrow = escrows[escrowId];
        newEscrow.id = escrowId;
        newEscrow.buyer = msg.sender;
        newEscrow.seller = _seller;
        newEscrow.tokenAddress = _tokenAddress;
        newEscrow.amount = _amount;
        newEscrow.platformFeeAmount = feeAmount;
        newEscrow.status = EscrowStatus.Created;
        newEscrow.createdAt = block.timestamp;
        newEscrow.metadata = _metadata;

        // Track user escrows
        userEscrows[msg.sender].push(escrowId);
        userEscrows[_seller].push(escrowId);

        emit EscrowCreated(escrowId, msg.sender, _seller, _tokenAddress, _amount, block.timestamp);

        return escrowId;
    }

    /**
     * @dev Fund escrow by transferring tokens to contract
     * @param _escrowId Escrow ID
     * @notice Buyer must approve tokens before calling this function
     */
    function fundEscrow(uint256 _escrowId)
        external
        nonReentrant
        escrowExists(_escrowId)
        onlyBuyer(_escrowId)
        inStatus(_escrowId, EscrowStatus.Created)
    {
        Escrow storage escrow = escrows[_escrowId];

        // Transfer tokens from buyer to contract (including platform fee)
        uint256 totalAmount = escrow.amount + escrow.platformFeeAmount;
        IERC20 token = IERC20(escrow.tokenAddress);

        require(
            token.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        // Update status
        escrow.status = EscrowStatus.Funded;
        escrow.fundedAt = block.timestamp;

        emit EscrowFunded(_escrowId, msg.sender, escrow.amount, block.timestamp);
    }

    /**
     * @dev Seller marks item as shipped
     * @param _escrowId Escrow ID
     */
    function markAsShipped(uint256 _escrowId)
        external
        escrowExists(_escrowId)
        onlySeller(_escrowId)
        inStatus(_escrowId, EscrowStatus.Funded)
    {
        Escrow storage escrow = escrows[_escrowId];
        escrow.status = EscrowStatus.Shipped;

        emit EscrowShipped(_escrowId, msg.sender, block.timestamp);
    }

    /**
     * @dev Buyer confirms delivery
     * @param _escrowId Escrow ID
     */
    function confirmDelivery(uint256 _escrowId)
        external
        escrowExists(_escrowId)
        onlyBuyer(_escrowId)
        inStatus(_escrowId, EscrowStatus.Shipped)
    {
        Escrow storage escrow = escrows[_escrowId];
        escrow.status = EscrowStatus.Delivered;
        escrow.deliveredAt = block.timestamp;

        emit EscrowDelivered(_escrowId, msg.sender, block.timestamp);
    }

    /**
     * @dev Release funds to seller (after delivery confirmation)
     * @param _escrowId Escrow ID
     * @notice Can be called by buyer or seller after 48 hours
     */
    function releaseFunds(uint256 _escrowId)
        external
        nonReentrant
        escrowExists(_escrowId)
        onlyParticipant(_escrowId)
        inStatus(_escrowId, EscrowStatus.Delivered)
    {
        Escrow storage escrow = escrows[_escrowId];

        // Check 48-hour waiting period (optional, can be removed)
        // require(
        //     block.timestamp >= escrow.deliveredAt + 48 hours,
        //     "Must wait 48 hours before release"
        // );

        IERC20 token = IERC20(escrow.tokenAddress);

        // Transfer escrow amount to seller
        require(
            token.transfer(escrow.seller, escrow.amount),
            "Transfer to seller failed"
        );

        // Transfer platform fee to fee recipient
        require(
            token.transfer(feeRecipient, escrow.platformFeeAmount),
            "Transfer of platform fee failed"
        );

        // Update status
        escrow.status = EscrowStatus.Completed;
        escrow.completedAt = block.timestamp;

        emit EscrowCompleted(_escrowId, escrow.seller, escrow.amount, escrow.platformFeeAmount, block.timestamp);
    }

    /**
     * @dev Cancel escrow before funding
     * @param _escrowId Escrow ID
     */
    function cancelEscrow(uint256 _escrowId)
        external
        escrowExists(_escrowId)
        onlyParticipant(_escrowId)
        inStatus(_escrowId, EscrowStatus.Created)
    {
        Escrow storage escrow = escrows[_escrowId];
        escrow.status = EscrowStatus.Cancelled;

        emit EscrowCancelled(_escrowId, msg.sender, block.timestamp);
    }

    // ============================================================================
    // DISPUTE FUNCTIONS
    // ============================================================================

    /**
     * @dev Raise dispute
     * @param _escrowId Escrow ID
     */
    function raiseDispute(uint256 _escrowId)
        external
        escrowExists(_escrowId)
        onlyParticipant(_escrowId)
    {
        Escrow storage escrow = escrows[_escrowId];

        require(
            escrow.status == EscrowStatus.Funded ||
            escrow.status == EscrowStatus.Shipped ||
            escrow.status == EscrowStatus.Delivered,
            "Cannot dispute in current status"
        );

        escrow.status = EscrowStatus.Disputed;

        emit EscrowDisputed(_escrowId, msg.sender, block.timestamp);
    }

    /**
     * @dev Resolve dispute (admin only)
     * @param _escrowId Escrow ID
     * @param _winner Winner address (buyer or seller)
     */
    function resolveDispute(uint256 _escrowId, address _winner)
        external
        nonReentrant
        onlyOwner
        escrowExists(_escrowId)
        inStatus(_escrowId, EscrowStatus.Disputed)
    {
        Escrow storage escrow = escrows[_escrowId];

        require(
            _winner == escrow.buyer || _winner == escrow.seller,
            "Winner must be buyer or seller"
        );

        IERC20 token = IERC20(escrow.tokenAddress);
        uint256 totalAmount = escrow.amount + escrow.platformFeeAmount;

        if (_winner == escrow.seller) {
            // Seller wins: release funds to seller + platform fee
            require(
                token.transfer(escrow.seller, escrow.amount),
                "Transfer to seller failed"
            );
            require(
                token.transfer(feeRecipient, escrow.platformFeeAmount),
                "Transfer of platform fee failed"
            );
        } else {
            // Buyer wins: refund full amount to buyer (no platform fee)
            require(
                token.transfer(escrow.buyer, totalAmount),
                "Refund to buyer failed"
            );
        }

        escrow.status = EscrowStatus.Completed;
        escrow.completedAt = block.timestamp;

        emit DisputeResolved(_escrowId, _winner, block.timestamp);
    }

    // ============================================================================
    // VIEW FUNCTIONS
    // ============================================================================

    /**
     * @dev Get escrow details
     * @param _escrowId Escrow ID
     */
    function getEscrow(uint256 _escrowId)
        external
        view
        escrowExists(_escrowId)
        returns (Escrow memory)
    {
        return escrows[_escrowId];
    }

    /**
     * @dev Get user's escrow IDs
     * @param _user User address
     */
    function getUserEscrows(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return userEscrows[_user];
    }

    /**
     * @dev Get total number of escrows
     */
    function getTotalEscrows() external view returns (uint256) {
        return escrowCounter;
    }

    // ============================================================================
    // ADMIN FUNCTIONS
    // ============================================================================

    /**
     * @dev Update platform fee (admin only)
     * @param _newFee New fee in basis points (e.g., 200 = 2%)
     */
    function updatePlatformFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee cannot exceed 10%"); // Max 10% fee
        uint256 oldFee = platformFee;
        platformFee = _newFee;
        emit PlatformFeeUpdated(oldFee, _newFee);
    }

    /**
     * @dev Update fee recipient (admin only)
     * @param _newRecipient New fee recipient address
     */
    function updateFeeRecipient(address payable _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid recipient");
        address oldRecipient = feeRecipient;
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(oldRecipient, _newRecipient);
    }

    /**
     * @dev Emergency withdraw (admin only) - for stuck tokens
     * @param _token Token address
     * @param _amount Amount to withdraw
     */
    function emergencyWithdraw(address _token, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        IERC20 token = IERC20(_token);
        require(token.transfer(owner(), _amount), "Emergency withdraw failed");
    }
}
