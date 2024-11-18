// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast, Not a "real" transaction
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        // After startBroadcast, Is a "real" transaction
        // Mock = serve per creare un fake price feed e fare i test in locale senza dover fare fork su un nodo di alchemy
        FundMe fundMe = new FundMe(ethUsdPriceFeed); // eth/USD price feed on sepolia network
        vm.stopBroadcast();
        return fundMe;
    }
}
