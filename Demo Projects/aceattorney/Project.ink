VAR selected_profile = 0
VAR selected_evidence = 0
VAR seen_cindy_profile = 0
VAR seen_autopsy = 0
VAR profile_count = 0
VAR evidence_count = 0
VAR selected_crossexamination = 0
VAR can_present_evidence = false
VAR presented_evidence = -1

=== StartUp ===
~ yres = 172
~ Panel = pic_title
~ wait = Wait_ForJoystick
~ Panel = null

=== start_case1
~ selected_profile = 0
~ seen_cindy_profile = 0
~ seen_autopsy = 0
~ selected_evidence = 0
~ selected_crossexamination = 0
~ profile_count = 4
~ evidence_count = 2
~ can_present_evidence = false
~ presented_evidence = -1

~ level = intro0
~ camera_y = 384 - 212
~ forcefadeout = true
Episode 1:<br>The First Turnabout
~ forcefadeout = false
~ wait = Wait_For2Seconds
*gasp*... *gasp*...

== intro0_loop0
{ camera_y > 0 :
 ~ camera_y = camera_y - 2
 ~ wait = 1
 -> intro0_loop0
}

~ wait = Wait_For2Seconds
~ forcefadeout = true
~ camera_x = 256+16
~ camera_y = 0
~ forcefadeout = false
~ wait = Wait_For2Seconds
Damnit! ...Why me?
~ forcefadeout = true
I can't get caught... Not like this!
~ camera_y = 396
~ forcefadeout = false

== intro0_loop1
{ camera_y > 224 :
 ~ camera_y = camera_y - 2
 ~ wait = 1
 -> intro0_loop1
}
I-I've gotta find someone to pin this on...
~ camera_x = 34*16
~ camera_y = 0
~ wait = 25
~ camera_y = 14*16
~ wait = 25
~ camera_x = 51*16
~ camera_y = 0
Someone like...
~ camera_y = 14*16
~ wait = 25
~ camera_y = 0
I'll make it look like... HE did it!

=== lobby_start ===
~ level = lobby
~ forcefadeout = true
~ talkpad_textdelay = 2
August 3, 9:47 AM<br>District Court Defendant Lobby No. 2
~ talkpad_textdelay = 1
~ forcefadeout = false
-> lobby_empty ->
Phoenix: (Boy am I nervous!)
Mia: Wright!
-> lobby_mia_smile1 ->
Phoenix: Oh, h-hiya, Chief.
Mia: Whew, I'm glad I made it on time.
Mia: Well, I have to say Phoenix, I'm impressed!
-> lobby_mia_smile2 ->
Mia: Not everyone takes on a murder trial right off the bat like this.
Mia: It says a lot about you... and your client as well.
Phoenix: Um... thanks.
Phoenix: Actually, it's because I owe him a favor.
-> lobby_mia_curious ->
Mia: A favor?
Mia: You mean, you knew the defendant before this case?
Phoenix: Yes.
Phoenix: Actually, I kind of owe my current job to him.
Phoenix: He's one of the reasons I became an attorney.
-> lobby_mia_smile2 ->
Mia: Well, that's news to me!
-> lobby_mia_smile1 ->
Phoenix: I want to help him out any way I can!
Phoenix: I just... really want to help him. I owe him that much.
-> lobby_mia_curious ->
???: (It's over!)
???: (My life, everything, it's all over!)
Mia: ...
Mia: Isn't that your client screaming over there?
-> lobby_mia_smile1 ->
Phoenix: Yeah... that's him.
???: (Death! Despair! Ohhhh!)
-> lobby_mia_curious ->
???: (I'm gonna do it, I'm gonna die!!!)
Mia: It sounds like he wants to die...
-> lobby_mia_smile2 ->
Phoenix: Um, yeah. *sigh*
-> lobby_larry_crying ->
Butz: Nick!!!
Phoenix: Hey. Hey there, Larry.
-> lobby_larry_nervous ->
Butz: Dude, I'm so guilty!! Tell them I'm guilty!!!
Butz: Gimmie the death sentence! I ain't afraid to die!
Phoenix: What!? What's wrong, Larry?
-> lobby_larry_crying ->
Butz: oh, it's all over... I... I'm finished. Finished!
Butz: I can't live in a world without her! I can't!
Butz: Who... who took her away from me, Nick? Who did this?
Butz: Aww, Nick, ya gotta tell me! Who took my baby away!?
Phoenix: (Hmm... the person responsible for your girlfriend's death?)
Phoenix: (The newspaper say it was you...)
~ forcefadeout = true
Phoenix: My name is Phoenix Wright.
Phoenix: Here's the story:
Phoenix: My first case is a fairly simple one.
-> lobby_cindy ->
~ forcefadeout = false
Phoenix: A young woman was killed in her apartment.
Phoenix: The guy they arrested was the unlucky sap dating her:
~ forcefadeout = true
-> lobby_larry_nervous ->
~ forcefadeout = false
Phoenix: Larry Butz... my best friend since grade school.
Phoenix: Our school had a saying: "When something smells, it's usually the Butz."
-> lobby_larry_crying ->
Phoenix: In the 23 years I've known him, it's usually been true.
Phoenix: He has a knack for getting himself in trouble.
Phoenix: One thing I can say though: it's usually not his fault. He just has terrible luck.
~ forcefadeout = true
Phoenix: But I know better than anyone that he's a good guy a heart.
Phoenix: That and I owe him one. Which is why I took the case... to clear his name.
Phoenix: And that's just what I'm going to do!

=== courtroom ===
~ level = court
~ forcefadeout = true
~ talkpad_textdelay = 2
August 3, 10:00 AM<br>District Court Coutroom No. 2
~ talkpad_textdelay = 1
~ forcefadeout = false
~ wait = Wait_For1Second
-> court_gavel ->
-> court_judge_normal ->
Judge: The court is now in session for the trial of Mr. Larry Butz.
-> court_payne_normal ->
Payne: The prosecution is ready, Your Honor.
-> court_phoenix_normal ->
Phoenix: The, um, defense is ready, Your Honor.
-> court_judge_thinking ->
Judge: Ahem.
-> court_judge_warn ->
Judge: Mr. Wright?
Judge: This is your first trial, is it not?
-> court_phoenix_normal ->
Phoenix: Y-Yes, Your Honor. I'm, um, a little nervous.
-> court_judge_warn ->
Judge: Your contact during this trial will decide the fate of your client.
Judge: Murder is a serious charge. For your client's sake, I hope you can control your nerves.
-> court_phoenix_normal ->
Phoenix: Thank... thank you, Your Honor.
-> court_judge_warn ->
Judge: ...
Judge: Mr. Wright, given the circumstances...
Judge: I think we should have a test to ascertain your readiness.
-> court_phoenix_normal ->
Phoenix: Yes, Your Honor.
-> court_phoenix_nervous ->
Phoenix: (Gulp... Hands shaking... Eyesight... fading...)
-> court_judge_warn ->
Judge: The test will consist of a few simple questions. Answer them clearly and concisely.

== choose_defendant
-> court_judge_warn ->
Judge: Please state the name of the defendant in this case.
+ Phoenix Wright -> defendant_phoenixwright
+ Larry Butz -> defendant_larrybutz
+ Mia Fey -> defendant_miafey
-> choose_defendant

== defendant_phoenixwright
-> court_phoenix_thinking ->
Phoenix: Um... the defendant... is me, right?
-> court_mia_sad ->
Mia: Wright! Have you completely lost your mind? Focus!
-> court_mia_shocked ->
Mia: The defenfant is the person on trial!
Mia: You're his lawyer!
-> court_mia_disappointed ->
Phoenix: Um, er, eh? Oh yeah, right! Eh heh heh.
Mia: This is no laughing matter!
Mia: You did pass the bar, didn't you?
-> repeat_defendant_answer

== defendant_miafey
-> court_phoenix_thinking ->
Phoenix: The, um, defendant? That's... er... Mia Fey?
-> court_mia_disappointed ->
Mia: Wrong, Wright. Look, I have to leave.
Mia: I have to go home. I'm... I'm expecting a delivery.
Phoenix: Aw, c'mon Chief. There's no need to be going so soon, is there?
-> court_mia_shocked ->
Mia: Wright!
Mia: Listen: the defendant is the one on trial--your client!
-> court_mia_disappointed ->
Mia: I mean, that's about as basic as you can get!
Phoenix: (I put my foot in it this time! I've got to relax!)
== repeat_defendant_answer
-> court_judge_warn ->
Judge: Sorry, I couldn't hear your answer. I'll ask once more:
-> choose_defendant

== defendant_larrybutz
-> court_phoenix_thinking ->
Phoenix: The defendant? Well, that's Larry Butz, Your Honor.
-> court_judge_normal ->
Judge: Correct.
Judge: Just keep your wits about you and you'll do fine.
Judge: Next Question:
-> court_judge_warn ->
Judge: This is a murder trial. Tell me - 
Judge: What's the victim's name?
-> court_phoenix_normal ->
Phoenix: (Whew, I know this one! Glad I read the case report cover to cover so many times.)
-> court_phoenix_thinking ->
Phoenix: (It's... wait... Uh-oh!)
-> court_phoenix_nervous ->
Phoenix: (No... no way! I forgot! I'm drawing a total blank here!)
-> court_mia_shocked ->
Mia: Phoenix! Are you absolutely SURE you're up to this?
Mia: You don't even know the victim's name!?
-> court_mia_disappointed ->
Phoenix: Oh, the victim! O-Of course I know the victim's name!
Phoenix: I, um, just forgot. ... Temporarily
Mia: I think I feel a migraine coming on.
-> court_mia_serious ->
Mia: Look, the victim's name is listed in the Court Record.
Mia: Just select Court Record to check it, okay?
-> court_mia_disappointed ->
Mia: Remember to check it often. Do it for me, please. I'm begging you.

== choose_victim
-> court_judge_warn ->
Judge: Let's hear your answer. Who is the victim in this case.
+ Mia Fey -> victim_miafey
+ Cinder Block -> victim_cinderblock
+ {seen_cindy_profile} Cindy Stone -> victim_cindystone
+ View Court Record -> victim_courtrecord

== victim_miafey
-> court_phoenix_thinking ->
Phoenix: Um... Mia Fey?
-> court_mia_shocked ->
Mia: W-W-What!? How can I be the victim!?
-> court_mia_disappointed ->
Phoenix: Oh! Right! Sorry! I, er, it was the first name that popped into my head, and--
-> court_mia_serious ->
Mia: The Court Record! Remember to use it when you are in a pinch.
-> court_judge_warn ->
Judge: Let me ask that one again:
-> choose_victim

== victim_cinderblock
-> court_phoenix_thinking ->
Phoenix: Oh, um, wasn't it Ms. Block? Ms. Cinder Block?
-> court_judge_warn ->
Judge: The person in question was a victim of murder, not ill- conceived naming, Mr. Wright.
-> court_mia_disappointed ->
Mia: Wright?
Mia: If you forget something, just use the Court Record to help you remember.
-> court_mia_serious ->
Mia: A mistake in court could cost you the case.
-> court_judge_warn ->
Judge: I'll ask you again:
-> choose_victim

== victim_courtrecord
-> open_court_record ->
-> choose_victim

== victim_cindystone
-> court_phoenix_normal ->
Phoenix: Um... the victim's name is Cindy Stone.
-> court_judge_normal ->
Judge: Correct.
Judge: Now, tell me, what was the cause of death?


== choose_causeofdeath
-> court_judge_warn ->
Judge: She died because she was...?
+ Poisoned -> causeofdeath_poisioned
+ Strangled -> causeofdeath_strangled
+ {seen_autopsy} Hit with a blunt object -> causeofdeath_blunt
+ View Court Record -> causeofdeath_courtrecord
-> end

== causeofdeath_poisioned
-> court_phoenix_thinking ->
Phoenix: Oh, right! Wasn't she, um, poisioned by er... poison?
-> court_judge_shocked ->
Judge: You're asking me?
-> court_mia_disappointed ->
Phoenix: Um... Chief! Help me out!
Mia: Check the court record. Remember?
Phoenix: (Geez. Give a guy a break!)
-> court_judge_warn ->
Judge: Let me ask again.
-> choose_causeofdeath

== causeofdeath_strangled
-> court_phoenix_thinking ->
Phoenix: Right... she was strangled, wasn't she?
-> court_mia_disappointed ->
Mia: Please tell me that was you talking to yourself.
-> court_judge_warn ->
Judge: If you wish to hang yourself Mr. Wright, you're welcome to, but not inside my courtroom.
Judge: I suppose there's nothing to do but give you another try:
-> choose_causeofdeath

== causeofdeath_courtrecord
-> open_court_record ->
-> choose_causeofdeath

== causeofdeath_blunt
-> court_phoenix_normal ->
Phoenix: She was struck once, by a blunt object.
-> court_judge_normal ->
Judge: Correct.
Judge: You've answered all my questions. I see no reason why we shouldn't proceed.
-> court_judge_warn ->
Judge: You seem much more relaxed, Mr. Wright. Good for you.
-> court_phoenix_nervous ->
Phoenix: Thank you, Your Honor. (Because I don't FEEL relaxed, that's for sure.)
-> court_judge_normal ->
Judge: Well, then...
-> court_judge_warn ->
Judge: First, a question for the prosecution. Mr. Payne?
-> court_payne_normal ->
Payne: Yes, Your Honor?
Judge: As Mr. Wright just told us, the victim was struck with a blunt object.
-> court_judge_normal ->
Judge: Would you explain to the court just what that "object" was?
-> court_payne_normal ->
Payne: The murder weapon was this statue of "The Thinker."
Payne: It was found lying on the floor, next to the victim.
-> court_judge_normal ->
Judge: I see... the court accepts it into evidence.
~camera_y = 96 * 16
~camera_x = 2 * 16 * 17
~evidence_count = 3
Statue added to the court record.
-> court_mia_serious ->
Mia: Wright...
Mia: Be sure to pay attention to any evidence added during the trial.
Mia: That evidence is the only ammunition you have in court.
Mia: Check the Court record frequently.
-> court_gavel ->
-> court_judge_normal ->
Judge: Mr. Payne, the prosecution may call its first witness.
-> court_payne_normal ->
Payne: The prosecution calls the defendant, Mr. Butz, to the stand.
-> court_mia_serious ->
Phoenix: Um, Chief, what do I do now?
Mia: Pay attention. You don't want to miss any information that might help your client's case.
Mia: You'll get your chance to respond to the prosecution later, so be ready!
Mia: Let's just hope he doesn't say anything... unfortunate.
Phoenix: (Uh oh, Larry gets excited easily... this could be bad.)
~ forcefadeout = true
~ wait = Wait_For1Second
-> court_larry_normal ->
~ forcefadeout = false
~ wait = Wait_For2Seconds
-> court_payne_normal ->
Payne: Ahem.
Payne: Mr. Butz. Is it not true that the victim had recently dumped you?
-> court_larry_nervous ->
Butz: Hey, watch it buddy!
Butz: We were great together! We were Romeo and Juliet, Cleopatra and Mark Anthony!
-> court_phoenix_nervous ->
Phoenix: (Um... didn't they all die?)
-> court_larry_normal ->
Butz: I wasn't dumped! She just wasn't taking my phone call. Or seeing me... Ever.
-> court_larry_nervous ->
Butz: WHAT'S IT TO YOU, ANYWAY!?
-> court_payne_normal ->
Payne: Mr. Butz, what you describe is generally what we mean by "dumped."
Payne: In fact, she had completely abandoned you... and was seeing other men!
Payne: She had just returned from overseas with one of them the day before the murder!
-> court_larry_nervous ->
Butz: Whaddya mean, "one of them"!?
Butz: Lies! All of it, lies! I don't believe a word of it.
-> court_payne_normal ->
Payne: Your Honor, the victim's passport.
Payne: According to this, she was in Paris until the day before she died.
~camera_y = 96 * 16
~camera_x = 3 * 16 * 17
~evidence_count = 4
Passport added to the court record.
-> court_judge_normal ->
Judge: Hmm... Indeed, she appears to have returned the day before the murder.
-> court_larry_nervous ->
Butz: Dude... no way...
-> court_payne_normal ->
Payne: The victim was a model, but did not have a large income.
Payne: It appears that she has several "Sugar Daddies."
-> court_larry_nervous ->
Butz: Daddies? Sugar?
-> court_payne_normal ->
Payne: Yes. Older men, who gave her money and gifts.
Payne: She took their money and used it to support their lifestyle.
-> court_larry_nervous ->
Butz: Duuude!
Payne: We can clearly see what kind of woman this Ms. Stone was.
Payne: Tell me, Mr. Butz, what do you think of her now?
-> court_mia_serious ->
Mia: Wright...
Mia: I don't think you want him to answer than question.
-> court_phoenix_nervous ->
Phoenix: (Yeah... Larry has a way of running his mouth in all the wrong directions.)
-> court_phoenix_thinking ->
Phoenix: (Should I...?)
+ Wait and see -> WaitAndSee
+ Stop him from answering -> StopFromAnswering

== WaitAndSee
-> court_phoenix_thinking ->
Phoenix: (Might be better not to get involved in this one...)
-> court_payne_normal ->
Payne: Well, Mr. Butz?
-> court_larry_nervous ->
Butz: Dude, no way! That cheatin' she-dog!
-> AfterSheDog

== StopFromAnswering
-> court_phoenix_desk ->
Phoenix: My client had no idea the victim was seeing other men!
-> court_phoenix_point ->
Phoenix: That question is irrelevant to this case!
-> court_payne_nervous ->
Payne: Oof! *wince*
-> court_larry_nervous ->
Butz: Dude! Nick! Whaddya mean, "irrelevant"!?
-> court_larry_normal ->
Butz: That cheatin' she-dog!

== AfterSheDog
-> court_larry_nervous ->
Butz: I'm gonna die. I'm just gonna drop dead!
Butz: And when I meet her in the afterlife...
Butz: I'm going to get to the bottom of this!
-> court_gavel ->
-> court_judge_normal ->
Judge: Let's continue with the trial, shall we?
-> court_payne_normal ->
Payne: I believe the accused's motive is clear to everyone.
-> court_judge_normal ->
Judge: Yes, quite.
-> court_phoenix_nervous ->
Phoenix: (Oh boy. This is so not looking good.)
-> court_payne_normal ->
Payne: Next question!
Payne: You went to the victim's apartment on the day of the murder, did you not?
-> court_larry_nervous ->
Butz: Gulp!
-> court_payne_normal ->
Payne: Well, did you, or did you not?
-> court_larry_normal ->
Butz: Heh? Heh heh. Well, maybe I did, and maybe I didn't!
-> court_phoenix_nervous ->
Phoenix: (Uh oh. He went.)
Phoenix: (What do I do?)
+ Have him answer honestly -> AnswerHonestly
+ Stop him from answering -> AnswerStop

== AnswerHonestly
-> court_phoenix_normal ->
Phoenix: (I know! I'll send him a signal...)
-> court_phoenix_point ->
Phoenix:  (TELL THE TRUTH)
-> court_larry_normal ->
Butz: Er... Yeah! Yeah! I was there! I went!
-> court_gavel ->
-> court_judge_normal ->
Judge: Order!
-> court_judge_warn ->
Judge: Well, Mr. Butz?
-> court_larry_normal ->
Butz: Dude, chill!
Butz: She wasn't home, man... So, like, I didn't see her.
-> objection_payne ->
Payne: Your Honor, the defendant is lying.
-> court_judge_shocked ->
Judge: Lying?
-> court_payne_normal ->
Payne: The prosectution would like to call a witness who can prove Mr. Butz is lying.
-> call_witness

== AnswerStop
-> court_phoenix_normal ->
Phoenix: (I know! I'll send him a signal...)
-> court_phoenix_desk ->
Phoenix:  (LIE LIKE A DOG)
-> court_larry_normal ->
Butz: Um, well, see it's like this: I don't remember.
-> court_payne_normal ->
Payne: You "don't remember"?
Payne: Well then, we'll just have to remind you!
-> court_phoenix_normal ->
Phoenix: (I've got a bad feeling about this...)
-> court_payne_normal ->
Payne: We have a witness that can prove he DID go to the victim's apartment that day!

== call_witness
-> court_judge_shocked ->
Judge: Well, that simplifies matters. Who is your witness?
-> court_payne_normal ->
Payne: The man who found the victim's body.
Payne: Just before making the gruesome discovery...
-> court_larry_nervous ->
Payne: He saw the defendant fleeing the scene of the crime!
-> court_gavel ->
-> court_gavel ->
-> court_judge_normal ->
Judge: Order! Order in the court!
-> court_judge_warn ->
Judge: Mr. Payne, the prosecution may call its witness.
-> court_payne_normal ->
Payne: Yes, Your Honor.
-> court_phoenix_nervous ->
Phoenix: (This is bad...)
-> court_payne_normal ->
Payne: On the day of the murder, my witness was selling newspapers at the victim's building.
Payne: Please bring Mr. Frank Sahwit to the stand!
~ forcefadeout = true
~ wait = Wait_For1Second
-> court_sahwit_normal ->
~ forcefadeout = false
~ wait = Wait_For2Seconds
-> court_payne_normal ->
Payne: Mr. Sahwit, you sell newspaper subscriptions, is this correct?
-> court_sahwit_normal ->
Sahwit: Oh, oh yes! Newspapers, yes!
-> court_judge_normal ->
Judge: Mr. Sahwit, you may proceed with your testimony.
-> court_judge_warn ->
Judge: Please tell the court what you saw on the day of the murder.
~ forcefadeout = true
~ wait = Wait_For1Second
-> court_sahwit_normal ->
~ forcefadeout = false
 -- Witness's Account --
Sahwit: I was going door-to-door, selling subscriptions when I saw a man fleeing an apartment.
Sahwit: I thought he must be in a hurry because he left the door half-open behind him.
Sahwit: Thinking it strange, I looked inside the apartment.
Sahwit: Then I saw her lying there... A woman... not moving... dead!
Sahwit: I quailed in fright and found myself unable to go inside.
Sahwit: I thought to call the police immediately!
Sahwit: However, the phone in her apartment wasn't working.
Sahwit: I went to a nearby park and found a public phone.
Sahwit: I remember the time exactly: It was 1:00pm.
Sahwit: The man who ran was, without a doubt, the defantant sitting right over there.
~ forcefadeout = true
-> court_judge_thinking ->
~ forcefadeout = false
Judge: Hmm...
-> court_phoenix_desk ->
Phoenix: (Larry! Why didn't you tell the truth?)
-> court_phoenix_nervous ->
Phoenix: (I can't defend you against a testimony like that!)
-> court_judge_warn ->
Judge: Incidentally, why wasn't the phone in the victim's apartment working?
-> court_payne_normal ->
Payne: Your Honor, at the time of the murder, there was a blackout in the building.
-> court_judge_shocked ->
Judge: Aren't phones supposed to work during a blackout?
-> court_payne_normal ->
Payne: Yes, Your Honor...
Payne: However, some cordless phones do not function normally.
Payne: The phone that Mr. Sahwit used was one of those.
Payne: Your Honor...
Payne: I have a record of the blackout, for your perusal.

~camera_y = 96 * 16
~camera_x = 4 * 16 * 17
~evidence_count = 5
Blackout Record added to the Court Record.
-> court_judge_thinking ->
Judge: Now, Mr. Wright...
-> court_phoenix_normal ->
Phoenix: Yes! Er... yes, Your Honor?
-> court_judge_warn ->
Judge: You may begin your cross-examination.
-> court_phoenix_thinking ->
Phoenix: C-Cross-examination, Your Honor?
-> court_mia_serious ->
Mia: Alright, Wright, this is it. The real deal!
Phoenix: Uh... what exactly am I supposed to do?
Mia: Why, you expose the lies in the testimony the witness just gave!
Phoenix: Lies! What?! He was lying!?
Mia: Your client is innocent, right?
Mia: Then that witness must have lied in his testimony!
Mia: Or is your client really... guilty?
Phoenix: !!! How do I prove he's not?
Mia: You hold the key. It's in the evidence!
Mia: Compare the witness's testimony to the evidence at hand.
Mia: There's bound to be a contradiction in there!
Mia: First, find contradictions between the Court Record and the witness's testimony.
Mia: Then, once you've found the contradicting evidence...
Mia: Present it and rub it in the witness's face!
Phoenix: Um... okay.
Mia: Look at the Court Record and point out the contradictions in the testimony!
~ forcefadeout = true
-> court_sahwit_normal ->
~ forcefadeout = false
 -- Witness's Account -- -- Cross-Examination --

== cross_examination
~ evidence_count = 5
-> court_sahwit_normal ->

//wrap cross examination

{ selected_crossexamination == 0:
Sahwit: I was going door-to-door, selling subscriptions when I saw a man fleeing an apartment.
}
{ selected_crossexamination == 1:
Sahwit: I thought he must be in a hurry because he left the door half-open behind him.
}
{ selected_crossexamination == 2:
Sahwit: Thinking it strange, I looked inside the apartment.
}
{ selected_crossexamination == 3:
Sahwit: Then I saw her lying there... A woman... not moving... dead!
}
{ selected_crossexamination == 4:
Sahwit: I quailed in fright and found myself unable to go inside.
}
{ selected_crossexamination == 5:
Sahwit: I thought to call the police immediately!
}
{ selected_crossexamination == 6:
Sahwit: However, the phone in her apartment wasn't working.
}
{ selected_crossexamination == 7:
Sahwit: I went to a nearby park and found a public phone.
}
{ selected_crossexamination == 8:
Sahwit: I remember the time exactly: It was 1:00PM.
}
{ selected_crossexamination == 9:
Sahwit: The man who ran was, without a doubt, the defendant sitting right over there.
}

//+ Press Him -> cross_examination_press
+ Next Line -> cross_examination_next
+ {selected_crossexamination > 0} Previous Line -> cross_examination_previous
+ Court Record -> cross_examination_courtrecord

== cross_examination_courtrecord
~ can_present_evidence = true
~ presented_evidence = -1
-> open_court_record ->
~ can_present_evidence = false
{ presented_evidence >= 0:

 -> objection_phoenix ->

 //We've presented evidence
 { selected_crossexamination == 8:
 { presented_evidence == 1:
 -> court_phoenix_point ->
 Phoenix: You found the body at 1:00 PM. You're sure?
 -> court_sahwit_normal ->
 Sahwit: Yes. It was 1:00 PM, for certain.
 -> court_phoenix_normal ->
 Phoenix: Frankly, I find that hard to believe!
 -> court_phoenix_paper ->
 Phoenix: Your statement directly contradicts the autopsy report.
 Phoenix: The autopsy notes the time of death at sometime after 4PM.
 Phoenix: There was no body to... er... no "body" to find at 1:00 PM!
 -> court_phoenix_smug ->
 Phoenix: How do you explain this three-hour gap?
 -> court_sahwit_nervous ->
 Sahwit: !!!
 Sahwit: Oh, that! Oh, er...
 -> objection_payne ->
 -> court_payne_nervous ->
 Payne: This is trivial! The witness merely forgot the time!
 -> court_judge_normal ->
 Judge: After his testimony, I find that hard to believe.
 -> court_judge_warn ->
 Judge: Mr. Sahwit...
 Judge: Why were you so certain that you found the body at 1:00pm?
 -> court_sahwit_nervous ->
 Sahwit: I... er... well, I... Gee, that's a really good question!
 -> court_mia_serious ->
 Mia: Great job, Wright! Way to put him on the spot!
 Mia: That's all you have to do: point out contradictions!
 Mia: Lies always beget more lies!
 Mia: See through one, and their whole story falls apart!
 ~ forcefadeout = true
 -> StartUp
 }
 }
 
 //If we've reached here, this evidence is wrong
 -> court_phoenix_desk ->
 Phoenix: Your Honor! What do you think about the witness's statement?
 -> court_judge_warn ->
 Phoenix: Uh... I'm not sure I follow?
 -> court_phoenix_desk ->
 Phoenix: It clearly, er, contradicts the... um... I thought...
 -> court_judge_warn ->
 Judge: You don't sound very convinced, Mr. Wright.
 Judge: Objection overruled.
 Phoenix: (I don't think that won me any points with the judge...)
 
}
-> cross_examination

== cross_examination_press
== cross_examination_present

== cross_examination_previous
~ selected_crossexamination = selected_crossexamination - 1
-> cross_examination

== cross_examination_next
~ selected_crossexamination = selected_crossexamination + 1

{ selected_crossexamination == 10:
-> court_mia_serious ->
Mia: That's all of it.
Mia: There must be a contradiction in there somewhere.
Mia: Examine the Court Record if something strikes you as being suspicious.
Mia: Then, find the evidence that contradicts his testimony, and present it to him!
~selected_crossexamination = 0
}

-> cross_examination

== open_court_record
+ View profiles -> open_profiles
+ View evidence -> open_evidence
+ Go back -> return

== open_evidence
//Wrap evidence
{ selected_evidence < 0 :
 ~selected_evidence = evidence_count - 1
}
{ selected_evidence >= evidence_count :
 ~selected_evidence = 0
}
~ camera_y = 96 * 16
~ camera_x = selected_evidence * 16 * 17

{ selected_evidence == 0 :
 Attorney's Badge:<br>No one would believe I was a defense attorney if I didn't carry this.
}
{ selected_evidence == 1 :
 Cindy's Autopsy Report:<br>Time of Death: 7-31, 4PM-5PM. Cause of death: loss of blood due to blunt trauma.
 ~seen_autopsy = true
}
{ selected_evidence == 2 :
 Statue/The Thinker:<br>A statue in the shape of "The Thinker". It's rather heavy.
}
{ selected_evidence == 3 :
 Passport:<br>The victim apparently arrived home from Paris on 7/30, the day before the murder.
} 
{ selected_evidence == 4 :
 Blackout Record:<br>Electricity to Ms. Stone's building was out from noon to 6 PM on the day of the crime.
}

+ Next Record -> next_evidence
+ Previous Record -> previous_evidence
+ {can_present_evidence} Present -> present_evidence
+ Go back -> open_court_record

== next_evidence
~ selected_evidence = selected_evidence + 1
-> open_evidence

== previous_evidence
~ selected_evidence = selected_evidence - 1
-> open_evidence

== present_evidence
~ presented_evidence = selected_evidence
->->

== open_profiles
//Wrap profiles
{ selected_profile < 0 :
 ~selected_profile = profile_count - 1
}
{ selected_profile >= profile_count :
 ~selected_profile = 0
}
~ camera_y = 83*16
~ camera_x = selected_profile * 16 * 17

{ selected_profile == 0 :
 Mia Fey. Age 27. Female:<br>Chief Attorney at Fey and Co My boss, and a very good defense attorney.
}
{ selected_profile == 1 :
 Larry Butz. Age 23. Male:<br>The defendant in this case. A likeable guy who was my friend in grade school.
}
{ selected_profile == 2 :
 ~ seen_cindy_profile = true
 Cindy Stone. Age 22. Female:<br>The victim in this case. A model, she lived in an apartment by herself.
}
{ selected_profile == 3 :
 Winston Paine. Age 52. Male:<br>The prosecutor for this case. Lacks presence, Generally bad at getting his points across.
}
+ Next Record -> next_profile
+ Previous Record -> previous_profile
+ Go back -> open_court_record

== next_profile
~ selected_profile = selected_profile + 1
-> open_profiles

== previous_profile
~ selected_profile = selected_profile - 1
-> open_profiles

== lobby_empty
 ~camera_x = 0
 ~camera_y = 0
->->

== lobby_mia_smile1
 ~camera_x = 0
 ~camera_y = 14 * 16
->->

== lobby_mia_smile2
 ~camera_x = 0
 ~camera_y = 14 * 16 * 2
->->

== lobby_mia_curious
 ~camera_x = 0
 ~camera_y = 14 * 16 * 3
->->

== lobby_larry_crying
 ~camera_x = 17 * 16
 ~camera_y = 0
->->

== lobby_larry_nervous
 ~camera_x = 17 * 16
 ~camera_y = 14 * 16
->->

== lobby_cindy
 ~camera_x = 17 * 2 * 16
 ~camera_y = 0
->->


== court_gavel
 ~sound = snd_gavel
 ~camera_x = 0
 ~camera_y = 14 * 16
 ~wait = Wait_For1Second
->->

== court_judge_normal
 ~camera_x = 0
 ~camera_y = 14 * 16 * 2
->->

== court_judge_thinking
 ~camera_x = 0
 ~camera_y = 14 * 16 * 3
->->

== court_judge_warn
 ~camera_x = 0
 ~camera_y = 14 * 16 * 4
->->

== court_judge_shocked
 ~camera_x = 0
 ~camera_y = 14 * 16 * 5
->->

== court_payne_normal
 ~camera_x = 17 * 16
 ~camera_y = 0
->->

== court_payne_smug
 ~camera_x = 17 * 16
 ~camera_y = 14 * 16
->->

== court_payne_nervous
 ~camera_x = 17 * 16
 ~camera_y = 28 * 16
->->

== objection_payne
 ~sound = snd_objection
 ~camera_x = 68*16
 ~camera_y = 83*16
 ~wait = Wait_For1Second
->->

== objection_phoenix
 ~sound = snd_objection
 ~camera_x = 68*16
 ~camera_y = 83*16
 ~wait = Wait_For1Second
->->

== court_phoenix_normal
 ~camera_x = 17 * 16 * 2
 ~camera_y = 0
->->

== court_phoenix_nervous
 ~camera_x = 17 * 16 * 2
 ~camera_y = 14 * 16 * 1
->->

== court_phoenix_thinking
 ~camera_x = 17 * 16 * 2
 ~camera_y = 14 * 16 * 2
->->

== court_phoenix_paper
 ~camera_x = 17 * 16 * 2
 ~camera_y = 14 * 16 * 3
->->

== court_phoenix_point
 ~camera_x = 17 * 16 * 2
 ~camera_y = 14 * 16 * 4
->->

== court_phoenix_shocked
 ~camera_x = 17 * 16 * 2
 ~camera_y = 14 * 16 * 5
->->

== court_phoenix_smug
 ~camera_x = 51 * 16
 ~camera_y = 56 * 16
->->

== court_phoenix_desk
 ~sound = snd_deskslam
 ~camera_x = 51 * 16
 ~camera_y = 70 * 16
->->

== court_mia_disappointed
 ~camera_x = 17 * 16 * 3
 ~camera_y = 0
->->

== court_mia_sad
 ~camera_x = 17 * 16 * 3
 ~camera_y = 14 * 16 * 1
->->

== court_mia_shocked
 ~camera_x = 17 * 16 * 3
 ~camera_y = 14 * 16 * 2
->->

== court_mia_serious
 ~camera_x = 17 * 16 * 3
 ~camera_y = 14 * 16 * 3
->->

== court_larry_normal
 ~camera_x = 68 * 16
 ~camera_y = 0
->->

== court_larry_nervous
 ~camera_x = 68 * 16
 ~camera_y = 14 * 16
->->

== court_sahwit_normal
 ~camera_x = 68 * 16
 ~camera_y = 14 * 16 * 2
->->

== court_sahwit_nervous
 ~camera_x = 68 * 16
 ~camera_y = 14 * 16 * 3
->->

== return
->->
