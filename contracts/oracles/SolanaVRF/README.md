# Solana VRF on Neon EVM

> [!CAUTION]
> The following contracts have not been audited yet and are here for educational purposes.

### On-chain VRF
The following smart contract is an interface to existing [VRF functionality](https://orao.network/solana-vrf) provided by Orao Network program on Solana. Smart contract methods:
* `requestRandomness` - this method is requested whenever a VRF value has to be generated
* `getRandomness` - this method is a getter and returns the VRF value once it's being fulfilled
* `randomnessAccountAddress` - this method is a getter and returns the account where the fulfilled VRF value will be stored

You can interact with this smart contract at [https://neon.blockscout.com/address/0x7007B99847E2634395b2c3244416bFD80495EF45#contract](https://neon.blockscout.com/address/0x7007B99847E2634395b2c3244416bFD80495EF45#contract).

### Off-chain subscription to fulfilled randomness
```
const { AnchorProvider } = require("@coral-xyz/anchor");
const { Orao } = require("@orao-network/solana-vrf");
const provider = AnchorProvider.env();
const vrf = new Orao(provider);

const seed = 'Buffer_OR_Uint8Array_SEED';
const randomness = await vrf.waitFulfilled(seed);
console.log(Buffer.from(randomness.randomness).readBigUInt64LE(), 'randomness');
```

### Private keys setup

Private keys used in tests must be stored in an encrypted keystore file (located at
`~/Library/Preferences/hardhat-nodejs/keystore.json` by default on macOS systems) before running tests. To do so, run the following
commands in the CLI. You will be asked to choose a password (which will be used to encrypt provided secrets) and to
enter the secret values to be encrypted.

```shell
npx hardhat keystore set PRIVATE_KEY_OWNER
```

### Environment variables

The keystore's password can be added to the `.env` file (as `KEYSTORE_PASSWORD`) which allows secrets to be decrypted
automatically when running tests. Otherwise, each running test have the CLI prompt a request to enter the keystore's
password manually.
