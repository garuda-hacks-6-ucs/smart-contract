# BlocTenderID : Beaches aren't gonna clean themselves. 🚀

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

### 📜 Smart Contract

```console
    git clone https://github.com/garuda-hacks-6-ucs/frontend.git
```