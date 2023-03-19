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
            packageObjectId: '0xb3d40059ce34de8e077251b6bb98076dab663f79',
            module: 'collection',
            function: 'add_address_to_airdrop',
            typeArguments: [],
            arguments: [
                '0xf1f4ce0381429f55858f976fdadc2dc87b4cf8d0',
                '0x080e1de136b9392b28e9fff72a7940009b61d50d',
                ['0x33f6bdb87c2974c83a6becc9f08560f7bab98441','0xa4e034a5104cc4f61a7e3a4f83c09e7d7e65f484',
                    '0x2e4cd7dfc63a9211d03c24caaa03e0a2a40191dd', '0xc3d73e836ec22308975332081d1b64898645ed73',
                    '0xd8cfc8de766060f5a699510f57d03a413fc7d196', '0x184c59aeabfc7c5ee2a61682727aeb7d87f6cb87',
                    '0xea947cc9bda00b244154d74cc32528f4f3fcc05a']
            ],
            gasBudget: 100000,
        },
    });
    console.log(result);
}

main().catch(console.error);