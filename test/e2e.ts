import { expect } from "chai";
import { BigNumber } from "ethers";
import { Client } from "@unique-nft/sdk";
import {
  createSdk,
  deploy,
  getAccounts,
  getCollectionContract,
  getNetworkConfig,
} from "./utils";
import { UniqueNFT } from "@unique-nft/solidity-interfaces";
import { Market } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const { collectionId, tokenId } = getNetworkConfig();

describe("e2e", function () {
  let sdk: Client = createSdk();
  let ownerAccount: SignerWithAddress;
  let otherAccount: SignerWithAddress;
  let uniqueNFT: UniqueNFT;
  let market: Market;

  it("prepare", async () => {
    const accounts = await getAccounts(sdk, collectionId, tokenId);
    ownerAccount = accounts.ownerAccount;
    otherAccount = accounts.otherAccount;

    uniqueNFT = await getCollectionContract(ownerAccount, collectionId);

    market = await deploy();
  });

  it("approve", async () => {
    await expect(uniqueNFT.approve(market.address, tokenId)).to.emit(
      uniqueNFT,
      "Approval"
    );
  });

  const tokenPrice = 12;
  it("put", async () => {
    await expect(
      market.connect(ownerAccount).put(collectionId, tokenId, tokenPrice, 1, {
        gasLimit: 10_000_000,
      })
    )
      .to.emit(market, "TokenIsUpForSale")
      .withArgs("1", [
        collectionId,
        tokenId,
        tokenPrice,
        1,
        ownerAccount.address,
      ]);
  });

  it("check approved", async () => {
    await expect(
      market.connect(ownerAccount).checkApproved(collectionId, tokenId, {
        gasLimit: 10_000_000,
      })
    )
      .to.emit(market, "TokenIsApproved")
      .withArgs("1", [
        collectionId,
        tokenId,
        tokenPrice,
        1,
        ownerAccount.address,
      ]);
  });

  let ownerBalanceBefore: BigNumber;
  let otherBalanceBefore: BigNumber;
  it("balances before", async () => {
    ownerBalanceBefore = await ownerAccount.getBalance();
    otherBalanceBefore = await otherAccount.getBalance();
  });

  it("check price", async () => {
    const order = await market.getOrder(collectionId, tokenId);

    await expect(order.collectionId).to.be.eq(collectionId);
    await expect(order.tokenId).to.be.eq(tokenId);
    await expect(order.price).to.be.eq(BigNumber.from(tokenPrice));
    await expect(order.amount).to.be.eq(1);
    await expect(order.seller).to.be.eq(ownerAccount.address);
  });

  let buyUsePrice: BigNumber;
  it("buy", async () => {
    const { effectiveGasPrice, cumulativeGasUsed, events } = await (
      await market.connect(otherAccount).buy(collectionId, tokenId, {
        value: tokenPrice + 10,
        gasLimit: 10_000_000,
      })
    ).wait();

    const event = events?.find((log) => log.event === "TokenIsPurchased");
    expect(event).to.deep.include({
      event: "TokenIsPurchased",
      args: [
        "1",
        [
          collectionId,
          tokenId,
          BigNumber.from(tokenPrice),
          1,
          ownerAccount.address,
        ],
      ],
    });

    buyUsePrice = effectiveGasPrice.mul(cumulativeGasUsed);
  });

  it("check balances", async function () {
    const ownerBalanceAfter = await ownerAccount.getBalance();
    expect(ownerBalanceAfter.sub(ownerBalanceBefore)).eq(
      BigNumber.from(tokenPrice)
    );

    const otherBalanceAfter = await otherAccount.getBalance();
    const newBalance = otherBalanceBefore
      .sub(buyUsePrice)
      .sub(BigNumber.from(tokenPrice));

    expect(otherBalanceAfter).eq(newBalance);
  });
});
