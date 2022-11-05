<template>
  <div id="app">

  <H1>Reach BUY SEND SELL</H1>

  current state: <b>{{state.value}}</b><BR/>
  <!--
  
    {{state}}<BR/><BR/>
  context: {{state.context}}<BR/>
  event: {{state.event}} <BR/>
  <HR></HR>


  <div v-show="state.matches('appInit')">
    <button @click="send('DEPLOY')">Deploy Contract</button>
  </div>

  <button @click="send('ONLY')">Only</button>
  <button @click="send('EACH')">Each</button>
  <button @click="send('COMMIT')">Commit</button>
  <button @click="send('PUBLISH')">Publish</button>
  <BR/><BR/>
  <button @click="increment">INC</button>
  <button @click="decrement">DEC</button> -->


    <H3>Choose your role:</H3>
    <b-button variant="success" @click="Owner()"> Donor2</b-button>
    <b-button variant="success" @click="Donor1()"> Donor2</b-button>
    <b-button variant="primary" @click="Donor2()"> Donor1</b-button>
    <b-button variant="warning" @click="Recipient1()">Recipient1</b-button>
    <b-button variant="warning" @click="Recipient2()">Recipient1</b-button>

    <BR/>
  
  <HR/>

  <div v-if="role==0">
  <h3>Owner</h3>

    Enter the selling price ? 
    <input v-model="approveDonation" placeholder="selling price">
    <button @click="getSellPrice()">Submit</button> <BR/>
    Enter the Recipient1 fees ? 
    <input v-model="tPrice" placeholder="Recipient1 fees">
    <button @click="getTPrice()">Submit</button><BR/>

    <div v-show="sellPriceOK">Submitted Selling price : {{ sellPrice}} <BR/></div>
    <div v-show="tPriceOK">Submitted Recipient1 fees : {{ tPrice}} <BR/></div>

  <BR/><BR/>
  <div v-show="state.matches('appInit')">
    <b-button variant="danger" @click="createContract()">Click to Deploy Contract</b-button><BR/>
  </div>

    contract: (Copy below to Donor1 and Recipient1)<BR/> 
    <h3>{{ ctcInfoStr }}</h3><BR /><BR />



    <!-- Enter the Recipient1 fees ? 
    <input @v-model="tPrice" placeholder="transpot fees"><button @click="getsellPrice()">Submit</button><BR/> -->



  </div>

  <div v-else-if="role==1">
  <h3>Donor1</h3>

  <input v-model="ctcStr" placeholder="paste contract here"> <button @click="attachContract1()">Attach Contract</button>
  
    <BR/><BR/>

    
    <div v-show="ctc && paymentDone==undefined">
    Do you want to purchase this for {{sellPrice}} ? 
    <button @click="yesnoPurchase(true)">YES</button>
    <button @click="yesnoPurchase(false)">NO</button>
    </div>

    <BR/><BR/>  
    <div v-show="pickupDone && deliveryMsg==undefined">
      Confirm order delivery ? 
      <button @click="yesnoDelivery(true)">YES</button>
      <button @click="yesnoDelivery(false)">NO</button>

  </div>

  </div>

  <div v-else-if="role==2">
  <h3>Donor2</h3>

  <input v-model="ctcStr" placeholder="paste contract here"> <button @click="attachContract1()">Attach Contract</button>
  
    <BR/><BR/>

    
    <div v-show="ctc && paymentDone==undefined">
    Do you want to purchase this for {{sellPrice}} ? 
    <button @click="yesnoPurchase(true)">YES</button>
    <button @click="yesnoPurchase(false)">NO</button>
    </div>

    <BR/><BR/>  
    <div v-show="pickupDone && deliveryMsg==undefined">
      Confirm order delivery ? 
      <button @click="yesnoDelivery(true)">YES</button>
      <button @click="yesnoDelivery(false)">NO</button>

  </div>

  </div>

<div v-else-if="role==3">
  <h3>Recipient1</h3>

    <input v-model="ctcStr" placeholder="paste contract here"> <button @click="attachContract2()">Attach Contract</button>
  
    <BR/> <BR/> 
    <div v-if="paymentDone && pickupMsg==undefined">
    Do you want to deliver this for {{tPrice}} ? 
    <button @click="yesnoRecipient1(true)">YES</button>
    <button @click="yesnoRecipient1(false)">NO</button>
    </div>
</div>

<div v-else-if="role==4">
  <h3>Recipient2</h3>

    <input v-model="ctcStr" placeholder="paste contract here"> <button @click="attachContract2()">Attach Contract</button>
  
    <BR/> <BR/> 
    <div v-if="paymentDone && pickupMsg==undefined">
    Do you want to deliver this for {{tPrice}} ? 
    <button @click="yesnoRecipient1(true)">YES</button>
    <button @click="yesnoRecipient1(false)">NO</button>
    </div>
</div>

  <BR/>
  <div v-show="paymentDone">
   {{ paymentMsg }}
   </div>

 <BR/>
  <div v-show="pickupDone">
   {{ pickupMsg }}
   </div>

 <BR/>
  <div v-show="deliveryDone">
   {{ deliveryMsg }}
   </div>
  <HR/>
  addr: {{ addr}} <BR/>
  bal: {{ bal }} <BR/>
  balAtomic: {{ balAtomic }}<BR/>


  <button @click="updateBalance()">updateBalance</button>

  </div>
</template>

<script>

// xstate stuff
//import { Machine, assign } from "xstate"

import { Machine, assign, interpret } from "xstate"
//import { interpret } from "xstate-vue2"

const increment = (context) => context.count + 1;
const decrement = (context) => context.count - 1;


import * as backend from '../build/index.main.mjs';
import { loadStdlib } from '@reach-sh/stdlib';
//const stdlib = loadStdlib(process.env);

// Run in cmdline with 
// REACH_CONNECTOR_MODE=ALGO-Live
// ../reach devnet

const stdlib = loadStdlib("ETH");

// Needed for ETH
const myGasLimit = 5000000;

// commet out to use Metamask
//stdlib.setProviderByName("TestNet")

stdlib.setWalletFallback(stdlib.walletFallback({}));

console.log(`The consensus network is ${stdlib.connector}.`);

const suStr = stdlib.standardUnit;
console.log("Unit is ", suStr)

// Defined all interact as global for backend calls, later convert them to Vue methods
let commonInteract = { };
let OwnerInteract = { };
let DonorInteract = { };
let RecipientInteract= { };


// Setup secret seed here, loaded in .env.local
const secret1 = process.env.VUE_APP_SECRET1
const secret2 = process.env.VUE_APP_SECRET2
const secret3 = process.env.VUE_APP_SECRET3
const secret4 = process.env.VUE_APP_SECRET4


// One is not used as we will access Metamask directly
//const privkey1 =  process.env.VUE_APP_PRIVKEY1
// const privkey2 =  process.env.VUE_APP_PRIVKEY2
// const privkey3 =  process.env.VUE_APP_PRIVKEY3

export default {
  name: 'App',
  created() {
      // Start service on component creation
      this.reachService
        .onTransition((state) => {
          // Update the current state component data property with the next state
          this.state = state;
          // Update the context component data property with the updated context
          this.context = state.context;
        })
        .start();
    },
  components: {
    //WizardSteps
  },
  data: () => {
    return {
      reachService: interpret(reachMachine),
      state: reachMachine.initialState,
      context: reachMachine.context,
      role: undefined,
      acc: undefined,
      addr: undefined,
      balAtomic: undefined,
      bal: undefined,
      ctc: undefined,
      ctcInfoStr: undefined,

    };
  },
   methods: {

      // xstate send in Vue format
      send(event) {
        this.reachService.send(event);
      },
      increment( ) {
          console.log("increment", this.context.count)
          this.context.count++
      },
      decrement() {
        console.log("decrement", this.context.count)
        this.context.count--
      },

      // Create a Vue methods for every OwnerInteract methods
      commonFunctions() {
        commonInteract = {
          reportDonation: () => { console.log(`The job was refused.`); },
          reportPayment: () => { console.log(`The job was refused.`); },
        }
      },

      reportDonation(orderreceivedTime, sellPrice, tPrice) {
        let rTime = new Date(parseInt(orderreceivedTime))
        this.send('EACH')
        this.deliveryDone = true;
        this.deliveryMsg = 'The order have been delivered, payment of ' 
        + stdlib.formatCurrency(sellPrice,6) + ' to Donor2 and payment of ' 
        + stdlib.formatCurrency(tPrice,6) + ' to Recipient1 at ' + rTime;

        console.log('The order have been delivered, payment of ' 
        + stdlib.formatCurrency(sellPrice,6) + ' to Donor2 and payment of ' 
        + stdlib.formatCurrency(tPrice,6) + ' to Recipient1 at ' + rTime)
        this.updateBalance();
      },


      reportPayment(payment, purchaseTime) {
        let pTime = new Date(parseInt(purchaseTime))

        this.send('EACH')
        this.paymentDone = true;
        this.paymentMsg = 'The Donor1 have made payment of ' + stdlib.formatCurrency(payment,6) + ' to the contract at ' + pTime;
        console.log('The Donor1 have made payment of ' + stdlib.formatCurrency(payment,6) + ' to the contract at ' + pTime);
      },

      async getSellPrice() {
        this.sellPriceOK = true;
      },

      async getTPrice() {
        this.tPriceOK = true;
      },

      async sellPriceYesNo(res) {
        console.log("getsellPrice: ", res)
        // Only return if YES
        if ( res === true) {
          this.getsellPrice = true;
        }
      },

      async createContract() {

            // Change state to deploy
            this.send('DEPLOY')

            // create the contract here
            // https://docs.reach.sh/frontend/#ref-frontends-js-ctc
            console.log("Creating contract...")

            this.ctc = await this.acc.contract(backend);
            this.ctc.p.Donor2(Donor2Interact);
            //console.log("Prices are: ", stdlib.parseCurrency(this.sellPrice), stdlib.parseCurrency(this.tPrice) )

            const info = await this.ctc.getInfo();
            console.log("getInfo(): ", info);
            this.ctcInfoStr = JSON.stringify(info, null,2);
            console.log("this.ctcInfoStr: ", this.ctcInfoStr);

            this.contractCreated = true;
            await this.updateBalance();

      },

    // 0 - Donor2, 1 - Donor1, 2 - Recipient1
    //////////////////////////// Donor2 methods
    async Owner() {
      this.OwnerFunctions();
      OwnerInteract = {
             ...commonInteract,
              acceptDonation: async () => {
                await this.waitUntil( () => this.sellPriceOK == true )
                console.log("sellPrice: ", this.sellPrice, stdlib.parseCurrency(this.sellPrice))
                return stdlib.parseCurrency(this.sellPrice)              
              }
              
      }

      try {
          // Set role, create account, 
          this.role = 0;
          // Change from devnet to testnet
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));

          // for ALGO use mnemonic secret
          // this.acc = await stdlib.newAccountFromMnemonic(secret);

          //this.acc = await stdlib.newAccountFromSecret(privkey1);
          this.acc = await stdlib.getDefaultAccount();
          this.acc.setGasLimit(myGasLimit);
          
          console.log("this.acc: ", this.acc)

          this.addr = stdlib.formatAddress(this.acc.getAddress());

          this.balAtomic = await stdlib.balanceOf(this.acc);
          this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
            
      } catch (err) {
        console.log(err);
      }
    },

    async Donor1() {
      this.DonorFunctions();
      DonorInteract = {
             ...commonInteract,
              acceptDonation: async () => {
                await this.waitUntil( () => this.donation1OK == true )
                console.log("donation1: ", this.donation1, stdlib.parseCurrency(this.donation1))
                return stdlib.parseCurrency(this.donation1)              
              }
              
      }

      try {
          // Set role, create account, 
          this.role = 0;
          // Change from devnet to testnet
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));

          // for ALGO use mnemonic secret
          this.acc = await stdlib.newAccountFromMnemonic(secret1);

          // this.acc = await stdlib.newAccountFromSecret(privkey1);
          // this.acc = await stdlib.getDefaultAccount();
          this.acc.setGasLimit(myGasLimit);
          
          console.log("this.acc: ", this.acc)

          this.addr = stdlib.formatAddress(this.acc.getAddress());

          this.balAtomic = await stdlib.balanceOf(this.acc);
          this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
            
      } catch (err) {
        console.log(err);
      }
    },

    async Donor2() {
      this.DonorFunctions();
      DonorInteract = {
             ...commonInteract,
              acceptDonation: async () => {
                await this.waitUntil( () => this.donation2OK == true )
                console.log("donation2: ", this.donation2, stdlib.parseCurrency(this.donation2))
                return stdlib.parseCurrency(this.donation2)              
              }
              
      }

      try {
          // Set role, create account, 
          this.role = 0;
          // Change from devnet to testnet
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));

          // for ALGO use mnemonic secret
          this.acc = await stdlib.newAccountFromMnemonic(secret2);

          // this.acc = await stdlib.newAccountFromSecret(privkey2);
          // this.acc = await stdlib.getDefaultAccount();
          this.acc.setGasLimit(myGasLimit);
          
          console.log("this.acc: ", this.acc)

          this.addr = stdlib.formatAddress(this.acc.getAddress());

          this.balAtomic = await stdlib.balanceOf(this.acc);
          this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
            
      } catch (err) {
        console.log(err);
      }
    },

    async Recipient1() {
      this.RecipientFunctions();
      RecipientInteract = {
             ...commonInteract,
              acceptDonation: async () => {
                await this.waitUntil( () => this.sellPriceOK == true )
                console.log("sellPrice: ", this.sellPrice, stdlib.parseCurrency(this.sellPrice))
                return stdlib.parseCurrency(this.sellPrice)              
              }
              
      }

      try {
          // Set role, create account, 
          this.role = 0;
          // Change from devnet to testnet
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));

          // for ALGO use mnemonic secret
          this.acc = await stdlib.newAccountFromMnemonic(secret3);

          // this.acc = await stdlib.newAccountFromSecret(privkey3);
          // this.acc = await stdlib.getDefaultAccount();
          this.acc.setGasLimit(myGasLimit);
          
          console.log("this.acc: ", this.acc)

          this.addr = stdlib.formatAddress(this.acc.getAddress());

          this.balAtomic = await stdlib.balanceOf(this.acc);
          this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
            
      } catch (err) {
        console.log(err);
      }
    },
    
    //////////////////////////// Donor1

    async attachContract1() {

        // change state to deployed/attached
        this.send('DEPLOY')

        // For ALGO
        //this.ctc = await this.acc.contract(backend, JSON.parse(this.ctcStr));     

        // On ETH, return value is not JSON, just contract addr
        this.ctc = await this.acc.contract(backend, this.ctcStr);     

        this.updateBalance();

        await this.ctc.p.Donor1(Donor1Interact);
        await this.updateBalance();

        console.log("Contract attached: ",this.ctcStr)
    },

    async yesnoPurchase(res) {
        console.log("yesnoPurchase: ", res)
        // Only return if YES
        if ( res === true) {
          this.purchaseResult = res;
        }
    },

    async getPurchaseResult() {
      // return ONLY if not undefined
      if ( this.purchaseResult !== undefined ) {
        this.send('PUBLISH')
        return this.purchaseResult
      }
    },

    async yesnoDelivery(res) {
        console.log("yesnoDelivery: ", res)
        if ( res === true) {
        this.deliveryResult = res;
        }
    },

    async getDeliveryResult() {
      // return ONLY if not undefined
      if ( this.deliveryResult !== undefined ) {
        this.send('PUBLISH')
        return this.deliveryResult
      }
    },



    async Recipient2() {
      this.RecipientFunctions();
      RecipientInteract = {
        ...commonInteract,
        confirmPurchase: async (sellPrice) => {
          this.sellPrice = stdlib.formatCurrency(sellPrice,6)
          console.log("*** from backend confirmPurchase: ", this.sellPrice);
            // change to localStep
            this.send('ONLY')
            console.log("purchaseResult: ", this.purchaseResult);
            await this.waitUntil( () => this.purchaseResult !== undefined )
            this.purchaseTime = Date.now();
            console.log("purchaseTime: ", this.purchaseTime)
            console.log("parseCurrency: ", stdlib.parseCurrency(this.purchaseTime))
            return stdlib.parseCurrency(this.purchaseTime)
          },
          ackDelivery: async () => {
            console.log("*** from backend ackDelivery");
            this.send('ONLY')
            // Add some delays after button is clicked
            //await new Promise(r =>setTimeout(r,5000)); 
            await this.waitUntil( () => this.deliveryResult !== undefined )
            // return the current 
            this.orderreceivedTime = Date.now();
            console.log("orderreceivedTime: ", this.orderreceivedTime)
            return stdlib.parseCurrency(this.orderreceivedTime)
          },

      }
      console.log("Donor1: ", Donor1Interact);

      try {
        // Set role, create account
          this.role = 1;
          // Change from devnet to testnet
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));

          // ALGO
          // addr : 6RONCOHZ4ZVKO5K6PVN6ERV5PBXDGHCUYFZJ5ITZAJMGTNHSGDASHEB3MA
          // this.acc = await stdlib.newAccountFromMnemonic(secret2);


          //this.acc = await stdlib.getDefaultAccount();

          // Connect to metamask
          //this.acc = await stdlib.getDefaultAccount();
          this.acc = await stdlib.newAccountFromSecret(privkey2);
          this.acc.setGasLimit(myGasLimit);
          
          this.addr = stdlib.formatAddress(this.acc.getAddress());
      } catch (err) {
        console.log(err);
      }
    },  
    

    async attachContract2() {

            // change state to deployed/attached
            this.send('DEPLOY')

            // receive the json string {"type":"BigNumber","hex":"0x3b"}
            // attach to the Donor2 contract above
            // https://docs.reach.sh/frontend/#ref-frontends-js-ctc

            // On ETH, return value is not JSON, just contract addr
            this.ctc = await this.acc.contract(backend, this.ctcStr);  

            //this.ctc = await this.acc.contract(backend, JSON.parse(this.ctcStr));     

            console.log("Contract attached: ",this.ctcStr)
            console.log("ctc: ",this.ctc)
            this.updateBalance();
            await this.ctc.p.Recipient1(Recipient1Interact);
            await this.updateBalance();
    },

    async yesnoRecipient1(res) {
        console.log("yesnoRecipient1: ", res)
        if ( res === true) {
        this.Recipient1Result = res;
        }
    },

    async getRecipient1Result() {
      // return ONLY if not undefined
      if ( this.Recipient1Result !== undefined ) {
        this.send('PUBLISH')
        return this.Recipient1Result
      }
    },

    // Recipient1
    async Recipient1() {
      this.OwnerFunctions();      
      Recipient1Interact = {
           ...OwnerInteract,
          confirmDelivery: async (tPrice) => {
            this.tPrice = stdlib.formatCurrency(tPrice,6)
            console.log("*** from backend confirmDeliver", this.tPrice);
            // change to localStep
            this.send('ONLY')
            console.log("Recipient1Result: ", this.Recipient1Result);
            await this.waitUntil(() => this.Recipient1Result !== undefined)
            this.acceptdeliveyTime = Date.now();
            console.log("acceptdeliveyTime: ", this.acceptdeliveyTime)
            return await stdlib.parseCurrency(this.acceptdeliveyTime)
          }
        }
        console.log("Recipient1: ",Recipient1Interact);

      try {
          this.role = 2;
          
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
          
          // ALGO
          // acct : RVEIRICPDUBBZQAIXSBECCDTB4BULPGGUQXRXCFLOXVRQIJ3HHRXGVY4WY
          // this.acc = await stdlib.newAccountFromMnemonic(secret3);

          //this.acc = await stdlib.getDefaultAccount();
          this.acc = await stdlib.newAccountFromSecret(privkey3);
          this.acc.setGasLimit(myGasLimit);

          this.addr = stdlib.formatAddress(this.acc.getAddress());
      } catch (err) {
        console.log(err);
      }
    },

    ///////////////////////////
    // Owner helper functions
    ///////////////////////////

    async updateBalance() {
      try {
        this.balAtomic = await stdlib.balanceOf(this.acc);
        this.bal = String(stdlib.formatCurrency(this.balAtomic, 6));
      } catch (err) {
        console.log(err);
      }
    },

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

    ///////////////////////////
    // Owner helper functions
    ///////////////////////////

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