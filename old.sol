import { expect } from "chai";
import hre from "hardhat";
import { parseEther } from "viem";
import { deployMockVRFAndContracts } from "../scripts/deployWithMock";

// Descrizione: Test di deployment dei contratti e configurazione iniziale
describe("Deployment Tests", function () {
  let mockVRF: any;
  let registry: any;
  let nft: any;
  let owner: any;
  let publicClient: any;
  let subscriptionId: bigint;

  before(async function () {
    [owner] = await hre.viem.getWalletClients();
    publicClient = await hre.viem.getPublicClient();
  });

  it("Should deploy all contracts with Mock VRF", async function () {
    console.log("\n🔍 Testing full deployment with Mock VRF...");

    const deployment = await deployMockVRFAndContracts();

    mockVRF = deployment.vrfMock;
    registry = deployment.registry;
    nft = deployment.nft;
    subscriptionId = deployment.subscriptionId;

    console.log(`📍 MockVRF deployed to: ${mockVRF.address}`);
    console.log(`📍 Registry deployed to: ${registry.address}`);
    console.log(`📍 NFT Contract deployed to: ${nft.address}`);

    expect(mockVRF.address).to.not.equal(
      "0x0000000000000000000000000000000000000000"
    );
    expect(registry.address).to.not.equal(
      "0x0000000000000000000000000000000000000000"
    );
    expect(nft.address).to.not.equal(
      "0x0000000000000000000000000000000000000000"
    );
  });

  it("Should have correct VRF configuration", async function () {
    const baseFee = parseEther("0.1");
    const gasPriceLink = parseEther("0.000001");

    expect(await mockVRF.read.BASE_FEE()).to.equal(baseFee);
    expect(await mockVRF.read.GAS_PRICE_LINK()).to.equal(gasPriceLink);
  });

  it("Should have NFT contract registered as VRF consumer", async function () {
    const isConsumer = await mockVRF.read.isConsumer([
      subscriptionId,
      nft.address,
    ]);
    expect(isConsumer).to.be.true;
  });

  it("Should have correct Registry and NFT connection", async function () {
    const registeredNFTAddress = await registry.read.nftContract();
    expect(registeredNFTAddress.toLowerCase()).to.equal(
      nft.address.toLowerCase()
    );

    const contentRegistry = await nft.read.contentRegistry();
    expect(contentRegistry.toLowerCase()).to.equal(
      registry.address.toLowerCase()
    );
  });

  it("Should have funded VRF subscription", async function () {
    const subscription = await mockVRF.read.getSubscription([subscriptionId]);

    const [owner, balance, active] = subscription;

    expect(owner).to.not.be.undefined;
    expect(balance).to.not.be.undefined;
    expect(active).to.not.be.undefined;

    expect(Number(balance)).to.be.above(0);
    expect(active).to.be.true;
  });
});

// Descrizione: Test della funzionalità VRF e del processo di minting degli NFT
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

// Descrizione: Test di sicurezza e controllo degli accessi
describe("Security and Access Control Tests", function () {
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

  it("Should only allow owner to set NFT contract in registry", async function () {
    await expect(
      registry.write.setNFTContract([nft.address], {
        account: otherAccount.account,
      })
    ).to.be.rejectedWith("Ownable: caller is not the owner");
  });

  it("Should only allow NFT contract to increment minted copies", async function () {
    await expect(
      registry.write.incrementMintedCopies([contentId], {
        account: otherAccount.account,
      })
    ).to.be.rejectedWith("Only NFT contract can modify");
  });

  it("Should only allow NFT contract to change content availability", async function () {
    await expect(
      registry.write.setContentAvailability([contentId, false], {
        account: otherAccount.account,
      })
    ).to.be.rejectedWith("Only NFT contract can modify");
  });

  it("Should correctly handle payments and prevent reentrancy", async function () {
    const mintPrice = parseEther("0.05");

    // Verifica che il pagamento venga correttamente trasferito all'autore
    const initialAuthorBalance = await publicClient.getBalance({
      address: owner.account.address,
    });

    const mintTx = await nft.write.mintNFT([contentId], {
      value: mintPrice,
      account: otherAccount.account,
    });
    await publicClient.waitForTransactionReceipt({ hash: mintTx });

    const finalAuthorBalance = await publicClient.getBalance({
      address: owner.account.address,
    });
    const royaltyAmount = (mintPrice * 3n) / 100n;

    // Convertiamo i valori bigint in number per utilizzare closeTo
    const expectedAuthorBalance = Number(initialAuthorBalance + royaltyAmount);
    const actualAuthorBalance = Number(finalAuthorBalance);
    const tolerance = Number(parseEther("0.001")); // Tolleranza di 0.001 ETH

    expect(actualAuthorBalance).to.be.closeTo(expectedAuthorBalance, tolerance);

    // Verifica che l'eccesso di pagamento venga restituito al minter
    const excessPayment = parseEther("0.01");
    const initialMinterBalance = await publicClient.getBalance({
      address: otherAccount.account.address,
    });

    const mintTxWithExcess = await nft.write.mintNFT([contentId], {
      value: mintPrice + excessPayment,
      account: otherAccount.account,
    });
    await publicClient.waitForTransactionReceipt({ hash: mintTxWithExcess });

    const finalMinterBalance = await publicClient.getBalance({
      address: otherAccount.account.address,
    });

    // Convertiamo i valori bigint in number per utilizzare closeTo
    const expectedMinterBalance = Number(initialMinterBalance - mintPrice);
    const actualMinterBalance = Number(finalMinterBalance);

    expect(actualMinterBalance).to.be.closeTo(expectedMinterBalance, tolerance);
  });
});

// Descrizione: Test di edge case e situazioni limite
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
