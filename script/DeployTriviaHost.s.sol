// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {TriviaHost} from "src/TriviaHost.sol";
import {Script} from "forge-std/Script.sol";

contract DeployTriviaHost is Script {
    function run(address owner, address portal) public {
        vm.startBroadcast();
        new TriviaHost(portal, owner);
        vm.stopBroadcast();
    }
}
