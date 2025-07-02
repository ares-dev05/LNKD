// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockPancakeRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, "PancakeRouter: EXPIRED");
        require(path.length >= 2, "PancakeRouter: INVALID_PATH");
        
        // Mock swap - transfer tokens from path[0] to 'to' address
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        
        // Calculate mock output (simple 1:1 for testing)
        uint amountOut = amountIn;
        
        // Transfer output token to recipient
        if (path.length == 2) {
            IERC20(path[1]).transfer(to, amountOut);
        } else if (path.length == 3) {
            IERC20(path[2]).transfer(to, amountOut);
        }
        
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[path.length - 1] = amountOut;
        
        return amounts;
    }
    
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, "PancakeRouter: EXPIRED");
        require(path.length >= 2, "PancakeRouter: INVALID_PATH");
        
        // Mock swap - transfer tokens and send ETH
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        
        // Send mock ETH
        payable(to).transfer(amountIn);
        
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[path.length - 1] = amountIn;
        
        return amounts;
    }
    
    function getAmountsOut(uint amountIn, address[] calldata path) external pure returns (uint[] memory amounts) {
        require(path.length >= 2, "PancakeRouter: INVALID_PATH");
        
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[path.length - 1] = amountIn; // Mock 1:1 ratio
        
        return amounts;
    }
} 