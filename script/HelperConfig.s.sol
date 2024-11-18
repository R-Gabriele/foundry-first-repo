// SPDX-License-Identifier: MIT

// L'HelperConfig ci permette di lavorare su una local chain e su una qualsiasi chain. diamo un valore fake ai price feed per fare i test in locale
// 1.Deploy Moks when we are on a local anvil chain
// 2. Keep track of contract address across different chains
// 3. Sepolia ETH / USD
// 4. Mainnet ETH / USD

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local chain, we want to deploy mocks
    // Otherwise, grab the existing address from live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // pure = non modifica lo stato del contratto
        // Needs a price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // pure = non modifica lo stato del contratto
        // Needs a price feed address
        NetworkConfig memory EthConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return EthConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            // serve per evitare di fare di nuovo il deploy, se il contratto è già deployato
            return activeNetworkConfig;
        }

        // 1. Deploy the moks = "Fake" contracts
        // 2. Return the mock address

        vm.startBroadcast(); // In questo modo possiamo fare il deploy dei contratti fake nella anvil chain. NB dobbiamo togliere pure perche modifichiamo lo stato del contratto
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        ); // 2000 USD
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
