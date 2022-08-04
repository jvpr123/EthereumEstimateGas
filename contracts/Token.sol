// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Token is ERC20Pausable, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Property {_maxSupply}:
     *      Sets the maximum amount of tokens allowed for this contract.
     *      Owner is able to _mint() more tokens, but never beyond this property value.
     *      Owner is able to _burn() tokens, but never the total amount.
     */
    uint256 private _maxSupply;

    /**
     * @dev Property {_transactionFee}:
     *      Applied to all transactions, except for VIP addresses.
     *      Only owner has permission to update this property using the setAddressAsVip() function.
     *      Range 0-100 ensured by require statement on _setTransactionFee() internal function.
     */
    uint256 private _transactionFee;

    /**
     * @dev Property mapping {_vipClient}:
     *      Specifies if a given address is related to a regular or VIP client.
     *      Only owner has permission to update this property using
     *      setAddressAsVip() and unsetAddressAsVip() functions.
     */
    mapping(address => bool) private _vipClient;

    /**
     * @dev Event triggered when owner changes {_transactionFee} value:
     *      @param _changedBy -> address that set new {_transactionFee}
     *      @param _newFee -> new {_transactionFee} percentage value
     *      @param _oldFee -> old {_transactionFee} percentage value
     */
    event TransactionFeeChanged(
        address indexed _changedBy,
        uint256 indexed _newFee,
        uint256 _oldFee
    );

    /**
     * @dev Sets the values for:
     *      Contract {name_}.
     *      Contract {symbol_}.
     *      Tokens {initialSupply_} to be minted.
     *      Tokens {maxSupply_} possible to create.
     *      {transactionFee} to be applied over all transactions (pecentage - 10 for 10% fee).
     *
     *      All of these values are immutable, except the {transactionFee}, that may be
     *      adjusted by contract owner after deploy.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        uint256 maxSupply_,
        uint256 transactionFee_
    ) ERC20(name_, symbol_) {
        _maxSupply = maxSupply_;
        _mint(msg.sender, initialSupply_);
        _setTransactionFee(transactionFee_);
    }

    /**
     * @return if the given @param _address is a VIP address.
     *  Requirements:
     *      - @param _address cannot be address 0.
     */
    function isVipAddress(address _address) public view returns (bool) {
        return _isVipAddress(_address);
    }

    /**
     * @dev Allows caller to set @param _address as VIP address.
     *  Requirements:
     *      - @param _address cannot be address 0.
     *      - caller must be the contract owner.
     */
    function setAddressAsVip(address _address) public onlyOwner {
        _setAddressAsVip(_address);
    }

    /**
     * @dev Allows caller to remove @param _address from VIP mapping.
     *  Requirements:
     *      - @param _address cannot be address 0.
     *      - caller must be the contract owner.
     */
    function unsetAddressAsVip(address _address) public onlyOwner {
        _unsetAddressAsVip(_address);
    }

    /**
     * @return current {transactionFee}.
     */
    function transactionFee() public view returns (uint256) {
        return _transactionFee;
    }

    /**
     * @dev Allows caller to set a new {transactionFee}.
     *  Requirements:
     *      - @param _fee cannot be grater than 100.
     *      - caller must be the contract owner.
     */
    function setTransactionFee(uint256 _fee) public onlyOwner {
        _setTransactionFee(_fee);
    }

    /**
     * @dev Allows caller to pause all transactions.
     *  Requirements:
     *      - contract cannot be already paused.
     *      - the caller must be the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Allows caller to unpause all transactions.
     *  Requirements:
     *      - contract must be paused.
     *      - caller must be the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(
            amount.add(totalSupply()) <= maxSupply(),
            "LUBY-TOKEN: Minting the provided amount of tokens will exceed the maximum supply allowed."
        );
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        require(
            amount <= totalSupply(),
            "LUBY-TOKEN: It`s not possible to burn more than total supply of tokens."
        );
        _burn(account, amount);
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Allows caller to send tokens to another address.
     *  Checks if sender is a VIP address:
     *      - if true -> calls _vipTransfer() -> no {_transactionFee} applied;
     *      - if false -> calls _regularTransfer() -> applies {_transactionFee}
     *           and sends fee value to contract address(this) balance.
     *           Then, sends remanining value to receiver address(to).
     *  Requirements:
     *      - @param to cannot be address 0.
     *      - @param amount must be less than or equal sender balance.
     *
     *  @return true if transaction succeeds.
     */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address sender = _msgSender();

        if (_isVipAddress(sender)) {
            _vipTransfer(sender, to, amount);
            return true;
        }

        _regularTransfer(sender, to, amount);
        return true;
    }

    /**
     * @dev Allows caller to spend pre-authorized amount of tokens specified in 
     *  mapping allowance from another address.
     
     *  Sets caller as spender and discounts amont from allowance value.
     *  Checks if @param from is a VIP address:
     *      - if true -> calls _vipTransfer() -> no {_transactionFee} applied;
     *      - if false -> calls _regularTransfer() -> applies {_transactionFee}
     *           and sends fee value to contract address(this) balance. 
     *           Then, sends remanining value to receiver address(to).
     *  Requirements:
     *      - @param from cannot be address 0.
     *      - @param to cannot be address 0.
     *      - @param amount must be less than or equal amount specified in mapping allowance.
     *
     *  @return true if transaction succeeds.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);

        if (_isVipAddress(from)) {
            _vipTransfer(from, to, amount);
            return true;
        }

        _regularTransfer(from, to, amount);
        return true;
    }

    /**
     * @dev Allows owner to withdraw accumulated fee values in contract balance.
     *  Requirements:
     *      - Sender must be the owner.
     *      - Contract balance must be greater than 0.
     */
    function withdrawTotalValue() public onlyOwner {
        uint256 _contractBalance = balanceOf(address(this));
        address _ownerAddress = owner();

        require(_contractBalance > 0, "LUBY-TOKEN: Contract balance is 0.");
        _transfer(address(this), _ownerAddress, _contractBalance);
    }

    /**
     * @dev  -> INTERNAL FUNCTIONS <-
     */

    /**
     * @dev called internally by isVipAddress().
     */
    function _isVipAddress(address _address) internal view returns (bool) {
        require(_address != address(0), "LUBY-TOKEN: Cannot be 0 address.");
        return _vipClient[_address];
    }

    /**
     * @dev called internally by setAddressAsVip().
     */
    function _setAddressAsVip(address _address) internal {
        require(
            !_isVipAddress(_address),
            "LUBY-TOKEN: Address given is already in VIP list."
        );
        _vipClient[_address] = true;
    }

    /**
     * @dev called internally by unsetAddressAsVip().
     */
    function _unsetAddressAsVip(address _address) internal {
        require(
            _isVipAddress(_address),
            "LUBY-TOKEN: Address given is not included in VIP."
        );
        _vipClient[_address] = false;
    }

    /**
     * @dev Stores new {transactionFee} value. Called internally by setTransactionFee().
     *      Emits event TransactionFeeChanged.
     */
    function _setTransactionFee(uint256 _fee) internal {
        require(
            _fee <= 100,
            "LUBY-TOKEN: It is not possible to set a fee percentage above 100."
        );

        emit TransactionFeeChanged(_msgSender(), _fee, _transactionFee);
        _transactionFee = _fee;
    }

    /**
     * @dev Applies {transactionFee} to transaction amount.
     *      Called internally by function _regularTransfer() to calculate
     *      fee over transaction amount.
     */
    function _applyFee(uint256 _amount) internal view returns (uint256) {
        uint256 amountToCharge = _amount.div(100).mul(_transactionFee);
        return amountToCharge;
    }

    /**
     * @dev Called internally by function _tranfer() when @param _from address
     *  is not VIP. Will apply fee over transaction amount and tranfer values.
     */
    function _regularTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        uint256 feeToCharge = _applyFee(_amount);
        uint256 amountToTransfer = _amount.sub(feeToCharge);

        _transfer(_from, address(this), feeToCharge);
        _transfer(_from, _to, amountToTransfer);
    }

    /**
     * @dev Called internally by function _tranfer() to send total amount
     *  to @param _to address when @param _from is a VIP client.
     */
    function _vipTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        _transfer(_from, _to, _amount);
    }
}
