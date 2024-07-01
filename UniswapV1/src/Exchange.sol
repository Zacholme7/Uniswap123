pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Defines the exchanging logic
// Each pair is deployed as an exchange contract which allows the exchange to/from one token
contract Exchange {
        // the token this exchange allows you to swap with
        address public tokenAddress;

        // set the token for the contract upon construction
        constructor(address _token) {
                require(_token != address(0), "invalid token address");
                tokenAddress = _token;
        }


        // Add liquidity into the contract 
        function addLiquidity(uint256 _tokenAmount) public payable {
                IERC20 token = IERC20(tokenAddress);
                // transfer token amount from the sender to this contract
                token.transferFrom(msg.sender, address(this), _tokenAmount);
        }

        // get the reserves of the token for this contract
        function getReserves() public view returns (uint256) {
                return IERC20(tokenAddress).balanceOf(address(this));
        }

        // Calculate the amount out based on the amount in and current reserves
        function getAmount(
                uint256 inputAmount,
                uint256 inputReserves,
                uint256 outputReserves
        ) private pure returns (uint256) {
                require(inputReserves > 0 && outputReserves > 0, "invalid reserves");
                return outputReserves - (inputReserves * outputReserves) / (inputReserves + inputAmount);
        }

        // get the amount of tokens out based on the amount of eth put in
        function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
                require(_ethSold > 0, "Cannot sell zero amount");
                // calculate the amount out
                return getAmount(_ethSold, address(this).balance, getReserves());
        }

        // get the amount of eth out based on the amount of tokens put in
        function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
                require(_tokenSold > 0, "Cannot sell zero amount");
                // calculate the amount out
                return getAmount(_tokenSold, getReserves(), address(this).balance);
        }

        // swap eth to token
        function swapEthToToken(uint256 _minTokens) public payable {
                uint256 tokensOut = getAmount(
                        msg.value,
                        address(this).balance - msg.value,
                        getReserves()
                );

                require(tokensOut > _minTokens, "insufficient tokens out");

                IERC20(tokenAddress).transfer(msg.sender, tokensOut);
        }
}