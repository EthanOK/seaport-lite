import "dotenv/config";
import { Wallet } from "ethers";

export function requireSigner(): Wallet {
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    console.error("PRIVATE_KEY is required in .env or the environment.");
    process.exit(1);
  }
  return new Wallet(privateKey);
}

export function resolveOfferer(cliOfferer?: string): string {
  const signer = requireSigner();
  if (cliOfferer && cliOfferer.toLowerCase() !== signer.address.toLowerCase()) {
    console.error(
      `offerer mismatch: passed ${cliOfferer}, wallet is ${signer.address}`,
    );
    process.exit(1);
  }
  return signer.address;
}
