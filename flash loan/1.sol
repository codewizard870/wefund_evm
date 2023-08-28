// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/IFlashLoanReceiver.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Math.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Address.sol";

contract FlashLoanExample is IFlashLoanReceiver {
   using SafeMath for uint256;
   using Address for address;
   address constant LENDING_POOL_ADDRESS =  0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
   ILendingPool lendingPool = ILendingPool(LENDING_POOL_ADDRESS);

   function flashLoan(address _reserve, uint256 _amount) public {
      address receiverAddress = address(this);
      // Call the `flashLoan` function of the lending pool
      // Pass the address of the current contract as the `receiverAddress` parameter
      // and pass the parameters for the flash loan
      // The function will call the `executeOperation` function of this contract
      lendingPool.flashLoan(receiverAddress, _reserve, _amount, "");
  }
  function executeOperation(
    address _reserve,
    uint256 _amount,
    uint256 _fee,
    bytes calldata _params
  ) external override {
      // Make sure that this contract has the funds to pay the flash loan + fee
      require(
         address(this).balance >= _amount.add(_fee),
         "Not enough funds to repay the flash loan!"
      );
      // Perform some operations with the borrowed funds here
      // ...
      // Pay back the flash loan + fee
      // Transfer the funds to the lending pool
      uint totalDebt = _amount.add(_fee);
      address payable lp = payable(LENDING_POOL_ADDRESS);
      lp.transfer(totalDebt);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/IFlashLoanReceiver.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Math.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Address.sol";
contract FlashLoanExample is IFlashLoanReceiver {
   using SafeMath for uint256;
   using Address for address;
   address constant LENDING_POOL_ADDRESS = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
   ILendingPool lendingPool = ILendingPool(LENDING_POOL_ADDRESS);
   uint256 borrowPrice;

   function flashLoan(address _reserve) public {
      address receiverAddress = address(this);
      uint256 _amount = 10000 ether; // Set the amount to 10,000 ETH
      // Call the `flashLoan` function of the lending pool
      // Pass the address of the current contract as the `receiverAddress` parameter
      // and pass the parameters for the flash loan
      // The function will call the `executeOperation` function of this contract
    lendingPool.flashLoan(receiverAddress, _reserve, _amount, "");
  }
  function executeOperation(
    address _reserve,
    uint256 _amount,
    uint256 _fee,
    bytes calldata _params
  ) external override {
      // Make sure that this contract has the funds to pay the flash loan + fee
      require(
         address(this).balance >= _amount.add(_fee),
         "Not enough funds to repay the flash loan!"
      );
      // Store the borrow price
      borrowPrice = _amount;
      // Perform some operations with the borrowed funds here
      // ...
      // Check if the price has increased by 1%
      uint256 sellPrice = _amount.mul(101).div(100);
         if (address(this).balance >= sellPrice) {
            // Trigger the sale
            // ...
         }
         // Pay back the flash loan + fee
         // Transfer the funds to the lending pool
         uint totalDebt = _amount.add(_fee);
         address payable lp = payable(LENDING_POOL_ADDRESS);
            lp.transfer(totalDebt);
      }
}
// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/IFlashLoanReceiver.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Math.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Address.sol";
contract FlashLoanExample is IFlashLoanReceiver {
   using SafeMath for uint256;
   using Address for address;
   address constant LENDING_POOL_ADDRESS = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
   ILendingPool lendingPool = ILendingPool(LENDING_POOL_ADDRESS);
   uint256 borrowPrice;
   function flashLoan(address _reserve) public {
      address receiverAddress = address(this);
      uint256 _amount = 10000 ether; // Set the amount to 10,000 ETH
         // Call the `flashLoan` function of the lending pool
         // Pass the address of the current contract as the `receiverAddress` parameter
         // and pass the parameters for the flash loan
         // The function will call the `executeOperation` function of this contract
         lendingPool.flashLoan(receiverAddress, _reserve, _amount, "");
   }
   function executeOperation(
      address _reserve,
      uint256 _amount,
      uint256 _fee,
      bytes calldata _params
   ) external override {
      // Make sure that this contract has the funds to pay the flash loan + fee
      require(address(this).balance >= _amount.add(_fee),
         "Not enough funds to repay the flash loan!"
      );
      // Store the borrow price
      borrowPrice = _amount;
      // Perform some operations with the borrowed funds here
      // ...
      // Check if the price has increased by 1%
      uint256 sellPrice = _amount.mul(101).div(100);
      if (address(this).balance >= sellPrice) {
         // Calculate the profit from the sale
         uint256 profit = address(this).balance.sub(borrowPrice);
         // Calculate the 1% of the profit
         uint256 fee = profit.mul(1).div(100);
         // Repay the flash loan + fee to the lending pool
         uint totalDebt = _amount.add(_fee);
         address payable lp = payable(LENDING_POOL_ADDRESS);
               lp.transfer(totalDebt.add(fee));
      } else {
         // If the price hasn't increased, just repay the flash loan + fee to the lending pool
         uint totalDebt = _amount.add(_fee);
         address payable lp = payable(LENDING_POOL_ADDRESS);
            lp.transfer(totalDebt);
      }
   }
}
// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/IFlashLoanReceiver.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Math.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Address.sol";
contract FlashLoanExample is IFlashLoanReceiver {
   using SafeMath for uint256;
   using Address for address;
   address constant LENDING_POOL_ADDRESS =
   0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
   ILendingPool lendingPool = ILendingPool(LENDING_POOL_ADDRESS);
   uint256 borrowPrice;

   function flashLoan(address _reserve) public {
      address receiverAddress = address(this);
      uint256 _amount = 10000 ether; // Set the amount to 10,000 ETH
      // Call the `flashLoan` function of the lending pool
      // Pass the address of the current contract as the `receiverAddress` parameter
      // and pass the parameters for the flash loan
      // The function will call the `executeOperation` function of this contract
      lendingPool.flashLoan(receiverAddress, _reserve, _amount, "");
   }
   function executeOperation(
      address _reserve,
      uint256 _amount,
      uint256 _fee,
      bytes calldata _params
   ) external override {
      // Make sure that this contract has the funds to pay the flash loan + fee
      require(
         address(this).balance >= _amount.add(_fee),
         "Not enough funds to repay the flash loan!"
      );
      // Store the borrow price
      borrowPrice = _amount;
      // Perform some operations with the borrowed funds here
      // ...
      // Check if the price has increased by 1%
      uint256 sellPrice = _amount.mul(101).div(100);
      
      if (address(this).balance >= sellPrice) {
         // Calculate the profit from the sale
         uint256 profit = address(this).balance.sub(borrowPrice);
         // Calculate the 1% of the profit
         uint256 fee = profit.mul(1).div(100);
         // Transfer the profit to the specified Metamask address
         address payable receiver = payable(0xC087038aaF2e4cf9C6F1E0a347B1c99e9F0B8626);
         receiver.transfer(profit.sub(fee));
         // Repay the flash loan + fee to the lending pool
         uint totalDebt = _amount.add(_fee);
         address payable lp = payable(LENDING_POOL_ADDRESS);
         lp.transfer(totalDebt.add(fee));
      } else {
         // If the price hasn't increased, just repay the flash loan + fee to the lending pool
         uint totalDebt = _amount.add(_fee);
         address payable lp = payable(LENDING_POOL_ADDRESS);
         lp.transfer(totalDebt);
      }
  }
}
// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/IFlashLoanReceiver.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Math.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Address.sol";
import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

contract FlashLoanExample is IFlashLoanReceiver {
   using SafeMath for uint256;
   using Address for address;
   address constant LENDING_POOL_ADDRESS = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
   ILendingPool lendingPool = ILendingPool(LENDING_POOL_ADDRESS);
   IUniswapV2Router02 uniswapRouter =
   IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
   uint256 borrowPrice;
   
   function flashLoan() public {
      address receiverAddress = address(this);
      uint256 _amount = 10000 ether; // Set the amount to 10,000 ETH
      address _reserve = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // Use the ETH reserve address
    // Call the `flashLoan` function of the lending pool
    // Pass the address of the current contract as the `receiverAddress` parameter
    // and pass the parameters for the flash loan
    // The function will call the `executeOperation` function of this contract
      lendingPool.flashLoan(receiverAddress, _reserve, _amount, "");
   }
   function executeOperation(
      address _reserve,
      uint256 _amount,
      uint256 _fee,
      bytes calldata _params
   ) external override {
      // Make sure that this contract has the funds to pay the flash loan + fee
      require(
         address(this).balance >= _amount.add(_fee),
         "Not enough funds to repay the flash loan!"
      );
      // Swap the borrowed ETH for USDT
      address[] memory path = new address[](2);
      path[0] = _reserve;
      path[1] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT address
      uniswapRouter.swapExactETHForTokens{ value: _amount } (0, path, address(this), block.timestamp + 300);
      // Store the borrow price
      borrowPrice = _amount;
      // Perform some operations with the borrowed funds here
      // ...
      // Check if the price of ETH/USDT has increased by 1%
      uint256 sellPrice = borrowPrice.mul(101).div(100);
         (uint256 amountOut,) = uniswapRouter.getAmountsOut(sellPrice, path);
         if