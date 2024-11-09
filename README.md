# Stablecoin Creation Flow
Let's learn how to create our custom stablecoin.

# Some Theory
There are four types of stablecoins based on its collateralization
*  Fiat backed
*  Crypto backed
*  Commodity backed
*  Algorithmic

The logic behind the first three methods is simple: Each existing stablecoin should have a peg appropriate to its worth stored in a vault managed by the stablecoin provider.
So, the coin's owner should be able to exchange it with the pegged asset whenever he wants without any problems. In the case of **Algorithmic** one, it keeps stablecoin's value stable around the peg
by minting and burning coin supplies. The latest option is less desirable as it demands complex mechanisms and is not as safe as asset-backed ones. There can also be partially collateralized stablecoins or
hybrid stablecoins that are backed partly by fiat and partly by other coins for example. 

In this article we'll build USD pegged, USDT backed stablecoin named `A4USD` with circulation of `1,000,000`
```Attention: This will be an experimental non-audited stablecoin project deployed on Polygon Amoy testnet```



# Creating and Minting Mock USDT
As we create our coin in Amoy where there is no `USDT` and we don't have actual USDT first we need to create cusotm test Mock USDT. After deploying the [contract](https://github.com/puls369ar/stablecoin-creation-flow/blob/main/code/USDT.sol) we mint `1,000,000` USDT that will back our stabelcoins. We call it from creator's (our) wallet by calling `mint(ethers.parseEther("1000000"))` 

# Creating and Minting A4USD stablecoin
Now we create our actual [stablecoin](https://github.com/puls369ar/stablecoin-creation-flow/blob/main/code/A4USD.sol) and again mint it from creator's account, thus emulating the circulation of tokens in the network.

# Creating A4USDReserves and Adding USDT as Collateral
USDT tokens need the vault to be stored in. If the price unexpectedly drastically fluctuates the appropriate amount of tokens should be deposited or withdrawed to keep the price of stablecoin pegged to dollar. **A4USDReserves** [contract](https://github.com/puls369ar/stablecoin-creation-flow/blob/main/code/A4USDReserves.sol) has this ability, also it has functions to add tokens into the vault as collaterals. It can be used when creating hybrid stablecoins too, but we'll add just USDT. 
So first we add USDT as a collateral token by calling `addReserveVault(<USDT_ADDRESS>)` then to deposit tokens from our account into the vault we allow `A4USDReserves` to receive it from us, by calling `approve(<A4USDRESERVES_ADDRESS>,ethers.parseEther("1000000"))` and finally call  `deposit(0,ethers.parseEther("1000000"))` where 0 is vault id of `USDT`

# Creating and Deploying A4USDGovernance, Setting USDT as Collateral
A4USD [contract](https://github.com/puls369ar/stablecoin-creation-flow/blob/main/code/A4USDGovernance.sol) has functions `setReserveContract(<A4USDReserves_ADDRESS>)` and `addColateralToken(<USDT_ADDRESS>)` to set appropriate values. `fetchColPrice()` is the function that gets price of USDT from  custom chainlink node configured specifically for our goal. I have a guide of how to create this node [here](https://github.com/puls369ar/chainlink-node-creation-flow). And finally `validatePeg()` function will implement 
