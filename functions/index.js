const functions = require('firebase-functions'); // coud functions for firebase sdk to create cloud functions and setup triggers
const admin = require('firebase-admin'); // access to ifrebase realtime database
admin.initializeApp();

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
                    console.log('group ' + id + ' completed')
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
            console.log('group ' + id + ' enter ' + token)
            return token
        }

        this.leave = function (token) {
            if(!token) throw new Error("'token' must be the value earlier returned by '.enter()'")
            tokens.delete(token)
            console.log('group ' + id + ' leave '+token)
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
        	var post_time = parseInt(Math.floor(Date.now()/1000))
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
			post_date = parseInt(post_date)
			let is_subscribed = (in_subscriber_snapshot.val() !== null);
			if (is_subscribed) {
				return snapshot.ref.root.child('/groupsFollowing/' + new_member_id + '/' + group_id + '/autoSubscribed').set("false"); // not auto subscriber if in group
			}
			else {
				const promises = [];
				let promise_followers = snapshot.ref.root.child('/groupFollowers/' + group_id + '/' + new_member_id).set(1);
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
				post_date = parseInt(post_date.toString()).toString()
				const promises = [];
				var sync = new DispatchGroup();
				var token_0 = sync.enter();
				new_member_followers.forEach(function(member_follower) {
					var member_follower_id = member_follower.key;
					var token = sync.enter()
					snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id).once('value', in_subscriber_snapshot => {
						let is_subscribed = (in_subscriber_snapshot.val() !== null);
						if (is_subscribed) {
							// if the user is already subscribed to the group, 
							// just add uid to membersFollowing of the group for new_member_follower_id				
							let promise = snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id + '/membersFollowing/' + new_member_id).set(1);
							promises.push(promise);
							sync.leave(token);
							// tested with 1 follower
						}
						else {
							if (is_private) {
								// add to groupFollowPending with autoSubscribed: true... what if they were already in groupFollowPending with autoSubscribed as false?
								// add new_member_id to membersFollowing for groupFollowPending of new_member_follower_id
	
								var lower_sync = new DispatchGroup();
								var lower_token = lower_sync.enter();
								snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + member_follower_id).once('value', in_follow_pending_snapshot => {
									let is_in_follow_pending = (in_follow_pending_snapshot.val() !== null);
									if (is_in_follow_pending) {
										// do nothing
									}
									else {
										// add user to groupFollowPending with autoSubscribed: true
										let promise = snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + member_follower_id + '/autoSubscribed').set(true);
										promises.push(promise);
									}
									lower_sync.leave(lower_token);
								});						

								lower_sync.notify(function() {
                   	 				let promise = snapshot.ref.root.child('/groupFollowPending/' + group_id + '/' + member_follower_id + '/membersFollowing/' + new_member_id).set(1);
									promises.push(promise);
									sync.leave(token);
                				})
                				// tested with 1 follower
							}
							else {
								// add to followers/following and autoFollow (since group is public would have auto became subscribed if manually clicked subscribe button)
								// add new_member_id to membersFollowing for the group

								let promise_followers = snapshot.ref.root.child('/groupFollowers/' + group_id + '/' + member_follower_id).set(1);
								let promise_following = snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id + '/lastPostedDate').set(post_date);
								let promise_following_auto = snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id + '/autoSubscribed').set("true");
								let promise_membersFollowing = snapshot.ref.root.child('/groupsFollowing/' + member_follower_id + '/' + group_id + '/membersFollowing/' + new_member_id).set(1);
								promises.push(promise_followers);
								promises.push(promise_following);
								promises.push(promise_following_auto);
								promises.push(promise_membersFollowing);
								sync.leave(token);
								// tested with 1 follower
							}
						}	
					});
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
			var token = sync.enter()
			snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id).once('value', in_subscriber_snapshot => {
				let is_subscribed = (in_subscriber_snapshot.val() !== null);
				if (is_subscribed) {
					snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id + '/autoSubscribed').once('value', auto_subscribed => {
						if (auto_subscribed !== null && auto_subscribed.val() !== null){
							var is_auto_subscribed = auto_subscribed.val()
							if (is_auto_subscribed) {
								snapshot.ref.root.child('/groupsFollowing/' + follower_id + '/' + group_id + '/membersFollowing').once('value', membersFollowing => {
									if (membersFollowing.length === 0 || membersFollowing === null){
										// send notification of unsubscribe_request
										var creation_time = parseInt(Math.floor(Date.now()/1000))
										var values = {
											type: "unsubscribeRequest",
											group_id: group_id,
											creationDate: creation_time
										}
										let promise = snapshot.ref.root.child('notifications/' + follower_id).push(values);
										promises.push(promise);
										sync.leave(token);
									}
								})
							}
						}
					})
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
					var creation_time = parseInt(Math.floor(Date.now()/1000))
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
exports.removeGroupSubscribersOnProfileHide = functions.database.ref('/users/{user_hiding}/groups/{group_id}/hidden').onCreate((hidden_snapshot, context) => {
	const user_hiding = context.params.user_hiding;
	const group_id = context.params.group_id;
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
												if (membersFollowing !== null && membersFollowing.length === 1){
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
})

exports.removeGroupSubscribersOnProfileHideUpdate = functions.database.ref('/users/{user_hiding}/groups/{group_id}/hidden').onUpdate((hidden_snapshot, context) => {
	const user_hiding = context.params.user_hiding;
	const group_id = context.params.group_id;
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
												if (membersFollowing !== null && membersFollowing.length === 1){
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
})

// exports.updateGroupFollowersCountOnSubscribe

// exports.updateGroupFollowersCountOnUnSubscribe

// exports.updateUserFollowersCountOnFollow

// exports.updateUserFollowersCountOnUnfollow

// exports.update






















