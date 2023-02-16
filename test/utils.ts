import { ethers } from "hardhat";
import { Address } from "@unique-nft/utils";
import { UniqueNFTFactory } from "@unique-nft/solidity-interfaces";
import { Sdk, Client } from "@unique-nft/sdk";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export function createSdk(sdkBaseUrl: string) {
  const sdk = new Sdk({
    baseUrl: sdkBaseUrl,
  });
  return sdk;
}

export async function deploy() {
  const Market = await ethers.getContractFactory("Market");
  const market = await Market.deploy();

  return market;
}

export async function getCollectionContract(owner: any, collectionId: number) {
  const collectionAddress = Address.collection.idToAddress(collectionId);
  const uniqueNFT = await UniqueNFTFactory(collectionAddress, owner);

  return uniqueNFT;
}

export async function getAccounts(
  sdk: Client,
  collectionId: number,
  tokenId: number
) {
  const [account1, account2] = await ethers.getSigners();

  const tokenOwner = await sdk.tokens.owner({
    collectionId,
    tokenId,
  });

  const isOwner1 =
    tokenOwner?.owner.toLowerCase() === account1.address.toLowerCase();

  const ownerAccount: SignerWithAddress = isOwner1 ? account1 : account2;

  const otherAccount: SignerWithAddress = isOwner1 ? account2 : account1;

  return { ownerAccount, otherAccount };
}
