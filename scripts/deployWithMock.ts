import hre from "hardhat";
import { deployContractsFixture } from './deployContracts';
import { Address } from "viem";

async function deployMockVRFAndContracts() {
  console.log("\n🚀 Starting local deployment with Mock VRF...\n");

  const mockVRF = await hre.viem.deployContract("MockVRFCoordinatorV2");
  console.log(`📍 Mock VRF Coordinator deployed to: ${mockVRF.address}`);

  const deployment = await deployContractsFixture(true, true, mockVRF.address as Address);

  console.log("\n✅ Local deployment completed with Mock VRF");
  console.log("=".repeat(50));
  console.log(`📚 Registry Address: ${deployment.registry.address}`);
  console.log(`🎨 NFT Contract Address: ${deployment.nft.address}`);
  console.log(`🎲 Mock VRF Address: ${mockVRF.address}`);
  console.log("=".repeat(50) + "\n");

  return deployment;
}

async function main() {
  try {
    await deployMockVRFAndContracts();
  } catch (error) {
    console.error("\n❌ Deployment failed:", error);
    process.exitCode = 1;
  }
}

if (require.main === module) {
  main();
}

