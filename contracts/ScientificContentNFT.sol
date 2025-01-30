// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "./ScientificContentRegistry.sol";

contract ScientificContentNFT is ERC721Enumerable, VRFConsumerBaseV2Plus {
    using Strings for uint256;

    IVRFCoordinatorV2Plus private immutable COORDINATOR;
    bytes32 private immutable keyHash;
    uint256 private immutable subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant CALLBACK_GAS_LIMIT = 300000;
    uint32 private constant NUM_WORDS = 1;

    ScientificContentRegistry public immutable contentRegistry;
    
    uint256 public constant MINT_PRICE = 0.05 ether;
    uint256 private constant AUTHOR_ROYALTY_PERCENTAGE = 3;
    
    struct NFTMetadata {
        uint256 contentId;
        address author;
        uint256 randomSeed;
        bool hasSpecialContent;
        uint256 copyNumber;
    }

    mapping(uint256 => NFTMetadata) private _nftMetadata;
    mapping(uint256 => uint256) private _randomRequests;
    mapping(uint256 => PendingMint) private _pendingMints;

    struct PendingMint {
        address minter;
        uint256 contentId;
    }

    event NFTMinted(
        uint256 indexed tokenId,
        uint256 indexed contentId,
        address indexed owner,
        bool isSpecial,
        uint256 copyNumber
    );
    event MintingFailed(address indexed minter, uint256 indexed contentId);

    constructor(
        address _contentRegistry,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId
    ) 
        ERC721("DnA Scientific Content", "DNASCI")
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        require(_contentRegistry != address(0), "Invalid registry address");
        require(_vrfCoordinator != address(0), "Invalid VRF coordinator");
        require(_keyHash != bytes32(0), "Invalid key hash");
        require(_subscriptionId != 0, "Invalid subscription ID");
        
        contentRegistry = ScientificContentRegistry(_contentRegistry);
        COORDINATOR = IVRFCoordinatorV2Plus(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }

    function mintNFT(uint256 contentId) external payable {
        require(msg.value >= MINT_PRICE, "Insufficient payment");
        
        ScientificContentRegistry.Content memory content = 
            contentRegistry.getContent(contentId);
        
        require(content.isAvailable, "Content not available");
        require(content.mintedCopies < content.maxCopies, "No copies available");

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: CALLBACK_GAS_LIMIT,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 requestId = COORDINATOR.requestRandomWords(request);
        _pendingMints[requestId] = PendingMint({
            minter: msg.sender,
            contentId: contentId
        });

        uint256 authorRoyalty = (msg.value * AUTHOR_ROYALTY_PERCENTAGE) / 100;
        payable(content.author).transfer(authorRoyalty);

        if (msg.value > MINT_PRICE) {
            payable(msg.sender).transfer(msg.value - MINT_PRICE);
        }
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        PendingMint memory mintData = _pendingMints[requestId];
        
        try this._processMint(
            mintData.minter,
            mintData.contentId,
            randomWords[0]
        ) {
            contentRegistry.incrementMintedCopies(mintData.contentId);
        } catch {
            emit MintingFailed(mintData.minter, mintData.contentId);
            payable(mintData.minter).transfer(MINT_PRICE);
            contentRegistry.setContentAvailability(mintData.contentId, true);
        }
        
        delete _pendingMints[requestId];
    }

    function _processMint(
        address minter,
        uint256 contentId,
        uint256 randomWord
    ) external {
        require(msg.sender == address(this), "Internal call only");
        
        uint256 newTokenId = totalSupply() + 1;
        _safeMint(minter, newTokenId);

        ScientificContentRegistry.Content memory content = 
            contentRegistry.getContent(contentId);

        bool hasSpecialContent = randomWord % 10 == 0;

        _nftMetadata[newTokenId] = NFTMetadata({
            contentId: contentId,
            author: content.author,
            randomSeed: randomWord,
            hasSpecialContent: hasSpecialContent,
            copyNumber: content.mintedCopies + 1
        });

        emit NFTMinted(
            newTokenId, 
            contentId, 
            minter, 
            hasSpecialContent, 
            content.mintedCopies + 1
        );
    }

    function getNFTMetadata(uint256 tokenId)
        external
        view
        returns (NFTMetadata memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return _nftMetadata[tokenId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}