const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

var compare_dates = function(date1,date2){
     if (date1>date2) return 1;
   else if (date1<date2) return -1;
   else return 0; 
  }

var add_minutes =  function (dt, minutes) {
    return new Date(dt.getTime() + minutes*60000);
}

 // Create and Deploy Your First Cloud Functions
 // https://firebase.google.com/docs/functions/write-firebase-functions
  exports.deleteExpiredOffers = functions.region('europe-west1').https.onRequest(async (req, res) => {
    const db = admin.firestore();

    // get the offer collection of every users offers document
    const snapshot = await db.collectionGroup('offer').get();
    snapshot.forEach((doc) => {
      const timeNow = Date.now();
      const data = doc.data();
      var factor = 1;
      const timeFormat = data["timeFormat"]
      if (timeFormat === 'Std.') {
        factor = 60;
      }
      const expireDate = add_minutes(data["date"].toDate(), Number(data["duration"]) * factor);
      if (compare_dates(timeNow, expireDate) === 1) {
        console.log(data);
        const ref = doc.ref;
        doc.delete();
      }
    });
    res.sendStatus(200);
  })
