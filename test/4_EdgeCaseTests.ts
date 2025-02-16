// Descrizione: Test di edge case e situazioni limite
// Verifica il comportamento del sistema in situazioni limite, come pagamenti insufficienti o superamento del numero massimo di copie.

import { expect } from "chai";
import hre from "hardhat";
import { parseEther } from "viem";
import { deployMockVRFAndContracts } from "../scripts/deployWithMock";

describe("Edge Case Tests", function () {
  let mockVRF: any;
  let registry: any;
  let nft: any;
  let owner: any;
  let otherAccount: any;
  let publicClient: any;
  let subscriptionId: bigint;
  let contentId: bigint;

  before(async function () {
    [owner, otherAccount] = await hre.viem.getWalletClients();
    publicClient = await hre.viem.getPublicClient();

    const deployment = await deployMockVRFAndContracts();
    mockVRF = deployment.vrfMock;
    registry = deployment.registry;
    nft = deployment.nft;
    subscriptionId = deployment.subscriptionId;

    // Registra un contenuto per i test
    const title = "Edge Case Test Content";
    const description = "Edge Case Test Description";
    const maxCopies = 2; // Numero limitato di copie per testare il limite

    const tx = await registry.write.registerContent(
      [title, description, BigInt(maxCopies)],
      { account: owner.account }
    );
    await publicClient.waitForTransactionReceipt({ hash: tx });

    contentId = 1n;
  });

  it("Should prevent minting with insufficient payment", async function () {
    const insufficientMintPrice = parseEther("0.04"); // Pagamento inferiore al richiesto

    await expect(
      nft.write.mintNFT([contentId], {
        value: insufficientMintPrice,
        account: owner.account,
      })
    ).to.be.rejectedWith("Insufficient payment");
  });
});