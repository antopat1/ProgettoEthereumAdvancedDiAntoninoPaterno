// Descrizione: Test della funzionalità VRF e del processo di minting degli NFT
// Verifica che il processo di minting degli NFT funzioni correttamente, inclusa la generazione di numeri casuali tramite VRF.

import { expect } from "chai";
import hre from "hardhat";
import { parseEther } from "viem";
import { deployMockVRFAndContracts } from "../scripts/deployWithMock";

describe("VRF Functionality Tests", function () {
  let mockVRF: any;
  let registry: any;
  let nft: any;
  let owner: any;
  let publicClient: any;
  let subscriptionId: bigint;
  let contentId: bigint;

  before(async function () {
    [owner] = await hre.viem.getWalletClients();
    publicClient = await hre.viem.getPublicClient();

    const deployment = await deployMockVRFAndContracts();
    mockVRF = deployment.vrfMock;
    registry = deployment.registry;
    nft = deployment.nft;
    subscriptionId = deployment.subscriptionId;

    // Register a content for testing
    const title = "Test Content";
    const description = "Test Description";
    const maxCopies = 10;

    const tx = await registry.write.registerContent(
      [title, description, BigInt(maxCopies)],
      { account: owner.account }
    );
    await publicClient.waitForTransactionReceipt({ hash: tx });

    contentId = 1n;
  });

  it("Should verify content registration", async function () {
    const content = await registry.read.getContent([contentId]);
    expect(content.title).to.equal("Test Content");
    expect(content.description).to.equal("Test Description");
    expect(content.maxCopies).to.equal(10n);
  });

  it("Should verify NFT contract can access registered content", async function () {
    const content = await registry.read.getContent([contentId]);
    expect(content.title).to.equal("Test Content");

    const nftContent = await nft.read.contentRegistry();
    expect(nftContent.toLowerCase()).to.equal(registry.address.toLowerCase());

    const contentFromNFT = await registry.read.getContent([contentId], {
      from: nft.address,
    });
    expect(contentFromNFT.title).to.equal("Test Content");
  });

  it("Should verify content is available for minting", async function () {
    const content = await registry.read.getContent([contentId]);
    expect(content.isAvailable).to.be.true;
  });

  it("Should verify NFT contract is set in registry", async function () {
    const nftContractAddress = await registry.read.nftContract();
    expect(nftContractAddress.toLowerCase()).to.equal(
      nft.address.toLowerCase()
    );
  });

  it("Should verify content existence before minting", async function () {
    const invalidContentId = 999n;
    const mintPrice = parseEther("0.05");

    await expect(
      nft.write.mintNFT([invalidContentId], {
        value: mintPrice,
        account: owner.account,
      })
    ).to.be.rejectedWith("Content does not exist");
  });

  it("Should complete the NFT minting process with VRF", async function () {
    const mintPrice = parseEther("0.05");

    const content = await registry.read.getContent([contentId]);
    expect(content.title).to.equal("Test Content");
    expect(content.isAvailable).to.be.true;
    expect(content.mintedCopies).to.equal(0n);

    const mintTx = await nft.write.mintNFT([contentId], {
      value: mintPrice,
      account: owner.account,
    });
    const mintReceipt = await publicClient.waitForTransactionReceipt({
      hash: mintTx,
    });
    expect(mintReceipt.status).to.equal("success");

    const randomWordsRequestedEvents =
      await mockVRF.getEvents.RandomWordsRequested();
    expect(randomWordsRequestedEvents).to.have.length.above(0);
    const requestId = randomWordsRequestedEvents[0].args.requestId;

    const fulfillTx = await mockVRF.write.fulfillRandomWords([requestId], {
      account: owner.account,
    });
    await publicClient.waitForTransactionReceipt({ hash: fulfillTx });

    const totalSupply = await nft.read.totalSupply();
    expect(totalSupply).to.equal(1n);

    const tokenId = 1n;
    const metadata = await nft.read.getNFTMetadata([tokenId]);
    expect(metadata.contentId).to.equal(contentId);
    expect(metadata.randomSeed).to.not.equal(0n);
    expect(metadata.copyNumber).to.equal(1n);

    const updatedContent = await registry.read.getContent([contentId]);
    expect(updatedContent.mintedCopies).to.equal(1n);

    const tokenOwner = await nft.read.ownerOf([tokenId]);
    expect(tokenOwner.toLowerCase()).to.equal(
      owner.account.address.toLowerCase()
    );
  });

  it("Should fail minting when content is not available", async function () {
    const mintPrice = parseEther("0.05");
    const invalidContentId = 999n;

    await expect(
      nft.write.mintNFT([invalidContentId], {
        value: mintPrice,
        account: owner.account,
      })
    ).to.be.rejected;
  });

  it("Should fail minting with insufficient payment", async function () {
    const invalidMintPrice = parseEther("0.01");

    await expect(
      nft.write.mintNFT([contentId], {
        value: invalidMintPrice,
        account: owner.account,
      })
    ).to.be.rejected;
  });
});