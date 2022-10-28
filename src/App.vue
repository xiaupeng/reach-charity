<template>
  <div id="app">

  <H1>REACH MORRA</H1>

    <H3>Choose Your Role:</H3>

    <button @click="alice()" >Alice</button> VS 
    <button @click="bob()" >Bob</button>
    <BR/>
  
  <HR/>

  <div v-if="role==0">
  <h3>Alice</h3>

    <button @click="createContract()" >Click to Deploy Contract</button><BR/>

    contract: (Copy below to Buyer and Transport)<BR/> 
    <h4>{{ ctcInfoStr }}</h4><BR /><BR />
  </div>

  <div v-else-if="role==1">
  <h3>Bob</h3>

  <input v-model="ctcStr" placeholder="paste contract here"> <button @click="attachContract()">Attach Contract</button>
  
    <BR/>  
    <div v-if="wager>0">
      Do you want to accept wager of {{wager}} ? 
      <button @click="yesnoWager(true)">YES</button>
      <button @click="yesnoWager(false)" >NO</button>
    </div>
    <BR/>     
  </div>

  <HR/>

    <div v-if="displayHandsState">
      <BR/>
      <h4>Last result are : </h4>
      <BR/>
      Alice hand: {{aliceHands}}
      Alice guess: {{aliceGuess}}
      <BR/>
      Bob hand: {{bobHands}}
      Bob guess: {{bobGuess}}
      <BR/>
  </div>

  <div v-if="getHandState">
      Play your hand : <BR/>
      <button @click="readHand(0)">ZERO</button>
      <button @click="readHand(1)">ONE</button>
      <button @click="readHand(2)">TWO</button> 
      <button @click="readHand(3)">THREE</button> 
      <button @click="readHand(4)">FOUR</button> 
      <button @click="readHand(5)">FIVE</button> 
      <BR/>
  </div>

  <div v-if="getGuessState">
      Shout your total : <BR/>
      <button @click="readGuess(0)"> 0 </button>
      <button @click="readGuess(1)"> 1 </button>
      <button @click="readGuess(2)"> 2 </button> 
      <button @click="readGuess(3)"> 3 </button> 
      <button @click="readGuess(4)"> 4 </button> 
      <button @click="readGuess(5)"> 5 </button> 
      <button @click="readGuess(6)"> 6 </button> 
      <button @click="readGuess(7)"> 7 </button> 
      <button @click="readGuess(8)"> 8 </button> 
      <button @click="readGuess(9)"> 9 </button> 
      <button @click="readGuess(10)"> 10 </button> 
      <BR/>
    </div>   

  <div v-if="displayResultState">
      <H3>{{resultString}}</H3>
  </div>
  
  <BR/>

  <HR/>
  addr: {{ addr}} <BR/>
  bal: {{ bal }} <BR/>
  balAtomic: {{ balAtomic }}<BR/>

  <button @click="updateBalance()">updateBalance</button>

  </div>
</template>

<script>
import * as backend from '../build/index.main.mjs';
import { loadStdlib } from '@reach-sh/stdlib';
//const stdlib = loadStdlib(process.env);

// Here is to Run in cmdline with 
// REACH_CONNECTOR_MODE=ALGO-Live
// ../reach devnet
const stdlib = loadStdlib("ALGO");
stdlib.setProviderByName("TestNet")

console.log(`The consensus network is ${stdlib.connector}.`);

//const suStr = stdlib.standardUnit;
//console.log("Unit is ", suStr)
//const toAU = (su) => stdlib.parseCurrency(su);
const toSU = (au) => stdlib.formatCurrency(au, 4);

// Defined all interact methods as global for backend calls, 
// later convert them to Vue methods
// These object MUST match the contract object in index.rsh

// This MUST match object in index.rsh
let commonInteract = { };
let aliceInteract = { };
let bobInteract = { };

const OUTCOME = [ "NULL","Alice Wins", "Bob Wins" ];

// Setup secret seed here, loaded in .env.local
const secret = process.env.VUE_APP_SECRET1
const secret2 = process.env.VUE_APP_SECRET2

export default {
  name: 'App',
  components: {
  },
  data: () => {
    return {
      role: 0,
      acc: undefined,
      addr: undefined,
      balAtomic: undefined,
      bal: undefined,
      faucetLoading: false,
      ctc: undefined,
      ctcInfoStr: undefined,
      ctcStr: undefined,

      contractCreated: false,
      displayResultState: false,
      displayHandsState: false,
      getGuessState: false,
      getHandState: false,

      wager: undefined,
      hand: undefined,
      guess: undefined,
      aliceHands:undefined,
      aliceGuess:undefined,
      bobHands:undefined,
      bobGuess:undefined,
      resultString: undefined,
      acceptWager: undefined,
    };
  },
   methods: {

      // Create a Vue methods for every commonInteract methods
      commonFunctions() {

        commonInteract = {
            ...stdlib.hasRandom,
            reportResult: async (result) => { this.reportResult(result); },
            reportHands: (alice, aliceGuess, bob, bobGuess) => { this.reportHands(alice, aliceGuess, bob, bobGuess)},
            informTimeout: () => { this.informTimeout()},
            getHand: async () => {
                  console.log("*** getHand called from backend");
                  // this will use v-if to display the input
                  this.getHandState = true
                  // waitUtil hand is not undefined
                  await this.waitUntil(() => this.hand !== undefined );
                  console.log("You played ", this.hand + " finger(s)");
                  const hand = stdlib.parseCurrency(this.hand);
                  this.hand = undefined;
                  this.getHandState = false
                  return hand;
                },
            getGuess: async () => {
                  console.log("*** getGuess called from backend");
                  // this will use v-if to display the input
                  this.getGuessState = true
                  // waitUtil hand is not undefined
                  await this.waitUntil(() => this.guess !== undefined );
                  console.log("You guess total of ", this.guess);
                  const guess = stdlib.parseCurrency(this.guess);
                  this.guess = undefined;
                  this.getGuessState = false
                  return guess;
                },
          }
      },

      async reportResult(result) {
        // Return is 0x01 - Batman or 0x02 - Bob
        // How to convert to number ??
        console.log('*** reportResult ', result);
        this.resultString = OUTCOME[result];
        console.log('this.result ', this.resultString);
        // change state to true and display to web
        this.displayResultState = true;
        await this.updateBalance();
      },

      reportHands(alice, aliceGuess, bob, bobGuess) {
        console.log('*** The hands are ' + alice, aliceGuess, bob, bobGuess );
        this.aliceHands = toSU(alice);
        this.aliceGuess = toSU(aliceGuess);
        this.bobHands = toSU(bob);
        this.bobGuess = toSU(bobGuess);

        // change state to true and display to web
        this.displayHandsState = true;
      },

      readHand(hand) {
        console.log("readHand: ", hand)
        this.hand = hand;
      },

      readGuess(guess) {
        console.log("readguess: ", guess)
        this.guess = guess;
      },

    async createContract() {
          // create the contract here
          // https://docs.reach.sh/frontend/#ref-frontends-js-ctc
          console.log("Creating contract...")
          this.ctc = await this.acc.contract(backend);

          // The object must match backend in index.rsh
          this.ctc.p.Alice(aliceInteract);

          // This will be ran after the contract is deployed
          // the JSON contract will be displayed so others can attach this contract
          const info = await this.ctc.getInfo();
          this.ctcInfoStr = JSON.stringify(info);
          console.log("this.ctcInfoStr: ", this.ctcInfoStr);

          this.contractCreated = true;
          await this.updateBalance();
    },

    async alice() {
      this.commonFunctions();
      aliceInteract = {
            ...commonInteract,
            wager: stdlib.parseCurrency(1),
            deadline: stdlib.parseCurrency(10),
        }

      console.log("Alice: ", aliceInteract);
      try {
          this.role = 0;
           // Change from devnet to testnet
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
          // Get secret keywords from .env.local
          this.acc = await stdlib.newAccountFromMnemonic(secret);

          this.addr = stdlib.formatAddress(this.acc.getAddress());

          this.balAtomic = await stdlib.balanceOf(this.acc);
          this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
            
      } catch (err) {
        console.log(err);
      }
    },
    
    //////////////////////////// Buyer

    async yesnoWager(res) {
        console.log("yesnoWager: ", res)
        this.acceptWager = res;
    },

   async attachContract() {
            this.ctc = await this.acc.contract(backend, JSON.parse(this.ctcStr));     
            console.log("Contract attached: ",this.ctcStr)
            await this.ctc.p.Bob(bobInteract);
            await this.updateBalance();
    },

    async bob() {
      this.commonFunctions();
      bobInteract = {
        ...commonInteract,
         //acceptWager: Fun([UInt], Null),
          acceptWager: async (wager) => {
          console.log("*** acceptWager", wager);

          this.wager =  toSU(wager),
          this.waitUntil( ()=> this.acceptWager == true)
          // Exit if false
          if ( this.acceptWager == false) {
              process.exit(0);
          }
        }
      }
      console.log("Bob: ", bobInteract);

      try {
        // Set role, create account
          this.role = 1;
          // Change from devnet to testnet
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
          // Get secret keywords from .env.local
          this.acc = await stdlib.newAccountFromMnemonic(secret2);

          this.addr = stdlib.formatAddress(this.acc.getAddress());

          this.balAtomic = await stdlib.balanceOf(this.acc);
          this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));

      } catch (err) {
        console.log(err);
      }
    },  
    
    // Common function for all Vue Rech
    waitUntil (condition) {
    return new Promise((resolve) => {
        let interval = setInterval(() => {
            if (!condition()) {
                return
            }

            clearInterval(interval)
            resolve()
        }, 100)
      })
    },

    // Call this after every action to get current balance
    async updateBalance() {
      try {
        this.balAtomic = await stdlib.balanceOf(this.acc);
        this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
      } catch (err) {
        console.log(err);
      }
    },
  },
  computed: {
  },
  mounted() {
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
#wizard {
  width: 1024px;
}
.content {
  width: 1024px;
}
.navigation-buttons {
  display: flex;
  justify-content: space-between;
}
</style>
