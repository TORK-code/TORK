// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IBurnable {
    function burn(uint256 amount) external;
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function decimals() external view returns (uint8);
}

contract TORKFlip is Ownable, ReentrancyGuard {

    IERC20 public immutable playToken;
    AggregatorV3Interface public immutable bnbUsdFeed;

    uint256 public constant COMMIT_FEE_USD   = 10 * 10**16;
    uint256 public constant ENTRY_AMOUNT     = 100   * 10**18;
    uint256 public constant WIN_PAYOUT       = 42666 * 10**16;
    uint256 public constant LOSE_PAYOUT      = 75    * 10**18;
    uint256 public constant BURN_ON_LOSS     = 20    * 10**18;
    uint256 public constant FEE_ON_LOSS      = 5     * 10**18;
    uint256 public constant WIN_PROFIT       = 32666 * 10**16;
    uint256 public constant REFUND_PENALTY   = 20    * 10**18;
    uint256 public constant MAX_TURNS        = 1_000_000;
    uint256 public constant COMMIT_EXPIRY    = 256;
    uint256 public constant MIN_REVEAL_DELAY = 2;

    uint256 public prizePool;
    uint256 public reservedPool;
    uint256 public totalGames;
    uint256 public totalBurned;
    uint256 public totalPaid;
    uint256 public totalPendingWinnings;
    address public feeRecipient;
    bool    public gameActive = true;

    mapping(address => uint256) public pendingWinnings;

    struct UserStats {
        uint256 totalGames;
        uint256 totalWins;
        uint256 totalBurned;
    }
    mapping(address => UserStats) public userStats;

    struct LastGame {
        uint8   chosenSide;
        uint8   resultSide;
        bool    won;
        uint256 payout;
        uint256 timestamp;
    }
    mapping(address => LastGame) public lastGame;

    struct Commit {
        bytes32 commitHash;
        bytes32 playerSeedHash;
        uint8   chosenSide;
        uint256 blockNumber;
        bool    pending;
    }
    mapping(address => Commit) public commits;

    event GameCommitted(address indexed player, uint8 chosenSide, bytes32 playerSeedHash, uint256 commitBlock);
    event GameRevealed(address indexed player, uint8 chosenSide, uint8 resultSide, bool won, uint256 payout);
    event WinningsClaimed(address indexed player, uint256 amount);
    event CommitRefunded(address indexed player, uint256 refundAmount, uint256 penaltyBurned);
    event TokensBurned(address indexed player, uint256 amount);
    event FeeCollected(address indexed player, uint256 amount);
    event PrizePoolFunded(address indexed funder, uint256 amount);
    event CommitRefundedEmptyPool(address indexed player, uint256 refundAmount);
    event GameEnded(uint256 totalTurns, uint256 remainingPool);

    modifier onlyActive() {
        require(gameActive, "Game has ended");
        _;
    }

    constructor(address _token, address _bnbUsdFeed, address _feeRecipient) Ownable(msg.sender) {
        require(_token != address(0), "Invalid token");
        require(_bnbUsdFeed != address(0), "Invalid feed");
        require(_feeRecipient != address(0), "Invalid fee recipient");
        playToken = IERC20(_token);
        bnbUsdFeed = AggregatorV3Interface(_bnbUsdFeed);
        feeRecipient = _feeRecipient;
    }

    function getCommitFee() public view returns (uint256) {
        (, int256 price,, uint256 updatedAt,) = bnbUsdFeed.latestRoundData();
        require(price > 0, "Invalid price feed");
        require(block.timestamp - updatedAt <= 3600, "Price feed stale");
        uint8 feedDecimals = bnbUsdFeed.decimals();
        return (COMMIT_FEE_USD * (10 ** uint256(feedDecimals))) / uint256(price);
    }

    function commit(uint8 chosenSide, bytes32 playerSeedHash) external payable nonReentrant onlyActive {
        uint256 requiredFee = getCommitFee();
        require(msg.value >= requiredFee, "Insufficient commit fee");
        require(chosenSide <= 1, "Invalid side: 0=Heads, 1=Tails");
        require(playerSeedHash != bytes32(0), "Invalid seed hash");
        require(!commits[msg.sender].pending, "Pending commit exists");
        require(totalGames < MAX_TURNS, "Max turns reached");

        uint256 availablePool = prizePool > reservedPool ? prizePool - reservedPool : 0;
        require(availablePool >= WIN_PROFIT, "Prize pool insufficient");

        require(playToken.balanceOf(msg.sender) >= ENTRY_AMOUNT, "Insufficient token balance");
        require(playToken.allowance(msg.sender, address(this)) >= ENTRY_AMOUNT, "Insufficient allowance");
        require(playToken.transferFrom(msg.sender, address(this), ENTRY_AMOUNT), "Token transfer failed");

        reservedPool += WIN_PROFIT;

        commits[msg.sender] = Commit({
            commitHash: keccak256(abi.encodePacked(msg.sender, chosenSide, block.number, block.prevrandao)),
            playerSeedHash: playerSeedHash,
            chosenSide: chosenSide,
            blockNumber: block.number,
            pending: true
        });

        if (msg.value > 0) {
            (bool sent,) = feeRecipient.call{value: msg.value}("");
            require(sent, "Fee transfer failed");
        }

        emit GameCommitted(msg.sender, chosenSide, playerSeedHash, block.number);
    }

    function reveal(bytes32 playerSeed) external nonReentrant onlyActive returns (uint8 resultSide, bool won, uint256 payout) {
        Commit storage c = commits[msg.sender];
        require(c.pending, "No pending commit");
        require(keccak256(abi.encodePacked(playerSeed)) == c.playerSeedHash, "Invalid player seed");
        require(block.number > c.blockNumber + MIN_REVEAL_DELAY, "Wait for reveal block");
        require(block.number <= c.blockNumber + COMMIT_EXPIRY, "Commit expired, use refund");

        bytes32 bHash = blockhash(c.blockNumber + 2);
        require(bHash != bytes32(0), "Block hash unavailable");

        uint256 rng = uint256(keccak256(abi.encodePacked(
            bHash, c.commitHash, playerSeed, msg.sender, totalGames
        )));
        won = (rng % 10 < 6);
        resultSide = won ? c.chosenSide : (1 - c.chosenSide);

        reservedPool = reservedPool >= WIN_PROFIT ? reservedPool - WIN_PROFIT : 0;

        if (won) {
            payout = WIN_PAYOUT;
            prizePool = prizePool >= WIN_PROFIT ? prizePool - WIN_PROFIT : 0;
        } else {
            payout = LOSE_PAYOUT;
            IBurnable(address(playToken)).burn(BURN_ON_LOSS);
            totalBurned += BURN_ON_LOSS;
            userStats[msg.sender].totalBurned += BURN_ON_LOSS;
            emit TokensBurned(msg.sender, BURN_ON_LOSS);

            require(playToken.transfer(feeRecipient, FEE_ON_LOSS), "Fee transfer failed");
            emit FeeCollected(msg.sender, FEE_ON_LOSS);
        }

        pendingWinnings[msg.sender] += payout;
        totalPendingWinnings += payout;

        lastGame[msg.sender] = LastGame(c.chosenSide, resultSide, won, payout, block.timestamp);
        totalGames++;
        totalPaid += payout;
        userStats[msg.sender].totalGames++;
        if (won) userStats[msg.sender].totalWins++;

        c.pending = false;

        if (totalGames >= MAX_TURNS) {
            gameActive = false;
            emit GameEnded(totalGames, prizePool);
        }

        emit GameRevealed(msg.sender, c.chosenSide, resultSide, won, payout);
        return (resultSide, won, payout);
    }

    function refundExpiredCommit() external nonReentrant {
        Commit storage c = commits[msg.sender];
        require(c.pending, "No pending commit");
        require(block.number > c.blockNumber + COMMIT_EXPIRY, "Not expired yet");

        reservedPool = reservedPool >= WIN_PROFIT ? reservedPool - WIN_PROFIT : 0;
        c.pending = false;

        if (prizePool < WIN_PROFIT) {
            require(playToken.transfer(msg.sender, ENTRY_AMOUNT), "Refund transfer failed");
            emit CommitRefunded(msg.sender, ENTRY_AMOUNT, 0);
        } else {
            IBurnable(address(playToken)).burn(REFUND_PENALTY);
            totalBurned += REFUND_PENALTY;
            emit TokensBurned(msg.sender, REFUND_PENALTY);
            uint256 refundAmount = ENTRY_AMOUNT - REFUND_PENALTY;
            require(playToken.transfer(msg.sender, refundAmount), "Refund transfer failed");
            emit CommitRefunded(msg.sender, refundAmount, REFUND_PENALTY);
        }
    }

    function claim() external nonReentrant {
        uint256 amount = pendingWinnings[msg.sender];
        require(amount > 0, "Nothing to claim");

        pendingWinnings[msg.sender] = 0;
        totalPendingWinnings = totalPendingWinnings >= amount ? totalPendingWinnings - amount : 0;

        require(playToken.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        require(playToken.transfer(msg.sender, amount), "Claim transfer failed");

        emit WinningsClaimed(msg.sender, amount);
    }

    function getGameInfo() external view returns (
        uint256 _prizePool,
        uint256 _totalGames,
        uint256 _totalPaid,
        uint256 _totalBurned,
        uint256 _reservedPool,
        uint256 _availablePool,
        uint256 _remainingTurns,
        bool    _gameActive
    ) {
        uint256 avail = prizePool > reservedPool ? prizePool - reservedPool : 0;
        uint256 remaining = totalGames < MAX_TURNS ? MAX_TURNS - totalGames : 0;
        return (prizePool, totalGames, totalPaid, totalBurned, reservedPool, avail, remaining, gameActive);
    }

    function getUserStats(address user) external view returns (
        uint256 _games,
        uint256 _wins,
        uint256 _losses,
        uint256 _burned
    ) {
        UserStats memory s = userStats[user];
        uint256 losses = s.totalGames - s.totalWins;
        return (s.totalGames, s.totalWins, losses, s.totalBurned);
    }

    function getLastGame(address user) external view returns (
        uint8   _chosenSide,
        uint8   _resultSide,
        bool    _won,
        uint256 _payout,
        uint256 _timestamp
    ) {
        LastGame memory g = lastGame[user];
        return (g.chosenSide, g.resultSide, g.won, g.payout, g.timestamp);
    }

    function getCommitStatus(address user) external view returns (
        bool    _pending,
        uint256 _blockNumber,
        uint8   _chosenSide,
        bytes32 _playerSeedHash
    ) {
        Commit memory c = commits[user];
        return (c.pending, c.blockNumber, c.chosenSide, c.playerSeedHash);
    }

    function getPendingWinnings(address user) external view returns (uint256) {
        return pendingWinnings[user];
    }

    function canPlay() external view returns (bool) {
        if (!gameActive) return false;
        if (totalGames >= MAX_TURNS) return false;
        uint256 avail = prizePool > reservedPool ? prizePool - reservedPool : 0;
        return avail >= WIN_PROFIT;
    }

    function fundPrizePool(uint256 amount) external onlyOwner {
        require(playToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        prizePool += amount;
        emit PrizePoolFunded(msg.sender, amount);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid address");
        feeRecipient = _feeRecipient;
    }

    function refundOnEmptyPool() external nonReentrant {
        Commit storage c = commits[msg.sender];
        require(c.pending, "No pending commit");
        uint256 availablePool = prizePool > reservedPool ? prizePool - reservedPool : 0;
        require(availablePool < WIN_PROFIT, "Pool is sufficient, use reveal");
        reservedPool = reservedPool >= WIN_PROFIT ? reservedPool - WIN_PROFIT : 0;
        c.pending = false;
        require(playToken.transfer(msg.sender, ENTRY_AMOUNT), "Refund failed");
        emit CommitRefundedEmptyPool(msg.sender, ENTRY_AMOUNT);
    }

}
