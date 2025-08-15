# Community DAO Project

A decentralized community management system built on Ethereum using Solidity.

## Contracts

- CommunityDAO: [`0x11a99b229bac81a3a45a2566bc0c83ac3d89a30a`](https://sepolia.etherscan.io/address/0x11a99b229bac81a3a45a2566bc0c83ac3d89a30a)
- CreateCommunity: [`0x801a82d5fc8050b283197bf3ca6654dab56e0e60`](https://sepolia.etherscan.io/address/0x801a82d5fc8050b283197bf3ca6654dab56e0e60)

## Setup

1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/morph_project.git
cd morph_project
```

2. Install dependencies
```bash
forge install
```

3. Create .env file
```bash
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=your_rpc_url
```

4. Deploy
```bash
forge script script/Deploy.s.sol:DeployContracts --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## License
MIT
```
