// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {TriviaGuesser} from "src/TriviaGuesser.sol";
import {Script} from "forge-std/Script.sol";

contract DeployTriviaGuesser is Script {
    function run(address portal, address host, address token) public {
        vm.startBroadcast();
        new TriviaGuesser(portal, host, token);
        vm.stopBroadcast();
    }
}
