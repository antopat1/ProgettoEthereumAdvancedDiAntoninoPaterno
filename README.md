# Decentralized News & Articles (DnA)


Il progetto **Decentralized News & Articles (DnA)** è un sistema che integra NFT, randomicità verificabile (tramite Chainlink VRF) e un registro decentralizzato per gestire contenuti scientifici in modo trasparente e sicuro. Gli autori possono registrare i propri contenuti, specificando titolo, descrizione e numero massimo di copie disponibili. Ogni contenuto viene associato a un hash unico per garantirne l'autenticità. Gli utenti possono poi mintare NFT rappresentativi di questi contenuti, con metadati unici e una probabilità del 10% di ottenere un contenuto speciale.

---

## 🛠 Tecnologie e Framework

- **Smart Contract**: Sviluppati in Solidity, i contratti gestiscono la logica di registrazione, minting e distribuzione delle royalty.
- **Hardhat**: Ambiente di sviluppo e testing per SmartContract, che ha permesso di eseguire test completi e simulare scenari complessi.
- **Viem**: Libreria per interagire con la blockchain e testare le chiamate ai contratti, scelta per la sua efficienza e facilità d'uso nello sviluppo di script e test.
- **Chainlink VRF**: Utilizzato per generare numeri casuali verificabili, essenziali per il meccanismo dei contenuti speciali.
- **Mock VRF Coordinator**: Simulazione locale di Chainlink VRF per evitare dipendenze dalla rete.
- **Chai + Mocha**: Framework di test per Solidity.

---

## 🛠 Funzionalità chiave

- **Registro dei contenuti**: Gli autori registrano i contenuti nel `ScientificContentRegistry`, che ne memorizza i dettagli e garantisce l'autenticità tramite un hash unico.
- **Minting degli NFT**: Gli utenti pagano per mintare un NFT. Il sistema richiede un numero casuale tramite Chainlink VRF per generare metadati unici, inclusa la possibilità di contenuti speciali.
- **Royalty automatiche**: Il 3% del pagamento viene trasferito automaticamente all'autore come royalty, incentivando la creazione di contenuti di qualità.
- **Edizioni limitate**: Ogni contenuto ha un numero massimo di copie, rendendo gli NFT più preziosi e collezionabili.
- **Randomicità verificabile**: Chainlink VRF garantisce che la randomicità sia imparziale e verificabile, aggiungendo un elemento di sorpresa e valore.

---

## 🚀 Come iniziare

### Prerequisiti

1. **Node.js**: Assicurati di avere Node.js installato. Puoi scaricarlo da [qui](https://nodejs.org/).
2. **Git**: Clona la repository per iniziare.

```bash
   git clone https://github.com/antopat1/ProgettoEthereumAdvancedDiAntoninoPaterno.git
   cd ProgettoEthereumAdvancedDiAntoninoPaterno
   ```
   

### Installa le dipendenze:
```bash
npm install
```

   Nota: Questo comando installerà automaticamente tutte le dipendenze elencate nel file package.json, inclusi Hardhat, Viem, Chainlink e OpenZeppelin.


### Configura il file .env:
```bash
PRIVATE_KEY="<La tua chiave privata>"
CHAINLINK_VRF_COORDINATOR="<Indirizzo del coordinatore VRF>"
CHAINLINK_SUBSCRIPTION_ID="<ID della sottoscrizione Chainlink>"
CHAINLINK_KEY_HASH="<Key hash per Chainlink VRF>"
ARBITRUM_SEPOLIA_RPC_URL="https://sepolia-rollup.arbitrum.io/rpc"
LOCAL_PRIVATE_KEY="<Chiave privata per test locali>"
LOCAL_VRF_MOCK="<Indirizzo del mock VRF per test locali>"
```

   Nota: Per i test locali, puoi lasciare vuoti i campi relativi a Chainlink e utilizzare il mock VRF


### Compilazione dei contratti:
```bash
npx hardhat compile
```

### Comandi utili:

- **deploy in locale**
```bash
npx hardhat run scripts/deployWithMock.ts
```

- **deploy su Arbitrum Sepolia**
```bash
npx hardhat run scripts/deployContracts.ts --network arbitrumSepolia
```

- **Eseguire i test sviluppati**
```bash
npx hardhat test
```
## 🛠 Test sviluppati

- **DeploymentTests**: Verifica che i contratti vengano deployati correttamente e che le configurazioni iniziali siano impostate come previsto.

- **VRFFunctionalityTests**: Verifica che il processo di minting degli NFT funzioni correttamente, inclusa la generazione di numeri casuali tramite VRF.

- **SecurityAndAccessControlTests**: Verifica che solo gli utenti autorizzati possano eseguire determinate operazioni e che i pagamenti vengano gestiti correttamente.

- **EdgeCaseTests**: Verifica il comportamento del sistema in situazioni limite, come pagamenti insufficienti o superamento del numero massimo di copie.

- **RoyaltyTests & RegisterContentTests:**: Verifica che le royalty vengano correttamente calcolate e trasferite all'autore e che i contenuti siano registrati e accessibili.

- **MintingTests & RandomnessTests**: Verifica il processo di minting degli NFT e della generazione di numeri casuali tramite VRF.

- **SpecialContentTests & TokenTransferTest**: Verifica che il contenuto speciale venga assegnato con una probabilità del 10% e che il trasferimento NFT sia effettuabile

---
