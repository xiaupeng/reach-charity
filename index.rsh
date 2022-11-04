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
  const Recipient2 = Participant('Recipient2', RecipientInteract);


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
      const Requesttoken1 = declassify(interact.requestDonation());
  })

  Recipient1.publish(Requesttoken1);
    commit();

  Owner.only(() => {
      const approvetoken1 = declassify(interact.approveDonation(Requesttoken1));
  })

  Owner.publish(approvetoken1)

  if (!approvetoken1 && Donationtoken1+Donationtoken2 < Requesttoken1 )  {
    commit()
  }else {
        transfer(Requesttoken1).to(Recipient1);
        commit();
        each([Owner, Donor1,Donor2,Recipient1], () => declassify(interact.reportPayment(Requesttoken1)));
   }
  

Recipient2.only(() => {
    const Requesttoken2 = declassify(interact.requestDonation());
})

Recipient2.publish(Requesttoken2);
  commit();

Owner.only(() => {
    const approvetoken2 = declassify(interact.approveDonation(Requesttoken2));
})

Owner.publish(approvetoken2)

if (!approvetoken2 && Donationtoken2+Donationtoken2 < Requesttoken2  )  {
  commit()
}else {
      transfer(Requesttoken2).to(Recipient2);
      commit();
      each([Owner, Donor1,Donor2,Recipient2], () => declassify(interact.reportPayment(Requesttoken2)));
 }








 

   exit();
});
