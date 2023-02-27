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
            module: 'nft',
            function: 'mint',
            typeArguments: [],
            arguments: [
                '0x53ee3e0aeb3918f1a950e5f7c0d20fa1c0acbef9',
                '0x0b752b205b2c80b7fc3c9e5d5edaf751cafcc0b6',
                '0x714e59349f22c8f639571a9651d92472545646ee',
            ],
            gasBudget: 10000,
        },
    });
    console.log(result);
}

main().catch(console.error);