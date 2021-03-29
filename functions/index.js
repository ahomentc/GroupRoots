const functions = require('firebase-functions'); // coud functions for firebase sdk to create cloud functions and setup triggers
const admin = require('firebase-admin'); // access to ifrebase realtime database
const firebase = admin.initializeApp();

// --------- Start helper  ---------

var DispatchGroup = (function() {
    var nextId = 0

    function DispatchGroup() {
        var id = ++nextId
        var tokens = new Set()
        var onCompleted = null

        function checkCompleted() {
            if(!tokens.size) {
                if(onCompleted) {
                    onCompleted()
                }
            }
        }

        // the only requirement for this is that it's unique during the group's cycle
        function nextToken() {
            return Date.now() + Math.random()
        }

        this.enter = function () {
            let token = nextToken()
            tokens.add(token)
            return token
        }

        this.leave = function (token) {
            if(!token) throw new Error("'token' must be the value earlier returned by '.enter()'")
            tokens.delete(token)
            checkCompleted()
        }

        this.notify = function (whenCompleted) {
            if(!whenCompleted) throw new Error("'whenCompleted' must be defined")
            onCompleted = whenCompleted
            checkCompleted()
        }
    }

    return DispatchGroup;
})()

function shuffle(array) {
  var currentIndex = array.length, temporaryValue, randomIndex;

  // While there remain elements to shuffle...
  while (0 !== currentIndex) {

    // Pick a remaining element...
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex -= 1;

    // And swap it with the current element.
    temporaryValue = array[currentIndex];
    array[currentIndex] = array[randomIndex];
    array[randomIndex] = temporaryValue;
  }

  return array;
}

// ------- End helper ----------


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
        	var post_time = parseFloat(Date.now()/1000)
			let promise = snapshot.ref.root.child('/groupsFollowing/' + uid + '/' + group_id + '/lastPostedDate').set(post_time);
			promises.push(promise);
    		});
		if (promises.length === 0) {
			return null;
		}
		return Promise.all(promises);
  	}).catch(() => {return null});
});

exports.autoBecomeSubscriberOnGroupMembershipJoin = functions.database.ref('/groups/{groupId}/members/{uid}').onCreate((snapshot, context) => {
	const group_id = context.params.groupId;
	const new_member_id = context.params.uid;
	// if not already subscribed to group
	return snapshot.ref.root.child('/groupsFollowing/' + new_member_id + '/' + group_id).once('value', in_subscriber_snapshot => {
		return snapshot.ref.root.child('/groups/' + group_id + '/lastPostedDate').once('value', last_post_date => {
			var post_date = last_post_date.val();
			if(post_date === "0" || post_date === 0){
				post_date = 1;
			}
			// post_date = parseInt(parseInt(post_date.toString()).toString())
			post_date = parseFloat(post_date)
			let is_subscribed = (in_subscriber_snapshot.val() !== null);
			if (is_subscribed) {
				return snapshot.ref.root.child('/groupsFollowing/' + new_member_id + '/' + group_id + '/autoSubscribed').set("false"); // not auto subscriber if in group
			}
			else {
				var current_time = parseFloat(Date.now()/1000)
				const promises = [];
				let promise_followers = snapshot.ref.root.child('/groupFollowers/' + group_id + '/' + new_member_id).set(current_time);
				let promise_following = snapshot.ref.root.child('/groupsFollowing/' + new_member_id + '/' + group_id + '/lastPostedDate').set(post_date);
				let promise_following_auto = snapshot.ref.root.child('/groupsFollowing/' + new_member_id + '/' + group_id + '/autoSubscribed').set("false"); // not auto subscriber if in group
				let promise_remove = snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + new_member_id).remove();
				promises.push(promise_followers);
				promises.push(promise_following);
				promises.push(promise_following_auto);
				promises.push(promise_remove);
				return Promise.all(promises);
			}	
		});
	});
});

// when a user becomes a member of a group
// for all the followers of the new member:
// 		add them as a subscriber to the group with addToGroupFollowers, addToGroupsFollowing, removeFromFollowPending equivalent

// Map: Following user creates or joins a group
exports.autoSubscribeFollowers = functions.database.ref('/groups/{groupId}/members/{uid}').onCreate((snapshot, context) => {
	const group_id = context.params.groupId;
	const new_member_id = context.params.uid;
	return snapshot.ref.root.child('/followers/' + new_member_id).once('value', new_member_followers => {
		return snapshot.ref.root.child('/groups/' + group_id + '/lastPostedDate').once('value', last_post_date => {
			return snapshot.ref.root.child('/groups/' + group_id + '/private').once('value', private_snapshot => {
				var private_string = private_snapshot.val().toString();
				var is_private = false;
				if (private_string === "true"){
					is_private = true;
				}
				var post_date = last_post_date.val();
				if(post_date === "0" || post_date === 0){
					post_date = 1;
				}
				post_date = parseFloat(post_date.toString())
				const promises = [];
				var sync = new DispatchGroup();
				var token_0 = sync.enter();
				new_member_followers.forEach(function(member_follower) {
					var member_follower_id = member_follower.key;
					var token = sync.enter()

					snapshot.ref.root.child('/groupMembersCount/' + group_id).once('value', counter_value => {
						if (parseInt(counter_value.val()) < 20) {
							snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id).once('value', in_subscriber_snapshot => {
								let is_subscribed = (in_subscriber_snapshot.val() !== null);
								var current_time = parseFloat(Date.now()/1000)
								if (is_subscribed) {
									// if the user is already subscribed to the group, 
									// just add uid to membersFollowing of the group for new_member_follower_id				
									let promise = snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id + '/membersFollowing/' + new_member_id).set(current_time);
									promises.push(promise);
									sync.leave(token);
									// tested with 1 follower
								}
								else {
									if (is_private) {
										// add to groupFollowPending with autoSubscribed: true... what if they were already in groupFollowPending with autoSubscribed as false?
										// add new_member_id to membersFollowing for groupFollowPending of new_member_follower_id
			
										// var lower_sync = new DispatchGroup();
										// var lower_token = lower_sync.enter();
										// snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + member_follower_id).once('value', in_follow_pending_snapshot => {
										// 	let is_in_follow_pending = (in_follow_pending_snapshot.val() !== null);
										// 	if (is_in_follow_pending) {
										// 		// do nothing
										// 	}
										// 	else {
										// 		// add user to groupFollowPending with autoSubscribed: true
										// 		let promise = snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + member_follower_id + '/autoSubscribed').set(true);
										// 		promises.push(promise);
										// 	}
										// 	lower_sync.leave(lower_token);
										// });						

										// lower_sync.notify(function() {
		        //            	 				let promise = snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + member_follower_id + '/membersFollowing/' + new_member_id).set(current_time);
										// 	promises.push(promise);
										// 	sync.leave(token);
		        //         				})
		                				// tested with 1 follower

		                				sync.leave(token);
									}
									else {
										// add to followers/following and autoFollow (since group is public would have auto became subscribed if manually clicked subscribe button)
										// add new_member_id to membersFollowing for the group
										let promise_followers = snapshot.ref.root.child('/groupFollowers/' + group_id + '/' + member_follower_id).set(current_time);
										let promise_following = snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id + '/lastPostedDate').set(post_date);
										let promise_following_auto = snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id + '/autoSubscribed').set("true");
										let promise_membersFollowing = snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id + '/membersFollowing/' + new_member_id).set(current_time);
										promises.push(promise_followers);
										promises.push(promise_following);
										promises.push(promise_following_auto);
										promises.push(promise_membersFollowing);
										sync.leave(token);
										// tested with 1 follower
									}
								}	
							});
						}
						else {
							sync.leave(token);
						}
					}).catch(() => {return null});
				});
				sync.leave(token_0);
				sync.notify(function() {
					if (promises.length === 0) {
						return null;
					}
					return Promise.all(promises);
				})
			}).catch(() => {return null});
		}).catch(() => {return null});
	}).catch(() => {return null});
});



// exports.createSchoolToGroup = functions.database.ref('/groups/{groupId}/selectedSchool/{selectedSchool}}').onCreate((snapshot, context) => {
// 	const group_id = context.params.groupId;
// 	const selected_school = context.params.selectedSchool;
// 	var creation_time = parseFloat(Date.now()/1000)

// 	console.log("hi")

// 	// create school -> group_id
// 	return snapshot.ref.root.child('/schools/' + selected_school + '/groups/' + group_id).set(creation_time);
// });



// when follower_user unfollows following_user,
// remove follower_user from folliwng_user's membersFollowing under groupsFollowing
exports.removeFromMembersFollowingOnUnfollow = functions.database.ref('/followers/{following_user}/{follower_user}').onDelete((snapshot, context) => {
	const following_user = context.params.following_user;
	const follower_user = context.params.follower_user;

	// get all the groups that follower_user follows
	return snapshot.ref.root.child('/groupsFollowing/' + follower_user).once('value', groups_following_snapshot => {
		// for each group, remove following_user from the membersFollowing (ok if it doesn't actually exist)
		const promises = [];
		groups_following_snapshot.forEach(function(group) {
			var group_id = group.key;
			let promise = snapshot.ref.root.child('/groupsFollowing/' + follower_user + '/' + group_id + '/membersFollowing/' + following_user).remove();
			promises.push(promise);
		});
		if (promises.length === 0) {
			return null;
		}
		return Promise.all(promises);
	}).catch(() => {return null});
})

// when user leaves a group,
// for each of his followers
//		check if follower is a subscriber of the group user is leaving from
//			if so, then check if is auto_subscribed and if len of membersFollowing is 0
exports.notificationOnFollowingMemberLeave = functions.database.ref('/groups/{groupId}/members/{leaving_user_id}').onDelete((snapshot, context) => {
	const group_id = context.params.groupId;
	const leaving_user_id = context.params.leaving_user_id;

	return snapshot.ref.root.child('/followers/' + leaving_user_id).once('value', followers => {
		const promises = [];
		var sync = new DispatchGroup();
		var token_0 = sync.enter();
		followers.forEach(function(follower) {
			var follower_id = follower.key;

			// need to remove from membersFollowing in groupsFollowing TODO
			promises.push(snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id + '/membersFollowing/' + leaving_user_id).remove());

			var token = sync.enter()
			snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id).once('value', in_subscriber_snapshot => {
				let is_subscribed = (in_subscriber_snapshot.val() !== null);
				if (is_subscribed) {
					snapshot.ref.root.child('/groups/' + group_id + '/members/' + follower_id).once('value', in_group_snapshot => {
						let not_in_group = (in_group_snapshot.val() === null);
						if (not_in_group) {
							snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id + '/autoSubscribed').once('value', auto_subscribed => {
								if (auto_subscribed !== null && auto_subscribed.val() !== null){
									var is_auto_subscribed = auto_subscribed.val()
									if (is_auto_subscribed) {
										snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id + '/membersFollowing').once('value', membersFollowing => {
											var count = 0 // don't know how to get the count of membersFollowing so this for now
											membersFollowing.forEach(function(memberFollowing) {
												count += 1
											})
											// check if count is 1 because leaving user is removed from membersFollowing only after this part in the promise
											if (count === 0 || count === 1 || membersFollowing === null){
												// send notification of unsubscribe_request
												var creation_time = parseFloat(Date.now()/1000)
												var values = {
													type: "unsubscribeRequest",
													from_id: leaving_user_id,
													group_id: group_id,
													creationDate: creation_time
												}
												let promise = snapshot.ref.root.child('notifications/' + follower_id).push(values);
												promises.push(promise);
												sync.leave(token);
											}
											else {
												sync.leave(token);
											}
										})
									}
									else {
										sync.leave(token);
									}
								}
								else {
									sync.leave(token);
								}
							})
						}
						else {
							sync.leave(token);
						}
					})
				}
				else {
					sync.leave(token);
				}
			})
		})
		sync.leave(token_0);
		sync.notify(function() {
			if (promises.length === 0) {
				return null;
			}
			return Promise.all(promises);
		})
	}).catch(() => {return null});
})

// ^^^^ Notification (not push just in database) in case members_following length becomes 0 when a user is unfollowed
exports.notificationOnNoMembersFollowing = functions.database.ref('/groupsFollowing/{user_id}/{group_id}/membersFollowing/{removed_user}').onDelete((snapshot, context) => {
	const user_id = context.params.user_id;
	const group_id = context.params.group_id;

	// first check to see if user is autosubscribed
	return snapshot.ref.root.child('/groupsFollowing/' + user_id + '/' + group_id + '/autoSubscribed').once('value', auto_subscribed => {
		if (auto_subscribed === null || auto_subscribed.val() === null) {
			return null;
		}
		var is_auto_subscribed = auto_subscribed.val()
		if (is_auto_subscribed) {
			// only send notification if the user is auto subscribed
			// check if length of membersFollowing is 0
			return snapshot.ref.root.child('/groupsFollowing/' + user_id + '/' + group_id + '/membersFollowing').once('value', membersFollowing => {
				if (membersFollowing.length === 0 || membersFollowing === null){
					// send notification of unsubscribe_request
					var creation_time = parseFloat(Date.now()/1000)
					var values = {
						type: "unsubscribeRequest",
						group_id: group_id,
						creationDate: creation_time
					}
					let promise = snapshot.ref.root.child('notifications/' + user_id).push(values)
					return promise;
				}
				else {
					return null;
				}
			}).catch(() => {return null});
		}
		else {
			return null;
		}
	}).catch(() => {return null});
})

// when follower_user unfollows following_user,
// remove follower_user from folliwng_user's membersFollowing under groupFollowPending for all groups that following_user is pending for
exports.removeUserFromGroupFollowPendingOnUnfollow = functions.database.ref('/followers/{following_user}/{follower_user}').onDelete((snapshot, context) => {
	const following_user = context.params.following_user;
	const follower_user = context.params.follower_user;

	// get all the groups following_user is a member of
	return snapshot.ref.root.child('/users/' + following_user + '/groups').once('value', groups_memberof_snapshot => {
		// for each group, go to groupFollowPending -> group -> follower_user -> membersFolliwng -> following_user and remove
		const promises = [];
		groups_memberof_snapshot.forEach(function(group) {
			var group_id = group.key;
			let promise = snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + follower_user + '/membersFollowing/' + following_user).remove()
			promises.push(promise);
		})
		if (promises.length === 0) {
			return null;
		}
		return Promise.all(promises);
	}).catch(() => {return null});
})

// When a user hides a group, for each follower:
// 		check if follower is subscribed to group and 
//		membersFollowing count of follower for group is == 1 and 
//		follower is not a member of group:
//			unsubscribe follower with the usual stuff
exports.removeGroupSubscribersOnProfileHide = functions.database.ref('/users/{user_hiding}/groups/{group_id}/hidden').onCreate((snapshot, context) => {
	const user_hiding = context.params.user_hiding;
	const group_id = context.params.group_id;
	return snapshot.ref.root.child('/users/' + user_hiding + "/groups/" + group_id + "/hidden").once('value', hidden_snapshot => {
		if (hidden_snapshot === null || hidden_snapshot.val() === null) {
			return null;
		}
		var is_hidden = hidden_snapshot.val()
		if (is_hidden) {
			return snapshot.ref.root.child('/followers/' + user_hiding).once('value', followers => {
				const promises = [];
				var sync = new DispatchGroup();
				var token_0 = sync.enter();
				followers.forEach(function(follower) {
					var follower_id = follower.key;
					var token = sync.enter()
					snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id).once('value', is_subscriber_snapshot => {
						let is_subscribed = (is_subscriber_snapshot.val() !== null);
						if (is_subscribed) {
							snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id + '/autoSubscribed').once('value', auto_subscribed => {
								if (auto_subscribed !== null && auto_subscribed.val() !== null){
									var is_auto_subscribed = auto_subscribed.val()
									if (is_auto_subscribed) {
										snapshot.ref.root.child('/groups/' + group_id + '/members/' + follower_id).once('value', in_group_snapshot => {
											let not_in_group = (in_group_snapshot.val() === null);
											if (not_in_group) {
												snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id + '/membersFollowing').once('value', membersFollowing => {
													var count = 0 // don't know how to get the count of membersFollowing so this for now
													membersFollowing.forEach(function(memberFollowing) {
														count += 1
													})
													if (count === 1){
														promises.push(snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + follower_id).remove());
														promises.push(snapshot.ref.root.child('/groupFollowers/' + group_id + '/' + follower_id).remove());
														promises.push(snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id).remove());
														sync.leave(token);
													}
													else {
														sync.leave(token)
													}
												})
											}
											else {
												sync.leave(token)
											}
										})	
									}
									else {
										sync.leave(token)
									}
								}
								else {
									sync.leave(token)
								}
							})
						}
						else {
							sync.leave(token)
						}
					})
				})
				sync.leave(token_0);
				sync.notify(function() {
					if (promises.length === 0) {
						return null;
					}
					return Promise.all(promises);
				})
			}).catch(() => {return null});
		}
		else {
			return null;
		}
	}).catch(() => {return null});
})

exports.removeGroupSubscribersOnProfileHideUpdate = functions.database.ref('/users/{user_hiding}/groups/{group_id}/hidden').onUpdate((snapshot, context) => {
	const user_hiding = context.params.user_hiding;
	const group_id = context.params.group_id;
	return snapshot.after.ref.root.child('/users/' + user_hiding + "/groups/" + group_id + "/hidden").once('value', hidden_snapshot => {
		if (hidden_snapshot === null || hidden_snapshot.val() === null) {
			return null;
		}
		var is_hidden = hidden_snapshot.val()
		if (is_hidden) {
			return snapshot.after.ref.root.child('/followers/' + user_hiding).once('value', followers => {
				const promises = [];
				var sync = new DispatchGroup();
				var token_0 = sync.enter();
				followers.forEach(function(follower) {
					var follower_id = follower.key;
					var token = sync.enter()
					snapshot.after.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id).once('value', is_subscriber_snapshot => {
						let is_subscribed = (is_subscriber_snapshot.val() !== null);
						if (is_subscribed) {
							snapshot.after.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id + '/autoSubscribed').once('value', auto_subscribed => {
								if (auto_subscribed !== null && auto_subscribed.val() !== null){
									var is_auto_subscribed = auto_subscribed.val()
									if (is_auto_subscribed) {
										snapshot.after.ref.root.child('/groups/' + group_id + '/members/' + follower_id).once('value', in_group_snapshot => {
											let not_in_group = (in_group_snapshot.val() === null);
											if (not_in_group) {
												snapshot.after.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id + '/membersFollowing').once('value', membersFollowing => {
													var count = 0 // don't know how to get the count of membersFollowing so this for now
													membersFollowing.forEach(function(memberFollowing) {
														count += 1
													})
													if (count === 1){
														promises.push(snapshot.after.ref.root.child('/groupFollowPending/' + group_id + '/' + follower_id).remove());
														promises.push(snapshot.after.ref.root.child('/groupFollowers/' + group_id + '/' + follower_id).remove());
														promises.push(snapshot.after.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id).remove());
														sync.leave(token);
													}
													else {
														sync.leave(token)
													}
												})
											}
											else {
												sync.leave(token)
											}
										})	
									}
									else {
										sync.leave(token)
									}
								}
								else {
									sync.leave(token)
								}
							})
						}
						else {
							sync.leave(token)
						}
					})
				})
				sync.leave(token_0);
				sync.notify(function() {
					if (promises.length === 0) {
						return null;
					}
					return Promise.all(promises);
				})
			}).catch(() => {return null});
		}
		else {
			return null;
		}
	}).catch(() => {return null});
})

// send notification to all school members when a group is created
exports.notificationOnGroupAddedToSchool = functions.database.ref('/schools/{formatted_school}/groups/{group_id}').onCreate((snapshot, context) => {
	const group_id = context.params.group_id;
	const formatted_school = context.params.formatted_school;

	// A. get the users in the group and add to a list
	// B. get the people in the school and for each (excluding users in group):
	// C. send a notification saying that the a group was added to "school name". Notification just a push notification (not in notifications page)

	// A
	return snapshot.ref.root.child('/groupFollowers/' + group_id).once('value', subscribers_snapshot => {
		var subscribers = []
		subscribers_snapshot.forEach(function(subscriber) {
			var subscriber_id = subscriber.key;
			subscribers.push(subscriber_id)
		});

		// B
		return snapshot.ref.root.child('/schools/' + formatted_school + '/users').once('value', school_users_snapshot => {
			school_users_snapshot.forEach(function(school_user) {
				var uid = school_user.key;
				
				// C
				if (!subscribers.includes(uid)) {
					admin.database().ref('/users/' + uid + '/token').once('value', token_snapshot => {
						var user_token = token_snapshot.val();

						var school = formatted_school.split("_-a-_").join(" ");
						school_for_group_arr = school.split(",");
						var stripped_school = ""
						if (school_for_group_arr.length > 0) {
							stripped_school = school_for_group_arr[0];
						}

						var message = "A friend group has been added to " + stripped_school
						const payload = {
							notification: {
								body: message
							}
						};
						admin.messaging().sendToDevice(user_token, payload)
					})
				}
			});			
		})
	})
})

exports.transferToMembersFollowingOnSubscribe = functions.database.ref('/groupsFollowing/{user_id}/{group_id}').onCreate((snapshot, context) => {
	const user_id = context.params.user_id;
	const group_id = context.params.group_id;

	// first check to see if the group is private
	return snapshot.ref.root.child('/groups/' + group_id + '/private').once('value', private_snapshot => {
		var private_string = private_snapshot.val().toString();
		if (private_string === "true") {
			return snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + user_id + '/membersFollowing').once('value', membersFollowing => {
				return snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + user_id + '/autoSubscribed').once('value', auto_subscribed => {
					return snapshot.ref.root.child('/groups/' + group_id + '/lastPostedDate').once('value', last_post_date => {
						const promises = [];

						var post_date = last_post_date.val();
						if(post_date === "0" || post_date === 0){
							post_date = 1;
						}
						post_date = parseFloat(post_date)

						let setLastPosted = snapshot.ref.root.child('/groupsFollowing/' + user_id + '/' + group_id + '/lastPostedDate').set(post_date);
						promises.push(setLastPosted);

						// set the auto_subscribed from groupFollowPending for the groupFollowing 
						if (auto_subscribed !== null && auto_subscribed.val() !== null){
							var is_auto_subscribed = auto_subscribed.val()
							let set_auto_subscribed = snapshot.ref.root.child('/groupsFollowing/' + user_id + '/' + group_id + '/autoSubscribed').set(is_auto_subscribed);
							promises.push(set_auto_subscribed);
						}
					
						// remove the newly subscribed member from groupFollowPending, this deletes membersFollowing from under the user's entree in groupFollowPending too
						let promise_removeGroupFollowPending = snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + user_id).remove();
						promises.push(promise_removeGroupFollowPending);

						membersFollowing.forEach(function(following) {
							var following_id = following.key;
							var following_val = following.val();
							let promise_membersFollowing = snapshot.ref.root.child('/groupsFollowing/' + user_id + '/' + group_id + '/membersFollowing/' + following_id).set(following_val);
							promises.push(promise_membersFollowing);
						})
						return Promise.all(promises);
					}).catch(() => {return null});
				}).catch(() => {return null});
			}).catch(() => {return null});
		}
		else {
			return null;
		}
	}).catch(() => {return null});
})

exports.addToUsernamesOnCreate = functions.database.ref('/users/{user_id}/username/{username}').onCreate((snapshot, context) => {
	const user_id = context.params.user_id;
	const username = context.params.username;

	return snapshot.ref.root.child('/usernames').child(username).set(user_id);
})

exports.updateGroupsLastPostedWhenPostDeleted = functions.database.ref('/posts/{groupId}/{postId}/creationDate').onDelete((post_snapshot, context) => {
	const group_id = context.params.groupId;
	const followers_path = '/groupFollowers/' + group_id

	// get the groups current lastPostedDate
	// get the deleted post's post date
	// compare them and if not equal return
	var creationDate = parseInt(post_snapshot.val())
	return post_snapshot.ref.root.child('/groups/' + group_id + '/lastPostedDate').once('value', group_last_post_date => {
		var groups_post_date = group_last_post_date.val();
		if(groups_post_date === "0" || groups_post_date === 0){
			groups_post_date = 1;
		}
		groups_post_date = parseInt(groups_post_date)

		// need to do this instead of not equal since lastPostedDate could be different
		// example:
		// in group: 1598129142 (no decimal)
		// in deleted post: 1598129142.026304 (decimals)
		// in following: 1598129143.26 (decimals)
		if (creationDate < groups_post_date - 10 || creationDate > groups_post_date + 10){
			return null
		}

		// get the sorted posts of the group and get second last posted as post_time, or 0 if empty.
		// could make it limitTOLast(2) if the one being deleted is still there
		return post_snapshot.ref.root.child('/posts/' + group_id).orderByChild('creationDate').limitToLast(1).once('value', posts_snapshot => {
			var new_post_date = 0;

			var sync = new DispatchGroup();
			var token_0 = sync.enter();
			var found_follower = false

			posts_snapshot.forEach(function(post) {
				if (found_follower === false) {
					found_follower = true
		        	var post_id = post.key;
		        	var token = sync.enter()
		        	return post_snapshot.ref.root.child('/posts/' + group_id + "/" + post_id + "/creationDate").once('value', post_date_snapshot => {
		        		new_post_date = post_date_snapshot.val();
						new_post_date = parseFloat(new_post_date)
						sync.leave(token);
						sync.leave(token_0);
				  	}).catch(() => {return null});
				}
			})
			if (!found_follower) {
				sync.leave(token_0);
			}

			sync.notify(function() {
				return post_snapshot.ref.root.child(followers_path).once('value', follower_snapshot => {
					const promises = [];
					promises.push(post_snapshot.ref.root.child('/groups/' + group_id + '/lastPostedDate').set(new_post_date));
					// snapshot contains all the subscribers
					follower_snapshot.forEach(function(follower) {
			        	var uid = follower.key;
						let promise = post_snapshot.ref.root.child('/groupsFollowing/' + uid + '/' + group_id + '/lastPostedDate').set(new_post_date);
						promises.push(promise);
			    	});
					if (promises.length === 0) {
						return null;
					}
					return Promise.all(promises);
			  	}).catch(() => {return null});
			})
	  	}).catch(() => {return null});
	}).catch(() => {return null});
});

// need to use imageHeight because videos also use imgUrl
exports.removePhotoWhenPostDeleted = functions.database.ref('/posts/{groupId}/{postId}/imageHeight').onDelete((post_snapshot, context) => {
	const group_id = context.params.groupId;
	const post_id = context.params.postId;

	const bucket = firebase.storage().bucket();
	const filePath = 'group_post_images/' + group_id  + '/' + post_id + '.jpeg'
	return bucket.file(filePath).delete()
});

exports.removeVideoWhenPostDeleted = functions.database.ref('/posts/{groupId}/{postId}/videoUrl').onDelete((post_snapshot, context) => {
	const group_id = context.params.groupId;
	const post_id = context.params.postId;

	const bucket = firebase.storage().bucket();
	const videoFilePath = 'group_post_videos/' + group_id  + '/' + post_id
	const photoFilePath = 'group_post_images/' + group_id  + '/' + post_id + '.jpeg'

	const promises = []
	promises.push(bucket.file(videoFilePath).delete())
	promises.push(bucket.file(photoFilePath).delete())
	return Promise.all(promises);
});

// NOT TESTED
exports.deleteGroupOnNoMembers = functions.database.ref('/groupMembersCount/{group_id}').onUpdate((snapshot, context) => {
	const group_id = context.params.group_id;
	const subscribers_path = '/groupFollowers/' + group_id
	return snapshot.after.ref.root.child('/groupMembersCount/' + group_id).once('value', counter_value => {
		if (parseInt(counter_value.val()) < 1) {
			return snapshot.after.ref.root.child(subscribers_path).once('value', subscribers_snapshot => {
				return snapshot.after.ref.root.child('/groups/' + group_id + '/groupname').once('value', groupname_snapshot => {
					var groupname = "";
					if (groupname_snapshot !== null && groupname_snapshot.val() !== null) {
						groupname = groupname_snapshot.val().toString();
					}

					const promises = []

					// for each subscriber, remove group from subscribing
					subscribers_snapshot.forEach(function(subscriber) {
			        	var uid = subscriber.key;
						promises.push(snapshot.after.ref.root.child('/groupsFollowing/' + uid + '/' + group_id).remove());
						promises.push(snapshot.after.ref.root.child('/userRemovedGroups/' + uid + '/' + group_id).remove());
			    	});

			    	promises.push(snapshot.after.ref.root.child('/groupFollowers/' + group_id).remove());
			    	promises.push(snapshot.after.ref.root.child('/groupFollowPending/' + group_id).remove());
			    	promises.push(snapshot.after.ref.root.child('/groupFollowersCount/' + group_id).remove());
			    	promises.push(snapshot.after.ref.root.child('/groupMembersCount/' + group_id).remove());

			    	if (groupname !== "") {
			    		promises.push(snapshot.after.ref.root.child('/groupnames/' + groupname).remove());
			    	}

					// delete the group
					promises.push(snapshot.after.ref.root.child('/groups/' + group_id).remove());

					if (promises.length === 0) {
						return null;
					}
					return Promise.all(promises);
				}).catch(() => {return null});
		  	}).catch(() => {return null});
		}
		else {
			return null;
		}
	}).catch(() => {return null});
})

// when importing contacts, they'll be added with priority 1
// users that are followed by lots of your following will have priority 3-5, depending on how many common connections [later]
// priority of 1000 means not active anymore, user has followed them or rejected it

exports.updateRecommendedFollowOnGroupJoin = functions.database.ref('/groups/{groupId}/members/{uid}').onCreate((snapshot, context) => {
	const group_id = context.params.groupId;
	const new_member_id = context.params.uid;

	let promises = [];

	// for user joining: add all members of groups to it, if not already following them... with priority 0
	// for users in group: add joining member to each of them, if not already following... with priority 0

	// fetch the group's members
	return snapshot.ref.root.child('/groups/' + group_id + '/members/').once('value', members_snapshot => {
		var sync = new DispatchGroup();
		var token_0 = sync.enter();
		members_snapshot.forEach(function(member) {
			var member_id = member.key;
			
			// check if the new member is following them
			if (member_id !== new_member_id) {
				var token = sync.enter()
				snapshot.ref.root.child('/following/' + new_member_id + '/' + member_id).once('value', is_following_member_snapshot => {
					if (is_following_member_snapshot.val() === null) { // if not already following them
						promises.push(snapshot.ref.root.child('/recommendedToFollow/' + new_member_id + '/' + member_id).set(0));
					}

					// check if they are following the new_member
					snapshot.ref.root.child('/following/' + member_id + '/' + new_member_id).once('value', is_following_new_member_snapshot => {
						if (is_following_new_member_snapshot.val() === null) { // if not already following them
							promises.push(snapshot.ref.root.child('/recommendedToFollow/' + member_id + '/' + new_member_id).set(0));
						}
						sync.leave(token)
					}).catch(() => {return null});

				}).catch(() => {return null});
			}
		})
		sync.leave(token_0)
		sync.notify(function() {
			if (promises.length === 0) {
				return null;
			}
			return Promise.all(promises);
		})
	}).catch(() => {return null});
})

exports.removeFromRequestedGroupsOnGroupJoin = functions.database.ref('/groups/{groupId}/members/{uid}').onCreate((snapshot, context) => {
	const group_id = context.params.groupId;
	const new_member_id = context.params.uid;
	return snapshot.ref.root.child('/users/' + new_member_id + '/requestedGroups/' + group_id).remove();
})

exports.updateRecommendedFollowOnGroupSubscribe = functions.database.ref('/groupsFollowing/{user_id}/{group_id}').onCreate((snapshot, context) => {
	const new_subscriber_id = context.params.user_id;
	const group_id = context.params.group_id;

	// for user subscribing: add all members of groups to it, if not already following them... with priority 4
	// for users in group: add subscribing user to each of them, if not already following... with priority 4
	let promises = [];

	// check if new_subscriber_id is in the group already
	return snapshot.ref.root.child('/groups/' + group_id + '/members/' + new_subscriber_id).once('value', is_in_group_snapshot => {
		if (is_in_group_snapshot.val() !== null) { // is already in the group as a member
			return null;
		}
		// fetch the group's members
		return snapshot.ref.root.child('/groups/' + group_id + '/members/').once('value', members_snapshot => {
			var sync = new DispatchGroup();
			var token_0 = sync.enter();

			members_snapshot.forEach(function(member) {
				var member_id = member.key;
				
				// check if the new member is following member already
				if (member_id !== new_subscriber_id) {
					var token = sync.enter()
					snapshot.ref.root.child('/following/' + new_subscriber_id + '/' + member_id).once('value', is_following_member_snapshot => {
						if (is_following_member_snapshot.val() === null) { // if not already following them
							// check if already in recommendedToFollow with a higher priority
							snapshot.ref.root.child('/recommendedToFollow/' + new_subscriber_id + '/' + member_id).once('value', new_subscriber_rec_snapshot => {
								if ((new_subscriber_rec_snapshot.val() === null || new_subscriber_rec_snapshot.val() > 4) && new_subscriber_rec_snapshot.val() !== 1000) { // if priority doesn't exist or there is a lower priority currenlty
									promises.push(snapshot.ref.root.child('/recommendedToFollow/' + new_subscriber_id + '/' + member_id).set(4));
								}
								// check if member is already following the new_member
								snapshot.ref.root.child('/following/' + member_id + '/' + new_subscriber_id).once('value', is_following_new_member_snapshot => {
									if (is_following_new_member_snapshot.val() === null) { // if not already following them
										snapshot.ref.root.child('/recommendedToFollow/' + member_id + '/' + new_subscriber_id).once('value', member_rec_snapshot => {
											if ((member_rec_snapshot.val() === null || member_rec_snapshot.val() > 4) && member_rec_snapshot.val() !== 1000) { // if priority doesn't exist or there is a lower priority currenlty
												promises.push(snapshot.ref.root.child('/recommendedToFollow/' + member_id + '/' + new_subscriber_id).set(4));
											}
											sync.leave(token)
										}).catch(() => {return null});
									}
									else {
										sync.leave(token)
									}
								}).catch(() => {return null});
							}).catch(() => {return null});
						}
						else {
							// check if member is already following the new_member
							snapshot.ref.root.child('/following/' + member_id + '/' + new_subscriber_id).once('value', is_following_new_member_snapshot => {
								if (is_following_new_member_snapshot.val() === null) { // if not already following them
									snapshot.ref.root.child('/recommendedToFollow/' + member_id + '/' + new_subscriber_id).once('value', member_rec_snapshot => {
										if (member_rec_snapshot.val() === null || member_rec_snapshot.val() > 4) { // if priority doesn't exist or there is a lower priority currenlty
											promises.push(snapshot.ref.root.child('/recommendedToFollow/' + member_id + '/' + new_subscriber_id).set(4));
										}
										sync.leave(token)
									}).catch(() => {return null});
								}
								else {
									sync.leave(token)
								}
							}).catch(() => {return null});
						}
					}).catch(() => {return null});
				}
			})
			sync.leave(token_0)
			sync.notify(function() {
				if (promises.length === 0) {
					return null;
				}
				return Promise.all(promises);
			})
		}).catch(() => {return null});
	}).catch(() => {return null});
})

exports.updateRecommendedFollowOnUserFollow = functions.database.ref('/followers/{following_user}/{follower_user}').onCreate((snapshot, context) => {
	const following_user = context.params.following_user;
	const follower_user = context.params.follower_user;

	// remove following_user from follower_user's recommended by setting value to 1000
	return snapshot.ref.root.child('/recommendedToFollow/' + follower_user + '/' + following_user).set(1000);
})

exports.updateRecommendedUsersOnNumberTiedToAccount = functions.database.ref('/numbers/{number}').onCreate((snapshot, context) => {
//      when user creates an account with a number tied to it:
//          for each user under the number in importedContacts:
//              if not already in said user's recommendedUsers
//                  add them to recommendedUsers with priority 1
//          remove user from importedContacts

	const number = context.params.number;
	if (snapshot.val() === null) { 
		return null
	}
	// const numbers_user_id = context.params.numbers_user_id;
	const numbers_user_id = snapshot.val()

	// if number not in importedContacts then return
	console.log("start")
	return snapshot.ref.root.child('/importedContacts/' + number).once('value', imported_contacts_snapchat => {
		if (imported_contacts_snapchat === null || imported_contacts_snapchat.val() === null) {
			console.log("null 1")
			return null;
		}
		console.log("inside")

		const promises = []

		//  remove user from importedContacts
		promises.push(snapshot.ref.root.child('/importedContacts/' + number).remove());

		var sync = new DispatchGroup();
		var token_0 = sync.enter();
		console.log("enter 0")
		imported_contacts_snapchat.forEach(function(imported_user) {
			var token = sync.enter();
			console.log("enter 1")
			var imported_user_id = imported_user.key
			snapshot.ref.root.child('/following/' + numbers_user_id + '/' + imported_user_id).once('value', is_following_imported_snapshot => {
				if (is_following_imported_snapshot.val() === null) { // if not already following them
					// check if already in recommendedToFollow with a higher priority
					snapshot.ref.root.child('/recommendedToFollow/' + numbers_user_id + '/' + imported_user_id).once('value', imported_rec_snapshot => {
						if ((imported_rec_snapshot.val() === null || imported_rec_snapshot.val() > 4) && imported_rec_snapshot.val() !== 1000) { // if priority doesn't exist or there is a lower priority currenlty
							promises.push(snapshot.ref.root.child('/recommendedToFollow/' + numbers_user_id + '/' + imported_user_id).set(1));
						}
						// check if member is already following the new_member
						snapshot.ref.root.child('/following/' + imported_user_id + '/' + numbers_user_id).once('value', is_following_numbers_user_snapshot => {
							if (is_following_numbers_user_snapshot.val() === null) { // if not already following them
								snapshot.ref.root.child('/recommendedToFollow/' + imported_user_id + '/' + numbers_user_id).once('value', number_rec_snapshot => {
									if ((number_rec_snapshot.val() === null || number_rec_snapshot.val() > 4) && number_rec_snapshot.val() !== 1000) { // if priority doesn't exist or there is a lower priority currenlty
										promises.push(snapshot.ref.root.child('/recommendedToFollow/' + imported_user_id + '/' + numbers_user_id).set(1));
									}
									sync.leave(token)
									console.log("leave 0")
								}).catch(() => {return null});
							}
							else {
								sync.leave(token)
								console.log("leave 1")
							}
						}).catch(() => {return null});
					}).catch(() => {return null});
				}
				else {
					// check if member is already following the new_member
					snapshot.ref.root.child('/following/' + imported_user_id + '/' + numbers_user_id).once('value', is_following_numbers_user_snapshot => {
						if (is_following_numbers_user_snapshot.val() === null) { // if not already following them
							snapshot.ref.root.child('/recommendedToFollow/' + imported_user_id + '/' + numbers_user_id).once('value', number_rec_snapshot => {
								if (number_rec_snapshot.val() === null || number_rec_snapshot.val() > 4) { // if priority doesn't exist or there is a lower priority currenlty
									promises.push(snapshot.ref.root.child('/recommendedToFollow/' + imported_user_id + '/' + numbers_user_id).set(1));
								}
								sync.leave(token)
								console.log("leave 2")
							}).catch(() => {return null});
						}
						else {
							sync.leave(token)
						}
					}).catch(() => {return null});
				}
			}).catch(() => {return null});
    	});

    	sync.leave(token_0)
    	console.log("leave 3")
		sync.notify(function() {
			console.log("in notify")
			if (promises.length === 0) {
				return null;
			}
			return Promise.all(promises);
		})

		// get all the users under the number in importedContacts
	}).catch(() => {return null});
});


// ---------------- Updating counts ----------------

exports.updateGroupFollowersCountOnSubscribe = functions.database.ref('/groupFollowers/{group_id}/{subscribing_user_id}').onCreate((snapshot, context) => {
	const group_id = context.params.group_id;
    return snapshot.ref.root.child('/groupFollowersCount/' + group_id).transaction(counter_value => {
		return (counter_value || 0) + 1;
	}).catch(() => {return null});
})

exports.updateGroupFollowersCountOnUnSubscribe = functions.database.ref('/groupFollowers/{group_id}/{subscribing_user_id}').onDelete((snapshot, context) => {
	const group_id = context.params.group_id;
    return snapshot.ref.root.child('/groupFollowersCount/' + group_id).transaction(counter_value => {
		return (counter_value || 1) - 1;
	}).catch(() => {return null});
})

exports.updateUserFollowersCountOnFollow = functions.database.ref('/followers/{following_user}/{follower_user}').onCreate((snapshot, context) => {
	const following_user = context.params.following_user;
	return snapshot.ref.root.child('/userFollowersCount/' + following_user).transaction(counter_value => {
		return (counter_value || 0) + 1;
	}).catch(() => {return null});
})

exports.updateUserFollowersCountOnUnfollow = functions.database.ref('/followers/{following_user}/{follower_user}').onDelete((snapshot, context) => {
	const following_user = context.params.following_user;
	return snapshot.ref.root.child('/userFollowersCount/' + following_user).transaction(counter_value => {
		return (counter_value || 1) - 1;
	}).catch(() => {return null});
})

exports.updateGroupMembersCountOnJoin = functions.database.ref('/groups/{group_id}/members/{joining_user_id}').onCreate((snapshot, context) => {
	const group_id = context.params.group_id;
	return snapshot.ref.root.child('/groupMembersCount/' + group_id).transaction(counter_value => {
		return (counter_value || 0) + 1;
	}).catch(() => {return null});
})

exports.updateGroupMembersCountOnLeave = functions.database.ref('/groups/{group_id}/members/{leaving_user_id}').onDelete((snapshot, context) => {
	const group_id = context.params.group_id;
	return snapshot.ref.root.child('/groupMembersCount/' + group_id).transaction(counter_value => {
		return (counter_value || 1) - 1;
	}).catch(() => {return null});
})

exports.updateUserSubscriptionsCountOnSubscribe = functions.database.ref('/groupFollowers/{group_id}/{subscribing_user_id}').onCreate((snapshot, context) => {
	const subscribing_user_id = context.params.subscribing_user_id;
	return snapshot.ref.root.child('/userSubscriptionsCount/' + subscribing_user_id).transaction(counter_value => {
		return (counter_value || 0) + 1;
	}).catch(() => {return null});
})

exports.updateUserSubscriptionsCountOnUnSubscribe = functions.database.ref('/groupFollowers/{group_id}/{un_subscribing_user_id}').onDelete((snapshot, context) => {
	const un_subscribing_user_id = context.params.un_subscribing_user_id;
	return snapshot.ref.root.child('/userSubscriptionsCount/' + un_subscribing_user_id).transaction(counter_value => {
		return (counter_value || 1) - 1;
	}).catch(() => {return null});
})

exports.updateUserFollowingCountOnFollow = functions.database.ref('/followers/{following_user}/{follower_user}').onCreate((snapshot, context) => {
	const follower_user = context.params.follower_user;
	return snapshot.ref.root.child('/userFollowingCount/' + follower_user).transaction(counter_value => {
		return (counter_value || 0) + 1;
	}).catch(() => {return null});
})

exports.updateUserFollowingCountOnUnFollow = functions.database.ref('/followers/{following_user}/{follower_user}').onDelete((snapshot, context) => {
	const follower_user = context.params.follower_user;
	return snapshot.ref.root.child('/userFollowingCount/' + follower_user).transaction(counter_value => {
		return (counter_value || 1) - 1;
	}).catch(() => {return null});
})

exports.updatePostViewsCountOnView = functions.database.ref('/postViews/{post_id}/{user_id}').onCreate((snapshot, context) => {
	const post_id = context.params.post_id;
	return snapshot.ref.root.child('/postViewsCount/' + post_id).transaction(counter_value => {
		return (counter_value || 0) + 1;
	}).catch(() => {return null});
})

exports.updateNumGroupsCountOnJoin = functions.database.ref('/groups/{group_id}/members/{joining_user_id}').onCreate((snapshot, context) => {
	const joining_user_id = context.params.joining_user_id;
	return snapshot.ref.root.child('/usersGroupsCount/' + joining_user_id).transaction(counter_value => {
		return (counter_value || 0) + 1;
	}).catch(() => {return null});
})

exports.updateNumGroupsCountOnLeave = functions.database.ref('/groups/{group_id}/members/{leaving_user_id}').onDelete((snapshot, context) => {
	const leaving_user_id = context.params.leaving_user_id;
	return snapshot.ref.root.child('/usersGroupsCount/' + leaving_user_id).transaction(counter_value => {
		return (counter_value || 1) - 1;
	}).catch(() => {return null});
})

exports.updateNumNotificationsCountOnNew = functions.database.ref('/notifications/{user_id}/{notification_id}').onCreate((snapshot, context) => {
	const user_id = context.params.user_id;
	return snapshot.ref.root.child('/usersNotificationsCount/' + user_id).transaction(counter_value => {
		return (counter_value || 0) + 1;
	}).catch(() => {return null});
})

// '/schools/' + selected_school + '/groups/' + group_id).set(creation_time);
exports.updateNumGroupsInSchoolOnNew = functions.database.ref('/schools/{selected_school}/groups/{group_id}').onCreate((snapshot, context) => {
	const selected_school = context.params.selected_school;

	return snapshot.ref.root.child('/groupsInSchoolCount/' + selected_school).transaction(counter_value => {
		return (counter_value || 0) + 1;
	}).catch(() => {return null});
})


// ----------- Invite text messages ----------

// Twilio Phone numbers:
// +13232501061
// +19252814881
// +12023041217

/// Validate E164 format
function validE164(num) {
    return /^\+?[1-9]\d{1,14}$/.test(num)
}

// client app checks to see if the number is already in the system
// so don't need to do it here
exports.sendInvite = functions.database.ref('/invitedContacts/{number}/{group_id}').onCreate((snapshot, context) => {
	const number = context.params.number;
	const group_id = context.params.group_id;

	const twilio = require('twilio');
	const accountSid = functions.config().twilio.sid
	const authToken  = functions.config().twilio.token
	const client = new twilio(accountSid, authToken);
	var twilioNumber = '+13232501061'

	// TODO
	// get group name
	// get the name of the person who invited
	return snapshot.ref.root.child('/groups/' + group_id + '/groupname').once('value', groupname_snapshot => {
		var groupname = "";
		if (groupname_snapshot !== null && groupname_snapshot.val() !== null) {
			groupname = groupname_snapshot.val().toString();
		}

		// check if the group has a school and get the school if so
		return snapshot.ref.root.child('/groups/' + group_id + '/selectedSchool').once('value', school_for_group_snapshot => {
			var school_for_group = "";
			if (school_for_group_snapshot !== null && school_for_group_snapshot.val() !== null) {
				school_for_group = school_for_group_snapshot.val().toString();
			}
			if (school_for_group !== "") {
				school_for_group = school_for_group.split("_-a-_").join(" ");
				school_for_group_arr = school_for_group.split(",");
				if (school_for_group_arr.length > 0) {
					school_for_group = school_for_group_arr[0];
				}
			}

			return snapshot.ref.root.child('/invitedContacts/' + number + "/" + group_id + "/invitedBy").once('value', invited_by_snapshot => {
				var invited_by_id = "";
				if (invited_by_snapshot !== null && invited_by_snapshot.val() !== null) {
					invited_by_id = invited_by_snapshot.val().toString();
				}

				return snapshot.ref.root.child('/invitedContacts/' + number).once('value', groups_for_contact => {
					var sync = new DispatchGroup();
					var token_0 = sync.enter();
					let used_twilio_numbers = []

					groups_for_contact.forEach(function(post) {
			        	var post_id = post.key;
			        	var token = sync.enter()
			        	return snapshot.ref.root.child('/invitedContacts/' + number + '/' + group_id + '/twilioNumber').once('value', twilio_number_snapshot => {
			        		if (twilio_number_snapshot !== null && twilio_number_snapshot.val() !== null && twilio_number_snapshot.val() !== "0") {
								twilio_number = twilio_number_snapshot.val().toString();
				        		used_twilio_numbers.push(twilio_number);
							}
							sync.leave(token);
							
					  	}).catch(() => {return null});
					})
					sync.leave(token_0);

					sync.notify(function() {
						var promise = snapshot.ref.root.child('/invitedContacts/' + number + '/' + group_id + '/twilioNumber').set("+13232501061");
						if (used_twilio_numbers.indexOf("+13232501061") < 0) { // number not used yet
							twilioNumber = "+13232501061"
							promise = snapshot.ref.root.child('/invitedContacts/' + number + '/' + group_id + '/twilioNumber').set("+13232501061");
						}
						else if (used_twilio_numbers.indexOf("+19252814881") < 0) { // number not used yet
							twilioNumber = "+19252814881"
							promise = snapshot.ref.root.child('/invitedContacts/' + number + '/' + group_id + '/twilioNumber').set("+19252814881");
						}
						else if (used_twilio_numbers.indexOf("+12023041217") < 0) { // number not used yet
							twilioNumber = "+12023041217"
							promise = snapshot.ref.root.child('/invitedContacts/' + number + '/' + group_id + '/twilioNumber').set("+12023041217");
						}

						return snapshot.ref.root.child('/users/' + invited_by_id + '/name').once('value', name_snapshot => {
							var name = "";
							if (name_snapshot !== null && name_snapshot.val() !== null) {
								name = name_snapshot.val().toString();
							}

							return snapshot.ref.root.child('/users/' + invited_by_id + '/username').once('value', username_snapshot => {
								var username = "";
								if (username_snapshot !== null && username_snapshot.val() !== null) {
									username = username_snapshot.val().toString();
								}

								if ( !validE164(number) ) {
							        throw new Error('number must be E164 format!')
							    }

							    var message = ""
							    
							    if (name !== "") {
							    	message += name
							    }
							    else {
							    	message += username
							    }

							    if (groupname === "") {
							    	message += ' just added you to a group'
							    }
							    else {
							    	message += ' just added you to group "' + groupname.split("_-a-_").join(" ").split("_-b-_").join("'") + '"'
							    }

							    message += " on GroupRoots Beta! Download the app from: https://testflight.apple.com/join/5zCu1oG6"

							    const textMessageFirst = {
							        body: message,
							        to: number,  // Text to this number
							        from: twilioNumber // From a valid Twilio number
							    }
							    const textMessageSecond = {
							        // body: "Share your best group moments collectively and see what groups your friends belong to",
							        // share group moments to your followers through group profiles
							        // body: "Share your group moments to your followers through group profiles. Show your followers what groups you belong to",
							        // body: "Share photos and videos to your groups, for your followers to see! Show your friends what groups you belong to",
							        body: "Your group is a shared space for photos, videos, and memes. Add to its ongoing story… or post for 24 hours to keep it casual and fun.",
							        to: number,  // Text to this number
							        from: twilioNumber // From a valid Twilio number
							    }

							    const stopMessage = {
							        body: 'Group post messaging by GroupRoots. Message and data rates may apply. Reply STOP to stop receiving group post messages',
							        to: number,  // Text to this number
							        from: twilioNumber // From a valid Twilio number
							    }

							    client.messages.create(textMessageFirst)
							    setTimeout(function(){ 
							    	client.messages.create(textMessageSecond);
							    	setTimeout(function(){ 
								    	client.messages.create(stopMessage)
								    }, 2000);
							    }, 2000);

							    return promise;
							}).catch(() => {return null});
						}).catch(() => {return null});
					})
				}).catch(() => {return null});
			}).catch(() => {return null});
		}).catch(() => {return null});
	}).catch(() => {return null});
    
	// check to see which phone number hasn't been used for user
	// afterwards, set invitedContacts/contact_number/group_id/twilio_number
	// also need to set invitedContacts/contact_number/group_id/invited_by
	// these will the [group_id: 1] thing
});

// whenever a new post is created
// get the contacts that are invited (and that haven't done STOP)
// send them a message with the post and an image

// LATER TODO: Use storage to get the url with: storageRef.child(path).getDownloadURL().then(function(url) { ... instead of hardcoded

	// fix for loop problem
exports.sendPostToInvited = functions.database.ref('/posts/{group_id}/{post_id}').onCreate((snapshot, context) => {
	// var imagesRef = functions.storage.bucket('group_post_images');
	
	const post_id = context.params.post_id;
	const group_id = context.params.group_id;
	const twilio = require('twilio');
	const accountSid = functions.config().twilio.sid
	const authToken  = functions.config().twilio.token
	const client = new twilio(accountSid, authToken);
	// var imageRef = imagesRef.child(group_id).child(post_id);
	// var path = imageRef.fullPath

	return snapshot.ref.root.child('/invitedContactsForGroup/' + group_id).once('value', invited_numbers => {

		var sync = new DispatchGroup();
		var token_0 = sync.enter();
		invited_numbers.forEach(function(number_obj) {
			var token = sync.enter();
        	var number = number_obj.key;

        	// check to see that the user hasn't said STOP
        	snapshot.ref.root.child('/invitedContactsForGroup/' + group_id + '/' + number).once('value', invited_number_snapshot => {
        		// if the number has value of false, then it has unsubscribed from recieving messages
        		if (invited_number_snapshot !== null && invited_number_snapshot.val() !== null && invited_number_snapshot.val().toString() === "false") {
        			return null;
        		}
        		else {
        			// get the number that was used to send the first message
		        	snapshot.ref.root.child('/invitedContacts/' + number + '/' + group_id + '/twilioNumber').once('value', twilio_number_snapshot => {
		        		if (twilio_number_snapshot !== null && twilio_number_snapshot.val() !== null && twilio_number_snapshot.val() !== "0") {
							let twilio_number = twilio_number_snapshot.val().toString();

							// get the id of the user that invited the user
							// snapshot.ref.root.child('/invitedContacts/' + number + "/" + group_id + "/invitedBy").once('value', invited_by_snapshot => {

							// get the id of the user that posted the picture
							snapshot.ref.root.child('/posts/' + group_id + "/" + post_id + "/userUploaded").once('value', user_uploaded_snapshot => {
								var user_uploaded = "";
								if (user_uploaded_snapshot !== null && user_uploaded_snapshot.val() !== null) {
									user_uploaded = user_uploaded_snapshot.val().toString();
								}

								snapshot.ref.root.child('/users/' + user_uploaded + '/name').once('value', name_snapshot => {
									var name = "";
									if (name_snapshot !== null && name_snapshot.val() !== null) {
										name = name_snapshot.val().toString();
									}

									snapshot.ref.root.child('/users/' + user_uploaded + '/username').once('value', username_snapshot => {
										var username = "";
										if (username_snapshot !== null && username_snapshot.val() !== null) {
											username = username_snapshot.val().toString();
										}

										snapshot.ref.root.child('/groups/' + group_id + '/groupname').once('value', groupname_snapshot => {
											var groupname = "";
											if (groupname_snapshot !== null && groupname_snapshot.val() !== null) {
												groupname = groupname_snapshot.val().toString();
											}

											snapshot.ref.root.child('/posts/' + group_id + "/" + post_id + '/videoUrl').once('value', videoUrl_snapshot => {
												var vidUrl = "";
												if (videoUrl_snapshot !== null && videoUrl_snapshot.val() !== null) {
													vidUrl = videoUrl_snapshot.val().toString();
												}

												snapshot.ref.root.child('/posts/' + group_id + "/" + post_id + '/caption').once('value', caption_snapshot => {
													var caption = "";
													if (caption_snapshot !== null && caption_snapshot.val() !== null) {
														caption = caption_snapshot.val().toString();
													}

													snapshot.ref.root.child('/posts/' + group_id + "/" + post_id + '/imageUrl').once('value', url_snapshot => {
														var url = "";
														if (url_snapshot !== null && url_snapshot.val() !== null) {
															url = url_snapshot.val().toString();
														}
													// storageRef.child(path).getDownloadURL().then(function(url) {
														if ( !validE164(number) ) {
													        throw new Error('number must be E164 format!')
													    }

													    // create the message
													    var message1 = ""

													    if (name === "") { message1 += username }
													    else { message1 += name }

													    if (vidUrl === "") { message1 += " posted a picture in " }
													    else { message1 += " posted a video in " }
													    
													    if (groupname === "") { message1 += 'the group' }
													    else { message1 += groupname.split("_-a-_").join(" ").split("_-b-_").join("'") }

													    if (caption !== ""){
													    	message1 += ': "' + caption + '"'
													    }
														message1 += '... view more with GroupRoots: https://testflight.apple.com/join/5zCu1oG6'

													    const postedMessage = {
													        body: message1,
													        to: number,  // Text to this number
													        from: twilio_number, // From a valid Twilio number
													        mediaUrl: url
													    }
													    client.messages.create(postedMessage)
													    sync.leave(token)

													}).catch(() => {return null});
												}).catch(() => {return null});
											}).catch(() => {return null});
										}).catch(() => {return null});
									}).catch(() => {return null});
								}).catch(() => {return null});
							}).catch(() => {return null});
						}
						else {
							return null;
						}
					}).catch(() => {return null});
        		}
        	}).catch(() => {return null});        	
		})
		sync.leave(token_0)
		sync.notify(function() {
			return null;
		})
	}).catch(() => {return null});
});

// whenever a user joins a group
// get the contacts that are invited (and that haven't done STOP)
// send them a message letting them know the user has joined: user name if available else username
exports.sendGroupJoinToInvited = functions.database.ref('/groups/{group_id}/members/{member_id}').onCreate((snapshot, context) => {
	// var imagesRef = functions.storage.bucket('group_post_images');
	
	const new_member_id = context.params.member_id;
	const group_id = context.params.group_id;
	const twilio = require('twilio');
	const accountSid = functions.config().twilio.sid
	const authToken  = functions.config().twilio.token
	const client = new twilio(accountSid, authToken);
	// var imageRef = imagesRef.child(group_id).child(post_id);
	// var path = imageRef.fullPath

	return snapshot.ref.root.child('/invitedContactsForGroup/' + group_id).once('value', invited_numbers => {

		var sync = new DispatchGroup();
		var token_0 = sync.enter();
		invited_numbers.forEach(function(number_obj) {
			var token = sync.enter();
        	var number = number_obj.key;

        	// check to see that the user hasn't said STOP
        	snapshot.ref.root.child('/invitedContactsForGroup/' + group_id + '/' + number).once('value', invited_number_snapshot => {
        		// if the number has value of false, then it has unsubscribed from recieving messages
        		if (invited_number_snapshot !== null && invited_number_snapshot.val() !== null && invited_number_snapshot.val().toString() === "false") {
        			// return null;
        		}
        		else {
        			// get the number for the new_member_id if any, if matches existing number then don't send
        			snapshot.ref.root.child('/users/' + new_member_id + '/phoneNumber').once('value', new_member_phone_snapshot => {
	        			var new_member_phone = new_member_phone_snapshot.val();
						if(new_member_phone_snapshot === null || new_member_phone_snapshot.val() === null){
							new_member_phone = "+10000000000"
						}
						if (new_member_phone !== number) {
							// get the number that was used to send the first message
				        	snapshot.ref.root.child('/invitedContacts/' + number + '/' + group_id + '/twilioNumber').once('value', twilio_number_snapshot => {
				        		if (twilio_number_snapshot !== null && twilio_number_snapshot.val() !== null && twilio_number_snapshot.val() !== "0") {
									let twilio_number = twilio_number_snapshot.val().toString();


									snapshot.ref.root.child('/users/' + new_member_id + '/name').once('value', name_snapshot => {
										var name = "";
										if (name_snapshot !== null && name_snapshot.val() !== null) {
											name = name_snapshot.val().toString();
										}

										snapshot.ref.root.child('/users/' + new_member_id + '/username').once('value', username_snapshot => {
											var username = "";
											if (username_snapshot !== null && username_snapshot.val() !== null) {
												username = username_snapshot.val().toString();
											}
											snapshot.ref.root.child('/groups/' + group_id + '/groupname').once('value', groupname_snapshot => {
												var groupname = "";
												if (groupname_snapshot !== null && groupname_snapshot.val() !== null) {
													groupname = groupname_snapshot.val().toString();
												}

												if ( !validE164(number) ) {
											        throw new Error('number must be E164 format!')
											    }

											    // create the message
											    var message1 = ""

											    if (name === "") { message1 += username }
											    else { message1 += name }

											    message1 += " has joined "
											    
											    if (groupname === "") { message1 += 'the group' }
											    else { message1 += groupname.split("_-a-_").join(" ").split("_-b-_").join("'") }

												message1 += '... join with GroupRoots: https://apps.apple.com/us/app/id1525863510'

											    const postedMessage = {
											        body: message1,
											        to: number,  // Text to this number
											        from: twilio_number // From a valid Twilio number
											    }
											    client.messages.create(postedMessage)
											    sync.leave(token)
											}).catch(() => {return null});
										}).catch(() => {return null});
									}).catch(() => {return null});
								}
								else {
									// return null;
								}
							}).catch(() => {return null});
						}
        			}).catch(() => {return null});
        		}
        	}).catch(() => {return null});        	
		})
		sync.leave(token_0)
		sync.notify(function() {
			return null;
		})
	}).catch(() => {return null});
});

// https://us-central1-grouproots-1c51f.cloudfunctions.net/reply
exports.reply = functions.https.onRequest((req, res) => {
	const from = req.body['From']
	const twilio_number = req.body['To']
	const body = req.body['Body']
	var selected_group_id = ""

 	// check if contains STOP
 	// check if contains START
 	if(body.toLowerCase().indexOf("stop") !== -1){
 		// first get all the groups that the "from" number has under them,
 		// for each group check if the twilio_number is in invitedBy
 		// 		if so, then set that group as selected_group

 		// then do promise as ('/invitedContactsForGroup/' + group_id + '/' + from).set("false")

 		// now need to modify sendPostToInvited to check to see if the value for that number under the group is false

 		return admin.database().ref('/invitedContacts/' + from).once('value', groups_invited_to => {
 			if (groups_invited_to === null) {
 				res.status(500).send('');
 				return null;
 			}

			var sync = new DispatchGroup();
			var token_0 = sync.enter();
			groups_invited_to.forEach(function(group) {
				var token = sync.enter();
	        	var group_id = group.key;

	        	admin.database().ref('/invitedContacts/' + from + '/' + group_id + '/twilioNumber').once('value', twilio_number_snapshot => {
	        		var twilio_number_from_group = "";
					if (twilio_number_snapshot !== null && twilio_number_snapshot.val() !== null) {
						twilio_number_from_group = twilio_number_snapshot.val().toString();
					}
					if (twilio_number_from_group === twilio_number) {
						selected_group_id = group_id
					}
					sync.leave(token)
	        	}).catch(() => {res.status(500).send(''); return null});
	        })
	        sync.leave(token_0)
	        sync.notify(function() {
				if (selected_group_id === "") {
					res.status(500).send('');
					return null;
				}
				res.status(200).send('');
				return admin.database().ref('/invitedContactsForGroup/' + selected_group_id + '/' + from).set("false");
			})
	  	}).catch(() => {res.status(500).send(''); return null});
 	}
 	else if(body.toLowerCase().indexOf("start") !== -1){
 		// first get all the groups that the from number has under them,
 		// for each group check if the twilio_number is in invitedBy
 		// 		if so, then set that group as selected_group
 		return admin.database().ref('/invitedContacts/' + from).once('value', groups_invited_to => {
 			if (groups_invited_to === null) {
 				res.status(500).send('');
 				return null;
 			}

			var sync = new DispatchGroup();
			var token_0 = sync.enter();
			groups_invited_to.forEach(function(group) {
				var token = sync.enter();
	        	var group_id = group.key;

	        	admin.database().ref('/invitedContacts/' + from + '/' + group_id + '/twilioNumber').once('value', twilio_number_snapshot => {
	        		var twilio_number_from_group = "";
					if (twilio_number_snapshot !== null && twilio_number_snapshot.val() !== null) {
						twilio_number_from_group = twilio_number_snapshot.val().toString();
					}
					if (twilio_number_from_group === twilio_number) {
						selected_group_id = group_id
					}
					sync.leave(token)
	        	}).catch(() => {res.status(500).send(''); return null});
	        })
	        sync.leave(token_0)
	        sync.notify(function() {
				if (selected_group_id === "") {
					res.status(500).send('');
					return null;
				}
				res.status(200).send('');
				return admin.database().ref('/invitedContactsForGroup/' + selected_group_id + '/' + from).set("true");
			})
	  	}).catch(() => {res.status(500).send(''); return null});
 	}

  	
  	return null
});

// ------------------------ Fixes ------------------------

// function that sets username equal to userid in usernames if not equal
// exports.fixUsernames = functions.pubsub.schedule('every monday 02:00').timeZone('America/Los_Angeles').onRun((context) => {
// 	let promises = []
// 	return admin.database().ref('/users').once('value', users_snapshot => {
// 		var sync = new DispatchGroup();
// 		var token_0 = sync.enter();
// 		users_snapshot.forEach(function(user) {
//         	var uid = user.key;
//     		var token = sync.enter();
//     		// fetch username from user table
//     		admin.database().ref('/users/' + uid + '/username').once('value', username_snapshot => {
// 				var username = "";
// 				if (username_snapshot !== null && username_snapshot.val() !== null) {
// 					username = username_snapshot.val().toString();
// 				}

// 				// fetch uid from username from user table
// 				admin.database().ref('/usernames/' + username).once('value', user_from_username_snapshot => {
// 					var user_from_username = "";
// 					if (user_from_username_snapshot !== null && user_from_username_snapshot.val() !== null) {
// 						user_from_username = user_from_username_snapshot.val().toString();
// 					}
// 					// username entree in usernames table is empty or isn't equal to user who it actually belongs to
// 					// add promise setting it
// 					if (user_from_username === "" || user_from_username !== uid) {
// 						promises.push(admin.database().ref('/usernames').child(username).set(uid));
// 					}
// 					sync.leave(token)
// 				}).catch(() => {console.log("err1"); return null});
// 			}).catch(() => {console.log("err2"); return null});
//     	});
// 		sync.leave(token_0)
// 		sync.notify(function() {
// 			console.log("returning")
// 			if (promises.length === 0) {
// 				return null;
// 			}
// 			return Promise.all(promises);
// 		})
//   	}).catch(() => {console.log("err3"); return null});
// });



// ------------------------ Notifications ------------------------

const runtimeOpts = {
  timeoutSeconds: 540
  // memory: '1GB'
}

// for all users
// if user lastVisited is greater than 5 days, then continue
// if there is a post that the user hasn't seen yet, then continue
// get the user's token
// send the notification for the post and set lastVisited time ot current time
// exports.sendSubscriptionPostNotifications = functions.pubsub.schedule('every day 09:00').timeZone('America/Los_Angeles').runWith(runtimeOpts).onRun((context) => {
exports.sendSubscriptionPostNotifications = functions.pubsub.schedule('every day 09:00').timeZone('America/Los_Angeles').onRun((context) => {
	return admin.database().ref('/users').once('value', users_snapshot => {
		var current_time = parseFloat(Date.now()/1000) // in seconds
		users_snapshot.forEach(function(user) {
        	var uid = user.key;
    		admin.database().ref('/lastOpenedApp/' + uid).once('value', last_opened_snapshot => {
        		var last_opened_app =  1602658042
        		if (last_opened_snapshot !== null && last_opened_snapshot.val() !== null) {
					last_opened_app = parseFloat(last_opened_snapshot.val());
				}

				// current_time - last_opened_app = number of seconds between
				// convert number of seconds to nearest days
				// continue only on days % 5 === 0 and days !== 0
				let num_seconds = current_time - last_opened_app
				let num_days = Math.floor(num_seconds / 86400)

				if (num_days !== 0 && num_days % 5 === 0) {

					// retrieve the groups the user is subscribed to
					// for each group
					// check if they've seen the latest post
					// send notification for that and set a boolean to true to stop checking the other groups
					admin.database().ref('/groupsFollowing/' + uid).once('value', groups_following_snapshot => {
						var groups_with_new_posts = []

						let sync = new DispatchGroup();
						var token_0 = sync.enter();
						groups_following_snapshot.forEach(function(group) {
							var token = sync.enter();
							var group_id = group.key;

							// if the lastPostedDate of the group is more recent than the last time the app was opened
							// then continue
							admin.database().ref('/groups/' + group_id + '/lastPostedDate').once('value', last_post_date => {
								var group_post_date = 0
								if (last_post_date !== null && last_post_date.val() !== null) {
									group_post_date = parseFloat(last_post_date.val());
								}
								if(group_post_date > last_opened_app){
									groups_with_new_posts.push(group_id)
								}
								sync.leave(token)
							}).catch(() => {return null});
						})
						sync.leave(token_0)

				        sync.notify(function() {
				        	if (groups_with_new_posts.length > 0) {
				        		shuffle(groups_with_new_posts);
				        		admin.database().ref('/groups/' + groups_with_new_posts[0] + '/groupname').once('value', groupname_snapshot => {
									var groupname = "";
									if (groupname_snapshot !== null && groupname_snapshot.val() !== null) {
										groupname = groupname_snapshot.val().toString().split("_-a-_").join(" ").split("_-b-_").join("'");
									}

									// retrieve the token for the user
									admin.database().ref('/users/' + uid + '/token').once('value', token_snapshot => {
										var user_token = token_snapshot.val();

										var message = ""
										if (groups_with_new_posts.length === 1) {
											if (groupname === "") {
												message = "A group you're subscribed to has recently posted"
											}
											else {
												message = 'Group "' + groupname + '" has recently posted'
											}
										}
										else if (groups_with_new_posts.length > 1) {
											if (groupname === "") {
												message = "Groups you're subscribed to have recently posted"
											}
											else {
												message = 'Group "' + groupname + '" and other groups have recently posted'
											}
											
										}
										const payload = {
											notification: {
												body: message
											}
										};
										admin.messaging().sendToDevice(user_token, payload)
										// admin.messaging().sendToDevice("cFek9UsXGk91r5rSv8gUJ9:APA91bGrGlzleyoA0zsbcw2vKHYnP-RZk5bEsz-0f9ArHgAax6LobtKvbvQZCL0K9U5Fvyb5jz-TfNr5NMBoIn4BC5bip8QAg_99t_pJ3QgOLUsGytAx52Wt7dKzB5qk2dQjM0YFBc-Z", payload)
									})
								}).catch(() => {return null});
				        	}
						})

					}).catch(() => {return null});
				}
        	}).catch(() => {return null});
    	});
  	}).catch(() => {return null});
});

// https://us-central1-grouproots-1c51f.cloudfunctions.net/test_notif
exports.test_notif = functions.https.onRequest((req, res) => {
	const payload = {
		notification: {
			title: "test title",
			body: "test message", // has no badge
			click_action: "1"
		}
	};
	// admin.messaging().sendToDevice(user_token, payload)
	admin.messaging().sendToDevice("cFek9UsXGk91r5rSv8gUJ9:APA91bGrGlzleyoA0zsbcw2vKHYnP-RZk5bEsz-0f9ArHgAax6LobtKvbvQZCL0K9U5Fvyb5jz-TfNr5NMBoIn4BC5bip8QAg_99t_pJ3QgOLUsGytAx52Wt7dKzB5qk2dQjM0YFBc-Z", payload)
});

exports.new_post = functions.https.onRequest((req, res) => {
	const payload = {
		notification: {
			title: "test title",
			body: "test message", // has no badge
			click_action: "new_post"
		}
	};
	// admin.messaging().sendToDevice(user_token, payload)
	admin.messaging().sendToDevice("cFek9UsXGk91r5rSv8gUJ9:APA91bGrGlzleyoA0zsbcw2vKHYnP-RZk5bEsz-0f9ArHgAax6LobtKvbvQZCL0K9U5Fvyb5jz-TfNr5NMBoIn4BC5bip8QAg_99t_pJ3QgOLUsGytAx52Wt7dKzB5qk2dQjM0YFBc-Z", payload)
});

exports.open_group = functions.https.onRequest((req, res) => {
	const payload = {
		notification: {
			title: "test title",
			body: "test message", // has no badge
			click_action: "open_group_-MFNlTzu2pnegCPFqMyz"
		}
	};
	// admin.messaging().sendToDevice(user_token, payload)
	admin.messaging().sendToDevice("cFek9UsXGk91r5rSv8gUJ9:APA91bGrGlzleyoA0zsbcw2vKHYnP-RZk5bEsz-0f9ArHgAax6LobtKvbvQZCL0K9U5Fvyb5jz-TfNr5NMBoIn4BC5bip8QAg_99t_pJ3QgOLUsGytAx52Wt7dKzB5qk2dQjM0YFBc-Z", payload)
});

exports.open_group_requestors = functions.https.onRequest((req, res) => {
	const payload = {
		notification: {
			title: "test title",
			body: "test message", // has no badge
			click_action: "open_group_member_requestors_-MFNlTzu2pnegCPFqMyz"
		}
	};
	// admin.messaging().sendToDevice(user_token, payload)
	admin.messaging().sendToDevice("cFek9UsXGk91r5rSv8gUJ9:APA91bGrGlzleyoA0zsbcw2vKHYnP-RZk5bEsz-0f9ArHgAax6LobtKvbvQZCL0K9U5Fvyb5jz-TfNr5NMBoIn4BC5bip8QAg_99t_pJ3QgOLUsGytAx52Wt7dKzB5qk2dQjM0YFBc-Z", payload)
});

exports.open_group_sub_requestors = functions.https.onRequest((req, res) => {
	const payload = {
		notification: {
			title: "test title",
			body: "test message", // has no badge
			click_action: "open_group_subscribe_requestors_-MFNlTzu2pnegCPFqMyz"
		}
	};
	// admin.messaging().sendToDevice(user_token, payload)
	admin.messaging().sendToDevice("cFek9UsXGk91r5rSv8gUJ9:APA91bGrGlzleyoA0zsbcw2vKHYnP-RZk5bEsz-0f9ArHgAax6LobtKvbvQZCL0K9U5Fvyb5jz-TfNr5NMBoIn4BC5bip8QAg_99t_pJ3QgOLUsGytAx52Wt7dKzB5qk2dQjM0YFBc-Z", payload)
});

exports.open_post = functions.https.onRequest((req, res) => {
	const payload = {
		notification: {
			title: "test title",
			body: "test message", // has no badge
			click_action: "open_post_-MGQvIvjQygTS6arDQJi_-MFNlTzu2pnegCPFqMyz"
		}
	};
	// admin.messaging().sendToDevice(user_token, payload)
	admin.messaging().sendToDevice("cFek9UsXGk91r5rSv8gUJ9:APA91bGrGlzleyoA0zsbcw2vKHYnP-RZk5bEsz-0f9ArHgAax6LobtKvbvQZCL0K9U5Fvyb5jz-TfNr5NMBoIn4BC5bip8QAg_99t_pJ3QgOLUsGytAx52Wt7dKzB5qk2dQjM0YFBc-Z", payload)
});



// * don't do this one *
// don't do it because it makes users have to choose a group. It should be suggested to them already like reminderToPostNotificationForGroup.
// for all users
// if user hasn't posted in 15 days send message to post
// message: You haven't posted in a while. Post to a group
// - "Remember that one time?" Share a throwback with one of your groups
// - Do something new? Share a picture with one of your groups
// - Recent get together? Share a picture with your groups
// - Make your curated group profile better. Share a group picture
// - Something about how post will be sent to those invited too... maybe
// - You haven't posted to _group_ in a while. Post a funny picture of _user1_ or _user2_
// exports.reminderToPostNotificationForUser = functions.pubsub.schedule('every day 19:00').timeZone('America/Los_Angeles').onRun((context) => {

// });

// for all groups
// if no one in the group has posted in the last 7 days
// randomly select someone from the group to send a message to remind to post
// message: You haven't posted to [_group_ || your group with _user_ and _user_] in a while. Post something to keep your group's profile alive
// !!!!!!!!!
// exports.reminderToPostNotificationForGroup = functions.pubsub.schedule('every day 18:00').timeZone('America/Los_Angeles').runWith(runtimeOpts).onRun((context) => {
// 	var groupname = ""
// 	var messages = [
// 		"\"Remember when...?\" Share a funny throwback to " + groupname + "!",
// 		"\"Remember when...?\" Remind your friends in " + groupname + " with something funny!",
// 		"Do something new? Share a picture with " + groupname + "!",
// 		"You haven't posted to " + groupname + " in a while. Post something to keep your group's profile alive!",
// 		"Help make " + groupname "'s profile better. Share a group picture!",
// 		"You haven't posted to " + groupname + " in a while. Post something to show your followers!"
// 	]
// });

// reminder to follow people (might need new notification opener -> search tab)
// Follow user1, user2, and others to have their groups appear in your feed 
// !!!!!!!!!
// exports.reminderToFollowUsers = functions.pubsub.schedule('every day 19:00').timeZone('America/Los_Angeles').runWith(runtimeOpts).onRun((context) => {
// 	var user1 = ""
// 	var user2 = ""
// 	var message = "Follow " + user1 + ", " + user2 + ", and others to have their groups appear in your feed!"

// });

// exports.reminderToFollowBack = functions.pubsub.schedule('every day 19:00').timeZone('America/Los_Angeles').runWith(runtimeOpts).onRun((context) => {
// 	var user = ""
// 	var message = user + "follows you. Follow him back!"
// }); 




// ------------------------ Promotion stuff -----------------------


// When join the group:
// 	get the school the group is in and continue only if it is in a school
// 	if less than 10 groups in the groupsWithMultipleMembers for school:
// 		if group is not in groupsWithMultipleMembers:
// 			if less than 2 groups in groupsCompletedPromo for school:
// 				get the other member (first member) and add to rewardUser with value of 50
// 			else:
// 				get the other member (first member) and add to rewardUser with value of 20
// 			add group to groupsWithMultipleMembers for school
// 			add joining_user to rewardUser with value of 20
// 		else:
// 			if less than 4 members in the group:
// 				add joining_user to rewardUser with value of 20

// exports.joinGroupInSchoolPromo = functions.database.ref('/groups/{groupId}/members/{uid}').onCreate((snapshot, context) => {

// 	const joining_member = context.params.uid;
// 	const group_id = context.params.groupId;

// 	// get the school the group is in
// 	return snapshot.ref.root.child('/groups/' + group_id + "/selectedSchool").once('value', selected_school_snapshot => {
// 		if (selected_school_snapshot === null || selected_school_snapshot.val() === null || selected_school_snapshot.val() == "") {
// 			return null;
// 		}
// 		var selected_school = selected_school_snapshot.val()

// 		// get groupsWithMultipleMembers for the school
// 		return snapshot.ref.root.child('/schools/' + selected_school + "/groupsWithMultipleMembers").once('value', muliple_member_groups_snapshot => {
// 			var continue_with_promo = false
// 			if (muliple_member_groups_snapshot === null || muliple_member_groups_snapshot.val() === null) {
// 				continue_with_promo = true
// 			}
// 			else {
// 				var num_groups = 0;
// 				muliple_member_groups_snapshot.forEach(function(member) {
// 					num_groups += 1;
// 				})
// 				if (num_groups < 10) {
// 					continue_with_promo = true
// 				}
// 			}

// 			if (continue_with_promo) {

// 			}
// 			else {
// 				return null;
// 			}	
// 		})
// 	})


	
// 	// get the number of groups in the school
// 	return snapshot.ref.root.child('/groupsInSchoolCount/' + selected_school).once('value', num_groups_snaphshot => {
// 		var num_groups = parseInt(num_groups_snaphshot.val());

// 		// get the first user in the group
	// 	return snapshot.ref.root.child('/groups/' + group_id + '/members/').once('value', members_snapshot => {
	// 	var sync = new DispatchGroup();
	// 	var token_0 = sync.enter();

	// 	members_snapshot.forEach(function(member) {
	// 		var member_id = member.key;
	// 		// return snapshot.ref.root.child('/schools/' + selected_school + '/groupCreators/' + member_id).set(false)


	// 		// don't have this
	// 		// if(num_groups < 2) {
	// 		// 	// return snapshot.ref.root.child('/schools/' + selected_school + '/groupCreators/' + member_id).set(false)
	// 		// }
	// 		// else if(num_groups < 10) {

	// 		// }
	// 		else {
	// 			return null;
	// 		}
	// 	})
	// 	// create school -> group_id
	// 	// return snapshot.ref.root.child('/schools/' + selected_school + '/groups/' + group_id).set(creation_time);
	// }).catch(() => {return null});
// });



exports.updateUserAmountOnPromo = functions.database.ref("/promos/{schoolName}/postedToInsta/{username}").onCreate((snapshot, context) => {
	const username = context.params.username;
	const school_name = context.params.schoolName;

	var promises = []
	
	// get the number of groups in the school
	return admin.database().ref('/promos/' + school_name + "/currentInstaPayout").once('value', current_payout_snapshot => {
		var payout = 0

		if (current_payout_snapshot === null || current_payout_snapshot.val() === null) {
			// it's null so set it to 50
			payout = 50
			promises.push(admin.database().ref('/promos/' + school_name + '/currentInstaPayout/').set(50));
			promises.push(admin.database().ref('/promos/' + school_name + '/isActive').set(true));
		}
		else {
		 	payout = parseInt(current_payout_snapshot.val());
		}
		promises.push(admin.database().ref('/promos/' + school_name + '/postedToInsta/' + username + "/amount").set(payout));

		// get postedToInsta for the school and look at its count
		return admin.database().ref('/promos/' + school_name + '/postedToInsta').once('value', posted_snapshot => {
			var count = 0;
			posted_snapshot.forEach(function(member) {
				count += 1;
			})

			if ( count < 4 ) {
				promises.push(admin.database().ref('/promos/' + school_name + '/currentInstaPayout/').set(50));
			}
			else if (count < 14) {
				promises.push(admin.database().ref('/promos/' + school_name + '/currentInstaPayout/').set(20));
			}
			else if (count < 41) {
				promises.push(admin.database().ref('/promos/' + school_name + '/currentInstaPayout/').set(10));
			}
			else {
				promises.push(admin.database().ref('/promos/' + school_name + '/isActive').set(false));
			}
			if (promises.length === 0) {
				return null;
			}
			return Promise.all(promises);
		}).catch(() => {return null});

	}).catch(() => {return null});
});


// ------------------- Timer Posts -------------------

exports.addTempPostToBucket = functions.database.ref('/posts/{group_id}/{post_id}/isTempPost').onCreate((snapshot, context) => {	
	const post_id = context.params.post_id;
	const group_id = context.params.group_id;

	// check if temp post exists and has value of true
	if (snapshot !== null && snapshot.val() !== null && snapshot.val() === true) {
		var post_date = Date.now()
		var hour = (new Date(post_date)).getHours()

		// set the group_id and post_id to the bucket
		return snapshot.ref.root.child('/timerPostExpirations/' + hour + '/' + group_id + '/' + post_id).set(post_date/1000)
	}
});

exports.deleteTempPosts = functions.pubsub.schedule('0 * * * *').timeZone('America/Los_Angeles').onRun((context) => {
	var post_date = Date.now()
	var hour = (new Date(post_date)).getHours()
	console.log("deleting temp posts")
	console.log(hour)

	const promises = []

	// get all the groups,
	//		get all the post_ids in the group
	//			remove the group_id/post_id in posts
	return admin.database().ref('/timerPostExpirations/' + hour).once('value', groups_snapshot => {
		var sync = new DispatchGroup();
		var token_0 = sync.enter();
		var num_groups = 0
		console.log("checking timerPostExpirations to find groups")
		groups_snapshot.forEach(function(group) {
			num_groups += 1;
			var token = sync.enter();
			var group_id = group.key;
			console.log("in group " + group_id)
			return admin.database().ref('/timerPostExpirations/' + hour + '/' + group_id).once('value', posts_snapshot => {
				posts_snapshot.forEach(function(post) {
					var post_id = post.key;
					console.log("deleting post " + post_id)
					promises.push(admin.database().ref('/posts/' + group_id + '/' + post_id).remove())
					sync.leave(token)
				})
			}).catch(() => {return null});
		})
		
		sync.leave(token_0)
		sync.notify(function() {
			if ( num_groups > 0 ){
				promises.push(admin.database().ref('/timerPostExpirations/' + hour).remove())
				return Promise.all(promises);
			}
			return null;
		})
	}).catch(() => {return null});
});


























