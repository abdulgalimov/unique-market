import { expect } from "chai";
import { Client } from "@unique-nft/sdk";
import { createSdk, deploy, getAccounts } from "./utils";
import { Market } from "../typechain-types";
import { ethers } from "hardhat";

const collectionId = 244;
const tokenId = 3;
const sdkBaseUrl = "http://localhost:3002/v1";

describe("Market", function () {
  let sdk: Client = createSdk(sdkBaseUrl);

  it("put fail; collection not found", async () => {
    const market = await deploy();

    await expect(market.put(1000000, 1, 3)).to.be.revertedWithCustomError(
      market,
      "CollectionNotFound"
    );
  });

  it("put fail; collection not supported 721", async () => {
    const market = await deploy();

    await expect(market.put(251, 1, 3)).to.be.revertedWithCustomError(
      market,
      "CollectionNotSupportedERC721"
    );
  });

  it("put fail; token not found", async () => {
    const market = await deploy();

    await expect(market.put(collectionId, 1000, 3)).to.be.revertedWith(
      "token not found"
    );
  });
  it("put fail; user not owner of token", async () => {
    const market = await deploy();

    await expect(market.put(collectionId, 2, 3)).to.be.revertedWithCustomError(
      market,
      "SenderNotOwner"
    );
  });

  it.skip("put fail; token is not approved", async () => {
    const { ownerAccount } = await getAccounts(sdk, collectionId, tokenId);
    const market = await deploy();

    await expect(
      market.connect(ownerAccount).put(collectionId, tokenId, 3, {
        gasLimit: 10_000_000,
      })
    ).to.be.revertedWithCustomError(market, "TokenIsNotApproved");
  });

  it.only("buy fail; token is not approved", async () => {
    const { ownerAccount, otherAccount } = await getAccounts(
      sdk,
      collectionId,
      tokenId
    );
    const market = await deploy();

    await (
      await market.connect(ownerAccount).put(collectionId, tokenId, 10, {
        gasLimit: 10_000_000,
      })
    ).wait();

    await expect(
      market.connect(otherAccount).buy(collectionId, tokenId, {
        value: 10,
      })
    )
      .to.be.revertedWithCustomError(market, "FailTransformToken")
      .withArgs("ApprovedValueTooLow");
  });
});
