# BlocTenderID : Where businesses are chosen transparently based on merit, not connections. 🚀

BlocTenderID is a Blockchain and AI-powered digital tender platform designed to create a transparent, fair, and nepotism-free government procurement process. It empowers citizens to participate in selecting the most suitable vendors through decentralized public voting, while smart contracts automate secure and timely payments.

## 🧩 Architecture

### 📜 Smart Contract

    ```
    ├── smart-contract/
    │   ├── lib/              # External dependencies or libraries (via forge install)
    │   ├── scripts/          # Deployment and automation scripts using Forge
    │   ├── src/              # Main smart contract source files
    │   │   └── lib/          # Contains reusable code like custom errors and event declarations
    │   ├── test/             # Smart contract test files (e.g., unit tests)
    │   ├── .env              # Environment variables (e.g., RPC URL, private key)
    │   ├── .gitignore        # Git ignore rules
    │   ├── .gitmodules       # Tracks git submodules (e.g., external contracts/libs)
    │   ├── Makefile          # Automation commands for building, testing, and deploying
    │   └── foundry.toml      # Foundry configuration file (e.g., compiler version, optimizer)
    ```

## How to Run

This project uses [Foundry](https://book.getfoundry.sh/) and a custom `Makefile` for a smoother development experience.  
Just run `make <task>` without remembering long commands!

---

### 📦 1. Install Foundry

If you haven’t installed Foundry yet:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 📁 2. Clone Repository

```bash
> git clone https://github.com/garuda-hacks-6-ucs/frontend.git
> cd smart contract
```

### 📚 3. Install Dependencies

```bash
> make install
```

### 🔨 4. Compile Contracts
```bash
> make build
```

### 🧪 5. Run Test
```bash
> make test
```

### 🚀 6. Deploy Contracts
```bash
> make deploy-verify
```

## 🔐 .env Configuration

Before running deploy or verification commands, make sure your `.env` file is properly set up in the root directory.

```env
# 🔑 Private key of your deployer wallet (NEVER share this)
PRIVATE_KEY=your_private_key_here

# 🌐 RPC URL of the target network
RPC_URL=https://sepolia.optimism.io

# 🔍 Etherscan or Blockscout API key
ETHERSCAN_API_KEY=your_etherscan_or_blockscout_api_key

# 🛡️ Set verifier type: "etherscan" or "blockscout"
VERIFIER=blockscout

# 🔗 Optional: custom verifier URL (needed for blockscout)
VERIFIER_URL=https://testnet-explorer.optimism.io/api/
