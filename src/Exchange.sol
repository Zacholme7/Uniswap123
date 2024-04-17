pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange is ERC20 {
  // every exchange only allows swaps with only one token
  // connect exchange with token address
  address public tokenAddress;


  constructor(address _token) ERC20("Zuniswap-V1", "ZUNI-V1") {
    require(_token != address(0), "invalid token address");
    tokenAddress = _token;
  }

  // liquidity makes trades possible
  // need a way to add in liquidity
  function addLiquidity(uint256 _tokenAmount) public payable returns (uint256) {
    if(getReserve() == 0) {
        // case when the liquidty pool is empty so we can set an arbitrary ratio
        // cast the token address into a IERC20 interface instance
        IERC20 token = IERC20(tokenAddress);

        // transfer liqidity to this contract
        token.transferFrom(msg.sender, address(this), _tokenAmount);

        // upon first deposit, amt lp tokens = amt eth
        // get amount of eth in contract and mint that many tokens to sender
        uint256 liqudity = address(this).balance;
        _mint(msg.sender, liquidity);
        return liquidity;
    } else {
        // establish reserves proportion when there is some liquidity
        uint256 ethReserve = address(this).balance - msg.value;  // eth reserve we have,
        uint256 tokenReserve = getReserve(); // token reserve we have
        uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
        require(_tokenAmount >= tokenAmount, "insufficient token amount");

        // transfer from this sender to this contract
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), tokenAmount);

        // mit lp tokens proportionally to amount of ethers deposited
        uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
        _mint(msg.sender, liqudity);
        return liquidity;
    }
  }

  function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
    require(_amount > 0, "invalid amount");
    uint256 ethAmount = (adddress(this).balance *_amount) / totalSupply();
    uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

    _burn(msg.sender, _amount);
    payable(msg.sender).transfer(ethAmount);
    IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    return (ethAmount, tokenAmount);
  }

  // returns the token balance of an exchange (this contract)
  function getReserve() public view returns (uint256) {
    return IERC20(tokenAddress).balanceOf(address(this));
  }

  // get the output amount based on the swap
  function getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) private pure returns (uint256) {
    require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

    // floating point is not supported

    uint256 inputAmountWithFee = inputAmount * 99; // taking a 1% fee
    uint256 numerator = inputAmountWithFee * outputReserve;
    uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

    return numerator / denominator;
  }


  // get the token output amont when selling eth
  function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
    require(_ethSold > 0, "ethSold is too small");

    uint256 tokenReserve = getReserve();

    return getAmount(_ethSold, address(this).balance, tokenReserve);
  }

  // get the eth output amount when selling the token
  function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
    require(_tokenSold > 0, "tokenSold is too small");

    uint256 tokenReserve = getReserve();

    return getAmount(_tokenSold, tokenReserve, address(this).balance);
  }


  // swap eth to the token
  function ethToTokenSwap(uint256 _minTokens) public payable {
    uint256 tokenReserve = getReserve();
    uint256 tokensBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);

    require(tokensBought >= _minTokens, "insufficient output amount");
    IERC20(tokenAddress).transfer(msg.sender, tokensBought);
  }


  function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
    uint256 tokenReserve = getReserve();
    uint256 ethBought = getAmount(
      _tokensSold,
      tokenReserve,
      address(this).balance
    );

    require(ethBought >= _minEth, "insufficient output amount");

    IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
    payable(msg.sender).transfer(ethBought);
  }








}
