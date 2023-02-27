const { JsonRpcProvider, devnetConnection, Ed25519Keypair, RawSigner, LocalTxnDataSerializer } = require("@mysten/sui.js");
const { mnemonic }  = require('./secrets.json');


const path = "m/44'/784'/0'/0'/0'";
const keypair = Ed25519Keypair.deriveKeypair(mnemonic, path);

console.log(keypair.getPublicKey().toSuiAddress());

const provider = new JsonRpcProvider(devnetConnection);

async function main() {
    //await provider.requestSuiFromFaucet(address);
    const signer = new RawSigner(
        keypair,
        provider
    );
    const result = await signer.signAndExecuteTransaction({
        kind: 'moveCall',
        data: {
            packageObjectId: '0xa901063762dcf953ff2a0d08767903436f3fb483',
            module: 'collection',
            function: 'add_address_to_whitelist',
            typeArguments: [],
            arguments: [
                '0x75203afe0077667cd77bb291c7fbb1b703f60afe',
                '0x714e59349f22c8f639571a9651d92472545646ee',
                ['0x33f6bdb87c2974c83a6becc9f08560f7bab98441','0xa4e034a5104cc4f61a7e3a4f83c09e7d7e65f484',
                '0x2e4cd7dfc63a9211d03c24caaa03e0a2a40191dd'],
                '10',
                '1000',
                '100',
            ],
            gasBudget: 100000,
        },
    });
    console.log(result);
}

main().catch(console.error);