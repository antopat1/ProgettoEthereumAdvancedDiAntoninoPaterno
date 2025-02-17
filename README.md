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

### Installazione

1. Clona la repository:

   ```bash
   git clone https://github.com/antopat1/ProgettoEthereumAdvancedDiAntoninoPaterno.git
   cd ProgettoEthereumAdvancedDiAntoninoPaterno
   ```

 2. Installa le dipendenze:  

    ```bash
   npm install
   ```

   Nota: Questo comando installerà automaticamente tutte le dipendenze elencate nel file package.json, inclusi Hardhat, Viem, Chainlink e OpenZeppelin.
