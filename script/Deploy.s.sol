// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {CommunityDAO} from "../src/communityDAO.sol";
import {CreateCommunity} from "../src/createCommunity.sol";
import {console} from "forge-std/console.sol";

contract DeployContracts is Script {
    function run() external {
        // Get deployer private key from env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy CommunityDAO (no constructor args)
        CommunityDAO dao = new CommunityDAO();
        console.log("CommunityDAO deployed at:", address(dao));

        // 2. Deploy CreateCommunity with DAO address
        CreateCommunity community = new CreateCommunity(address(dao));
        console.log("CreateCommunity deployed at:", address(community));

        vm.stopBroadcast();
    }
}
