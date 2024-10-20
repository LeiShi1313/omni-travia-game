// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {TriviaHost} from "src/TriviaHost.sol";
import {Script} from "forge-std/Script.sol";

contract RegisterTriviaGuesser is Script {
    function run(address host, uint64 onChainID, address guesser)  public {
        vm.startBroadcast();
        TriviaHost(host).registerGuesser(onChainID, guesser);
        vm.stopBroadcast();
    }
}
