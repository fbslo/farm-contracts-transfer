pragma solidity ^0.8.2;
//SPDX-License-Identifier: MIT

/*
* Forwarder for CUB dev share of inflation, burn 90%, 10% team share
*/

contract Forwarder {
    using SafeMath for uint256;
    
    address[] public owners;
    address[] public timelocks;
    address public dead = 0x000000000000000000000000000000000000dEaD;
    address public cub_token;
    address public masterChef;
    uint256 burnPercentage = 900;
    
    event Claim(uint256 balance, address[] timelocks);
    
    constructor(address[] memory _owners, address[] memory _timelocks, address _cub, address _master){
        owners = _owners;
        timelocks = _timelocks;
        cub_token = _cub;
        masterChef = _master;
    }
    
    function forward() public {
        require(msg.sender == owners[0] || msg.sender == owners[1], 'Only owners can call this');
        uint256 balance = ERC20(cub_token).balanceOf(address(this));
        
        // Burn 90%
        ERC20(cub_token).transfer(dead, balance.mul(burnPercentage).div(1000));
        
        // Send 10% to dev timelocks
        ERC20(cub_token).transfer(timelocks[0], balance.mul(50).div(1000));
        ERC20(cub_token).transfer(timelocks[1], balance.mul(50).div(1000));
        
        emit Claim(balance, timelocks);
    }
    
    bool public isMigrationApproved_0;
    bool public isMigrationApproved_1;
    
    address public migrationAddress_0;
    address public migrationAddress_1;

    function approve(address _newDev) public {
        require(msg.sender == owners[0] || msg.sender == owners[1], 'Only owners can call this');
        if (msg.sender == owners[0]){
            isMigrationApproved_0 = true;
            migrationAddress_0 = _newDev;
        } else {
            isMigrationApproved_1 = true;
            migrationAddress_1 = _newDev;
        }
    }
    
    // Transfer dev address to new address
    function migrate() public {
        require(msg.sender == owners[0] || msg.sender == owners[1], 'Only owners can call this');
        require(isMigrationApproved_0, "Owner 0 did not approve yet");
        require(isMigrationApproved_1, "Owner 1 did not approve yet");
        require(migrationAddress_0 == migrationAddress_1, 'Migration address not matching');
        MasterChef(masterChef).dev(migrationAddress_0);
    }
}

interface MasterChef {
    function dev(address _devaddr) external; 
}

interface ERC20 {
    function totalSupply() external;
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
    function allowance(address _owner, address _spender) external;
    function decimals() external;
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
