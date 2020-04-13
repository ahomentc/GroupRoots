const functions = require('firebase-functions'); // coud functions for firebase sdk to create cloud functions and setup triggers
const admin = require('firebase-admin'); // access to ifrebase realtime database
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });


// we will create a trigger that does this:
// when a groupPost is created:
//     for all users in that groupPost's group g groupFollowers:
//         go to that user in groupsFollowing and set the group g's lastPostedDate value to be the time since 1970

exports.updateGroupsLastPosted = functions.database.ref('/posts/{groupId}/{postId}').onCreate((snapshot, context) => {
	// get the ref for groupFollowers[groupId] to get the followers array
	const group_id = context.params.groupId;
	const followers_path = '/groupFollowers/' + group_id
	return snapshot.ref.root.child(followers_path).once('value', follower_snapshot => {
	// snapshot contains all the followers
		const promises = []
		follower_snapshot.forEach(function(follower) {
        		var uid = follower.key;
			let promise = snapshot.ref.root.child('/groupsFollowing/' + uid + '/' + group_id).set(Date.now());
			promises.push(promise);
    		});
		return Promise.all(promises);
  	}).catch(() => {return null});
});

/*
exports.makeUppercase = functions.database.ref('/messages/{pushId}/original').onCreate((snapshot, context) => {
      // Grab the current value of what was written to the Realtime Database.
      const original = snapshot.val();
      console.log('Uppercasing', context.params.pushId, original);
      const uppercase = original.toUpperCase();
      // You must return a Promise when performing asynchronous tasks inside a Functions such as
      // writing to the Firebase Realtime Database.
      // Setting an "uppercase" sibling in the Realtime Database returns a Promise.
      return snapshot.ref.parent.child('uppercase').set(uppercase);
});
*/
