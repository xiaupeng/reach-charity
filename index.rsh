'reach 0.1';



// Here to Setup common functions
const commonInteract = {
  ...hasRandom,
  reportDonation: Fun([UInt], Null),
  reportPayment: Fun([UInt], Null),

};

const OwnerInterect = {
  ...commonInteract,
  approveDonation: Fun([UInt], Bool),
}

const DonorInteract = {
  ...commonInteract,
  acceptDonation: Fun([], UInt),
}

const RecipientInteract = {
  ...commonInteract,
  requestDonation: Fun([], UInt),
}

export const main = Reach.App(() => {
  const Owner = Participant('Owner',OwnerInterect );
  const Donor1 = Participant('Donor1', DonorInteract);
  const Donor2 = Participant('Donor2', DonorInteract);
  const Recipient1 = Participant('Recipient1', RecipientInteract);

  init();


  Donor1.only(() => {
  const Donationtoken1 = declassify(interact.acceptDonation());
  });
  Donor1.publish(Donationtoken1);
  commit()

  Donor1.pay(Donationtoken1);
  each ([Owner,Donor1,Donor2], () => declassify(interact.reportDonation(Donationtoken1)));
  commit()

  Donor2.only(() => {
    const Donationtoken2 = declassify(interact.acceptDonation());
    });
    Donor2.publish(Donationtoken2);
    commit();

    Donor2.pay(Donationtoken2)
    each ([Owner,Donor1,Donor2], () => declassify(interact.reportDonation(Donationtoken2)));
    commit()

  Recipient1.only(() => {
      const Requesttoken = declassify(interact.requestDonation());
      });

  Recipient1.publish(Requesttoken);
    commit();

  Owner.only(() => {
      const approvetoken = declassify(interact.approveDonation(Requesttoken));
      }); 
      Owner.publish(approvetoken);
      if (approvetoken) {
        transfer(Requesttoken).to(Recipient1);
        
        commit();
      
        each([Owner, Donor1,Donor2,Recipient1], () => declassify(interact.reportPayment(Requesttoken)));
   }
  

  
});
