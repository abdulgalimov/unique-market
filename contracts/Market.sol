// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@unique-nft/solidity-interfaces/contracts/CollectionHelpers.sol";
import "./utils.sol";

contract Market {
    using ERC165Checker for address;

    bytes4 private InterfaceId_ERC721 = 0x80ac58cd;
    bytes4 private InterfaceId_ERC165 = 0x5755c3f2;

    CollectionHelpers collectionHelpers =
        CollectionHelpers(0x6C4E9fE1AE37a41E93CEE429e8E1881aBdcbb54F);
    Utils utils = new Utils();

    struct Token {
        uint32 collectionId;
        uint32 tokenId;
        uint256 price;
        uint32 amount;
        address payable seller;
    }

    error SenderNotOwner();
    error TokenIsNotApproved();
    error CollectionNotFound();
    error CollectionNotSupportedERC721();
    error TokenNotFound();
    error NotEnoughError();
    error FailTransformToken(string reason);

    event TokenIsUpForSale(Token token);
    event TokenWithdrawnFromSale(Token token);
    event TokenIsPurchased(Token token);
    event Log(string message);

    mapping(uint32 => mapping(uint32 => Token)) tokens;
    address selfAddress;

    constructor() {
        selfAddress = address(this);
    }

    function getErc721(uint32 collectionId) private view returns (IERC721) {
        address collectionAddress = collectionHelpers.collectionAddress(
            collectionId
        );

        uint size;
        assembly {
            size := extcodesize(collectionAddress)
        }

        if (size == 0) {
            revert CollectionNotFound();
        }

        if (!collectionAddress.supportsInterface(InterfaceId_ERC721)) {
            revert CollectionNotSupportedERC721();
        }

        return IERC721(collectionAddress);
    }

    function onlyTokenOwner(IERC721 erc721, uint32 tokenId) private {
        address realOwner = erc721.ownerOf(tokenId);

        if (realOwner != msg.sender) {
            revert SenderNotOwner();
        }
    }

    function isApproved(IERC721 erc721, Token memory token) private {
        // todo not implementable in chain
        try erc721.getApproved(token.tokenId) returns (address approved) {
            emit Log(
                string.concat(
                    "getApproved approved: ",
                    utils.toString(approved)
                )
            );
            if (approved != selfAddress) {
                revert TokenIsNotApproved();
            }
        } catch Error(string memory reason) {
            emit Log(string.concat("getApproved error: ", reason));
        }
    }

    function putAmount(
        uint32 collectionId,
        uint32 tokenId,
        uint256 price,
        uint32 amount
    ) public {
        IERC721 erc721 = getErc721(collectionId);
        onlyTokenOwner(erc721, tokenId);

        Token memory token = Token(
            collectionId,
            tokenId,
            price,
            amount,
            payable(msg.sender)
        );

        isApproved(erc721, token);

        tokens[collectionId][tokenId] = token;

        emit TokenIsUpForSale(token);
    }

    function put(uint32 collectionId, uint32 tokenId, uint256 price) external {
        return putAmount(collectionId, tokenId, price, 1);
    }

    function getPrice(
        uint32 collectionId,
        uint32 tokenId
    ) external view returns (uint256) {
        if (tokens[collectionId][tokenId].price == 0) {
            revert TokenNotFound();
        }

        return tokens[collectionId][tokenId].price;
    }

    function revoke(uint32 collectionId, uint32 tokenId) external {
        IERC721 erc721 = getErc721(collectionId);
        onlyTokenOwner(erc721, tokenId);

        if (tokens[collectionId][tokenId].price == 0) {
            revert TokenNotFound();
        }

        Token memory token = tokens[collectionId][tokenId];

        delete tokens[collectionId][tokenId];

        emit TokenWithdrawnFromSale(token);
    }

    function buy(uint32 collectionId, uint32 tokenId) public payable {
        uint256 price = tokens[collectionId][tokenId].price;
        if (price == 0) {
            revert TokenNotFound();
        }

        if (price > msg.value) {
            revert NotEnoughError();
        }

        Token memory token = tokens[collectionId][tokenId];

        IERC721 erc721 = getErc721(token.collectionId);

        isApproved(erc721, token);

        delete tokens[collectionId][tokenId];

        try
            erc721.transferFrom(token.seller, msg.sender, token.tokenId)
        {} catch Error(string memory reason) {
            revert FailTransformToken(reason);
        }

        token.seller.transfer(price);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit TokenIsPurchased(token);
    }
}
