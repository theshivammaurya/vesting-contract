// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Vesting is Ownable {
    struct VestingInfo {
        uint256 allocatedAmount;
        uint256 claimedAmount;
        uint256 nextClaimTimestamp;
        uint256 claimEndTimestamp;
    }

    struct UserInfo {
        address wallet;
        uint256 totalAllocatedAmount;
        uint256 totalClaimedAmount;
        // uint256 vestingCount;
    }

    // IERC20 public token;
    uint256 public adminComm;
    uint256 public claimEndDay;
    uint256 public vestingEndDay;
    uint256 public EndDay;

    mapping(address => UserInfo) public userInfo;
    mapping(address => VestingInfo[]) private userVestingInfo;
    mapping(address => bool) public allocatedUser;

    event Withdraw(uint256 amount, uint256 timestamp);

    constructor(
        uint256 _adminComm,
        uint256 _vestingEndDay,
        uint256 _claimEndDay
    ) {
        // token = IERC20(_token);
        require(
            _vestingEndDay > 0 && _claimEndDay > 0,
            " Day should not be Zero"
        );
        adminComm = _adminComm;
        vestingEndDay = _vestingEndDay * 86400;
        claimEndDay = _claimEndDay * 86400;
        EndDay = _claimEndDay;
    }

    function updateAdminCommission(uint256 _adminComm) external onlyOwner {
        adminComm = _adminComm;
    }

    function updateVestingDays(uint256 _vestingEndDay, uint256 _claimEndDay)
        external
        onlyOwner
    {
        require(
            _vestingEndDay > 0 && _claimEndDay > 0,
            " Day should not be Zero"
        );
        vestingEndDay = _vestingEndDay * 86400;
        claimEndDay = _claimEndDay * 86400;
        EndDay = _claimEndDay;
    }

    function allocateForVesting(address _user) external payable onlyOwner {
        // require(
        //     !allocatedUser[_user],
        //     "vesting already allocated to this address"
        // );
        // token.transferFrom(msg.sender, address(this), _amount);
        _allocateAmount(_user, msg.value);
        allocatedUser[_user] = true;
    }

    function _allocateAmount(address _user, uint256 _amount) internal {
        UserInfo storage user = userInfo[_user];
        VestingInfo[] storage vestingInfo = userVestingInfo[_user];

        // uint256 duration = 1 days;
        uint256 vestingStartTimestamp = block.timestamp + vestingEndDay; //Changes

        user.wallet = _user;

        if (allocatedUser[_user]) {
            user.totalAllocatedAmount += _amount;
            user.totalClaimedAmount = user.totalClaimedAmount;
        } else {
            user.totalAllocatedAmount = _amount;
            user.totalClaimedAmount = 0;
        }

        // vestingInfo[vestingInfo.length].nextClaimTimestamp = vestingStartTimestamp;
        // vestingInfo[vestingInfo.length].tokensUnlockedAmount = 0;

        vestingInfo.push(
            VestingInfo({
                allocatedAmount: _amount,
                claimedAmount: 0,
                nextClaimTimestamp: vestingStartTimestamp,
                claimEndTimestamp: vestingStartTimestamp + claimEndDay //Changes
            })
        );
    }

    function claimTokens(address _user, uint256 _id) public {
        require(allocatedUser[_user], "Funds not allocated to this user");

        UserInfo storage user = userInfo[_user];

        // require(block.timestamp >= userVestingInfo[_user][_id].nextClaimTimestamp, "Cannot claim before claim start time");

        (uint256 tokensToSend, uint256 numberOfDays) = getUnlockedTokenAmount(
            user.wallet,
            _id
        );

        // tokensToSend = tokensToSend - user.claimedAmount;

        require(tokensToSend != 0, "Claim amount is insufficient");

        if (tokensToSend > 0) {
            uint256 fee = (tokensToSend * adminComm) / 10000;

            // token.transfer(_user, tokensToSend);
            // payable(_user).transfer(tokensToSend);

            payable(owner()).transfer(fee);
            payable(_user).transfer(tokensToSend - fee);

            user.totalClaimedAmount += tokensToSend;
            userVestingInfo[_user][_id].claimedAmount += tokensToSend;
            emit Withdraw(tokensToSend, block.timestamp);
        }

        uint256 nextClaimTime = userVestingInfo[_user][_id].nextClaimTimestamp +
            (numberOfDays * 86400);

        if (
            userVestingInfo[_user][_id].claimedAmount ==
            userVestingInfo[_user][_id].allocatedAmount
        ) {
            userVestingInfo[_user][_id].nextClaimTimestamp = 0;
        } else {
            userVestingInfo[_user][_id].nextClaimTimestamp = nextClaimTime;
        }
    }

    function claimTotalTokens(address _user, uint256 _id) external onlyOwner {
        UserInfo storage user = userInfo[_user];

        uint256 leftBalance = userVestingInfo[_user][_id].allocatedAmount -
            userVestingInfo[_user][_id].claimedAmount;

        uint256 fee = (leftBalance * adminComm) / 10000;

        userVestingInfo[_user][_id].nextClaimTimestamp = 0;
        user.totalClaimedAmount += leftBalance;
        userVestingInfo[_user][_id].claimedAmount += leftBalance;

        // token.transfer(owner(), fee);
        // token.transfer(_user, leftBalance - fee);

        payable(owner()).transfer(fee);
        payable(_user).transfer(leftBalance - fee);
        emit Withdraw(leftBalance, block.timestamp);
    }

    function getUnlockedTokenAmount(address _wallet, uint256 _id)
        public
        view
        returns (uint256, uint256)
    {
        VestingInfo[] memory vestingInfo = userVestingInfo[_wallet];

        uint256 allowedAmount = 0;
        uint256 numberOfDays = 0;

        if (!allocatedUser[_wallet]) {
            return (0, 0);
        }

        if (block.timestamp >= vestingInfo[_id].nextClaimTimestamp) {
            if (vestingInfo[_id].nextClaimTimestamp != 0) {
                uint256 fromTime = block.timestamp >
                    vestingInfo[_id].claimEndTimestamp
                    ? vestingInfo[_id].claimEndTimestamp - 86400
                    : block.timestamp;
                uint256 duration = (fromTime -
                    vestingInfo[_id].nextClaimTimestamp) + 86400;
                numberOfDays = duration / 86400;

                allowedAmount =
                    (userVestingInfo[_wallet][_id].allocatedAmount / EndDay) *
                    numberOfDays;
            }
        }

        // allowedAmount = allowedAmount - user.claimedAmount;

        if (
            allowedAmount >
            (userVestingInfo[_wallet][_id].allocatedAmount -
                userVestingInfo[_wallet][_id].claimedAmount)
        ) {
            allowedAmount = (userVestingInfo[_wallet][_id].allocatedAmount -
                userVestingInfo[_wallet][_id].claimedAmount);
        }

        return (allowedAmount, numberOfDays);
    }

    function getVestingInfo(address _user, uint256 _id)
        public
        view
        returns (VestingInfo memory)
    {
        return userVestingInfo[_user][_id];
    }

    function getUserTotalVesting(address _user) public view returns (uint256) {
        return userVestingInfo[_user].length;
    }

    function drainTokens(uint256 _amount) external onlyOwner {
        // token.transfer(msg.sender, _amount);
        payable(msg.sender).transfer(_amount);
    }

    function updateVestingStartTimestamp(
        address _user,
        uint256 index,
        uint256 _newVestingStartTimestamp
    ) external onlyOwner {
        require(
            _newVestingStartTimestamp > 0,
            "New vesting start time should not be zero"
        );
        //require(userVestingInfo[_user].length > index, "Invalid index");
        require(_user != address(0), "Invalid user address");

        userVestingInfo[_user][index]
            .nextClaimTimestamp = _newVestingStartTimestamp;
        userVestingInfo[_user][index].claimEndTimestamp =
            _newVestingStartTimestamp +
            claimEndDay;
    }
}