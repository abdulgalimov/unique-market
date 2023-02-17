// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@unique-nft/solidity-interfaces/contracts/CollectionHelpers.sol";
import "./utils.sol";

contract Market {
    using ERC165Checker for address;

    string version = "1";

    bytes4 private InterfaceId_ERC721 = 0x80ac58cd;
    bytes4 private InterfaceId_ERC165 = 0x5755c3f2;

    CollectionHelpers collectionHelpers =
        CollectionHelpers(0x6C4E9fE1AE37a41E93CEE429e8E1881aBdcbb54F);
    Utils utils = new Utils();

    struct Order {
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
    error OrderNotFound();
    error NotEnoughError();
    error FailTransformToken(string reason);

    event TokenIsUpForSale(string version, Order item);
    event TokenRevoke(string version, Order item);
    event TokenIsPurchased(string version, Order item);
    event Log(string message);

    mapping(uint32 => mapping(uint32 => Order)) orders;

    address selfAddress;
    address ownerAddress;
    bool marketPause;

    constructor() {
        ownerAddress = msg.sender;
        selfAddress = address(this);
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only owner can");
        _;
    }

    modifier onlyNonPause() {
        require(!marketPause, "Market on hold");
        _;
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

    function isApproved(IERC721 erc721, Order memory item) private {
        // todo not implementable in chain
        try erc721.getApproved(item.tokenId) returns (address approved) {
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

    // ################################################################
    // Set new contract owner                                         #
    // ################################################################

    function setOwner() public onlyOwner {
        ownerAddress = msg.sender;
    }

    function setPause(bool pause) public onlyOwner {
        marketPause = pause;
    }

    // ################################################################
    // Place a token for sale                                         #
    // ################################################################

    function put(
        uint32 collectionId,
        uint32 tokenId,
        uint256 price,
        uint32 amount
    ) public onlyNonPause {
        IERC721 erc721 = getErc721(collectionId);
        onlyTokenOwner(erc721, tokenId);

        Order memory order = Order(
            collectionId,
            tokenId,
            price,
            amount,
            payable(msg.sender)
        );

        isApproved(erc721, order);

        orders[collectionId][tokenId] = order;

        emit TokenIsUpForSale(version, order);
    }

    // ################################################################
    // Get order                                                      #
    // ################################################################

    function getOrder(
        uint32 collectionId,
        uint32 tokenId
    ) external view returns (Order memory) {
        if (orders[collectionId][tokenId].price == 0) {
            revert OrderNotFound();
        }

        return orders[collectionId][tokenId];
    }

    // ################################################################
    // Revoke the token from the sale                                 #
    // ################################################################

    function revoke(uint32 collectionId, uint32 tokenId) external {
        IERC721 erc721 = getErc721(collectionId);
        onlyTokenOwner(erc721, tokenId);

        if (orders[collectionId][tokenId].price == 0) {
            revert OrderNotFound();
        }

        Order memory order = orders[collectionId][tokenId];

        delete orders[collectionId][tokenId];

        emit TokenRevoke(version, order);
    }

    // ################################################################
    // Buy a token                                                    #
    // ################################################################

    function buy(
        uint32 collectionId,
        uint32 tokenId
    ) public payable onlyNonPause {
        Order memory order = orders[collectionId][tokenId];
        if (order.price == 0) {
            revert OrderNotFound();
        }

        if (order.price > msg.value) {
            revert NotEnoughError();
        }

        IERC721 erc721 = getErc721(order.collectionId);

        isApproved(erc721, order);

        delete orders[collectionId][tokenId];

        try
            erc721.transferFrom(order.seller, msg.sender, order.tokenId)
        {} catch Error(string memory reason) {
            revert FailTransformToken(reason);
        }

        order.seller.transfer(order.price);

        if (msg.value > order.price) {
            payable(msg.sender).transfer(msg.value - order.price);
        }

        emit TokenIsPurchased(version, order);
    }
}
