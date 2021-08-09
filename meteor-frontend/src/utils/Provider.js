import TxnWrapper, { TXN_PARAMS_TYPE, SerizalWithType } from '@wormhole-stc/txn-wrapper';
import ChainMethod from 'config/ChainMethod';

import { CurrencyAmount, Star } from '@starcoin/starswap-sdk-core';
import BigNumber from 'bignumber.js';
import { providers, bcs, serde } from '@starcoin/starcoin';

const PROVIDER_URL_MAP = {
  1: 'https://main-seed.starcoin.org',
  251: 'https://barnard-seed.starcoin.org',
};

const getJsonRpcProvider = () =>
  new providers.JsonRpcProvider(PROVIDER_URL_MAP[window.starcoin.networkVersion]);

/**
 * All Token that I Have
 */
export const Account_Info = async (account) => {
  try {
    if (!window.starcoin) return;

    const resources = await getJsonRpcProvider().getBalances(account);
    return Promise.all(
      Object.keys(resources).map(async (resource) => {
        const [address, module, token] = resource.split('::');
        const amount = await CurrencyAmount.fromRawAmount(
          Star.onChain(parseInt(window.starcoin.networkVersion)),
          new BigNumber(resources[resource]),
        );
        return {
          tokenName: resource,
          name: token,
          amount: amount.toSignificant(9),
        };
      }),
    );
  } catch (err) {
    console.log(err);
  }
};

import { v4 as uuidv4 } from 'uuid';
const getRandomNum = (n, total) => {
  var res = []; //最后返回的数组
  var range = total; //生成随机金额的范围
  var preTotal = 0; //已经生成的金额的和
  for (var i = 0; i < n - 1; i++) {
    var item = Math.ceil(Math.random() * (range / 2));
    res.push(item);
    range -= item; //从范围内减去已经生成的金额
    preTotal += item; //将已经生成的金额进行累加
  }
  res.push(total - preTotal); //最后将剩下的金额添加到数组中
  return res;
};

/**
 * Create a packet
 */
export const CreatePacket = async ({ quantity, token_amount, token_identifier }) => {
  const uuid = uuidv4();
  const leafs = getRandomNum(quantity, token_amount);
  return TxnWrapper({
    functionId: ChainMethod.CRAETE_PACKAGE,
    typeTag: token_identifier,
    params: [
      {
        value: uuid,
        type: TXN_PARAMS_TYPE['vector<u8>'],
      },
      {
        value: token_amount,
        type: TXN_PARAMS_TYPE.U128,
      },
      {
        value: leafs,
        type: TXN_PARAMS_TYPE['vector<u128>'],
      },
    ],
  }).then((res) => {
    return {
      uuid,
      txn: res,
    };
  });
};

import { hexlify } from '@ethersproject/bytes';
const checkTokenParams = (TOKEN) =>
  `0x00000000000000000000000000000001::Collection2::CollectionStore<0xb987F1aB0D7879b2aB421b98f96eFb44::RedPackage::RedPackage<${TOKEN}>>`;
const merkleRootGenerator = (uuid) => {
  const se = new bcs.BcsSerializer();
  se.serialize(serde.BinarySerializer.textEncoder.encode(uuid));
  return hexlify(se.getBytes());
};
/**
 * All packet pack by the account
 */
export const CheckPacket = async ({ account, uuid, token_identifier }) => {
  // 单独和链交互
  return getJsonRpcProvider()
    .send('state.get_resource', [
      account.toString(),
      checkTokenParams(token_identifier),
      { decode: true },
    ])
    .then((res) => {
      if (res) {
        const { json } = res;
        const [packetList] = json.items?.vec;
        return (
          packetList.filter((packet) => packet.merkle_root == merkleRootGenerator(uuid))[0] || {}
        );
      }
      return {};
    });
};

/**
 * Claim the pack
 */
export const ClaimPacket = async ({ owner_address, uuid, token_identifier }) => {
  return TxnWrapper({
    functionId: ChainMethod.CLAIM_PACKAGE,
    typeTag: token_identifier,
    params: [
      owner_address,
      {
        value: uuid,
        type: TXN_PARAMS_TYPE['vector<u8>'],
      },
    ],
  });
};

/**
 * Cancel the packets
 */
export const CancelPacket = async ({ token_identifier }) => {
  return TxnWrapper({
    functionId: ChainMethod.CANCEL_PACKAGE,
    typeTag: token_identifier,
    params: [],
  });
};

/**
 * Mint Shiba
 */
export const MintShiba = async () => {
  return TxnWrapper({
    functionId: ChainMethod.MINT_SHIBA,
    typeTag: '',
    params: [
      {
        value: new BigNumber(10000 * Math.pow(10, 9)),
        type: TXN_PARAMS_TYPE.U128,
      },
    ],
  });
};
