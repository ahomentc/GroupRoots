// add your adjectives and swears...
var sadjectives = ["absolute", "complete", "complete and utter", "relentless", "irritating", "annoying", "hateful", "grovelling", "stupid", "sad"],
    swears = ["prick", "bellend", "idiot", "fool", "bore", "piece", "sh*thead", "a***hole", "w*nker", "tw*t", "spanner", "tool", "c*ckend", "waste of skin", "waste of space", "human being"],
    appyjectives = ["lovely", "beautiful", "magnificent", "wonderful", "charming", "gorgeous", "delightful", "thoughful"],
    comps = ["person", "friend", "specimen", "human being", "sweetheart"];

var resultSad = document.querySelector(".resultSad"),
    resultHappy = document.querySelector(".resultHappy");

// init
updateSentences();

function getSentence (adjs, nouns) {
	var adjective = adjs[Math.floor(Math.random() * adjs.length)],
		noun = nouns[Math.floor(Math.random() * nouns.length)];

	var isVowel = /^[aeiou]/i.test(adjective);

	return ["Andrei is ", isVowel ? "an " : "a ", adjective, " ", noun, "."].join("");
}

function updateSentences () {
  resultSad.textContent = getSentence(sadjectives, swears);

  resultHappy.textContent = getSentence(appyjectives, comps); 
}

// button listener
document.querySelector(".go").addEventListener("click", updateSentences, false);

