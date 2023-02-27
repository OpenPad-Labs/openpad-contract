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
            function: 'new_collection',
            typeArguments: [],
            arguments: [
                '0x75203afe0077667cd77bb291c7fbb1b703f60afe',
                '0x33f6bdb87c2974c83a6becc9f08560f7bab98441',
                'collection1',
                'solan1',
                'desc',
                "icon",
                "cover",
                "team",
                "roadmap",
                '1000',
                '20',
                'placeholder',
                true,
            ],
            gasBudget: 1000,
        },
    });
    console.log(result);
}

main().catch(console.error);
