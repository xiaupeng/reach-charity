import { loadStdlib, ask } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const suStr = stdlib.standardUnit; 

const toAU = (su) => stdlib.parseCurrency(su);
const toSU = (au) => stdlib.formatCurrency(au, 4);
const iBalance = toAU(1000);
const showBalance = async (acc) => console.log(`Your balance is ${toSU(await stdlib.balanceOf(acc))} ${suStr}.`);

const OUTCOME = ['NO_WINS', 'Agnes WINS', 'Benny WINS', 'DRAW', ];

const commonInteract = {
  ...stdlib.hasRandom,
  reportResult:  (result) => { console.log(`The result is: ${OUTCOME[result]}`)},

  reportHands:  (A,aGuess,B, bGuess) => { 
    console.log(`*** Agnes played hand: ${toSU(A)}, guess: ${toSU(aGuess)} `)
    console.log(`*** Benny played hand: ${toSU(B)}, guess: ${toSU(bGuess)} `)
    console.log(`*** Total fingers : ${toSU( parseInt(A)+parseInt(B) )}`)
  },
  informTimeout: () => {  console.log(`There was a timeout.`); 
                            process.exit(1);
                          },
  getHand: async () => {  
          const hand = await ask.ask( `How many fingers?`, stdlib.parseCurrency );
          return hand
                        },
  getGuess: async () => {
        const guess = await ask.ask( `Guess total fingers?`, stdlib.parseCurrency );
        return guess
  },

}


const isAgnes = await ask.ask(
  `Are you Agnes?`,
  ask.yesno
);
const who = isAgnes ? 'Agnes' : 'Benny';

console.log(`Starting MORRA as ${who}`);

let acc = null;

if (who === 'Agnes') {
  const amt = await ask.ask( `How much do you want to wager?`, stdlib.parseCurrency );

  const agnesInteract = {
  ...commonInteract,
  wager: amt,
  deadline:100,
  }

  const acc = await stdlib.newTestAccount(iBalance);
  await showBalance(acc);

  const ctc = acc.contract(backend);
  
  ctc.getInfo().then((info) => {
    console.log(`The contract is deployed as = ${JSON.stringify(info)}`); });

  await ctc.p.Agnes(agnesInteract);
  await showBalance(acc);
} else if ( who === 'Benny') {
  const bennyInteract = {
    ...commonInteract,
    acceptWager: async (amt) => {
      const accepted = await ask.ask( `Do you want to accept water of ${toSU(amt)} ?`, ask.yesno )
        if (!accepted) {
          process.exit(0);
        }
      }
  }

  const acc = await stdlib.newTestAccount(iBalance);
  const info = await ask.ask('Paste contract info:', (s) => JSON.parse(s));

  const ctc = acc.contract(backend, info);
  await showBalance(acc);

  await ctc.p.Benny(bennyInteract);
  await showBalance(acc);
} 

ask.done();
