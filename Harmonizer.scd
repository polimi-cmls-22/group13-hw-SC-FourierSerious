(
//it boots the server if it is not already booted
if(s.hasBooted==false,{s.boot},{});

//when server is booted
s.doWhenBooted({
//Loading the audio file into a buffer
~path = PathName(thisProcess.nowExecutingPath).parentPath;
c = Buffer.read(s,~path ++ "Nirvana.wav");

//This synthesizer modules, pans and plays back the audio file stored in a buffer
SynthDef.new(\audio, {
	arg outBus, amp=1, buf=c, rate=1.0884, da=2, pan=0;
	var sig;
	sig = PlayBuf.ar(2, buf, rate, doneAction:da);
	sig = sig*amp; //Modulating
	sig = Balance2.ar(sig[0], sig[1], pan); //Panning
	Out.ar(outBus,sig);
}).add;

//This synthesizer modules, pans and plays back the audio taken from the mics
SynthDef.new(\mic, {
	arg outBus, amp=1, in=0, pan=0;
	var sig;
	sig = SoundIn.ar(in!2) * amp; //Modulating
	sig = Balance2.ar(sig[0], sig[1], pan);//Panning
	Out.ar(outBus,sig);
}).add;

//It generates the harmonized signals by pitch-shifting the input signal and sending them out on different output bus
SynthDef(\harmonizer, {

	arg key=0, inBus, outBus, dispr=0, disp=0;
	var in, inTemp, freq, hasFreq, harm1, harm2, harm4, harm3, note, tempNote, pitch = [18, 18, 18, 18];

	in = In.ar(inBus,2);
	inTemp = Mix.new(in);
	# freq, hasFreq = Pitch.kr(inTemp);  //pitch recognition of the audio input
	note = freq.cpsmidi.round(1); //frequency converted as a midi number
	tempNote = note - key; //note shifted in a C major scale
	tempNote = (tempNote % 12);  //now all notes are converted to a number from 0 to 12
	//switch to assign different pitch-shifts to each note
	pitch = Select.kr(tempNote+1 < 1, [[-8, -5, 4, 7], pitch]);
	pitch = Select.kr(tempNote+1 < 2, [[-8, -4, 4, 8], pitch]);
	pitch = Select.kr(tempNote+1 < 3, [[-9, -5, 3, 7], pitch]);
	pitch = Select.kr(tempNote+1 < 4, [[-8, -4, 4, 8], pitch]);
	pitch = Select.kr(tempNote+1 < 5, [[-9, -5, 3, 7], pitch]);
	pitch = Select.kr(tempNote+1 < 6, [[-8, -5, 4, 7], pitch]);
	pitch = Select.kr(tempNote+1 < 7, [[-9, -6, 3, 6], pitch]);
	pitch = Select.kr(tempNote+1 < 8, [[-8, -5, 4, 7], pitch]);
	pitch = Select.kr(tempNote+1 < 9, [[-8, -4, 4, 8], pitch]);
	pitch = Select.kr(tempNote+1 < 10, [[-9, -5, 3, 7], pitch]);
	pitch = Select.kr(tempNote+1 < 11, [[-8, -5, 4, 7], pitch]);
	pitch = Select.kr(tempNote+1 < 12, [[-9, -6, 3, 6], pitch]);

	//pitch-shifts of the signal
	harm1 = PitchShift.ar(in, pitchRatio:pitch[0].midiratio, pitchDispersion: dispr, timeDispersion:disp);
	harm2 = PitchShift.ar(in, pitchRatio:pitch[1].midiratio, pitchDispersion: dispr, timeDispersion:disp);
	harm3 = PitchShift.ar(in, pitchRatio:pitch[2].midiratio, pitchDispersion: dispr, timeDispersion:disp);
	harm4 = PitchShift.ar(in, pitchRatio:pitch[3].midiratio, pitchDispersion: dispr, timeDispersion:disp);

	Out.ar(outBus, harm1);    //6th below
	Out.ar(outBus+2, harm2);  //4th below
	Out.ar(outBus+4, harm3);  //3rd above
	Out.ar(outBus+6, harm4);  //5th above

}).add;

//This synthesizer receives the harmonized voice and modulates and pans it.
SynthDef(\harmController, {
	arg inBus, outBus, amp=1, pan=0;
	var sig;
	sig = In.ar(inBus,2);
	sig = Balance2.ar(sig[0], sig[1], pan); //Panning
	sig = sig * amp; //Modulating
	Out.ar(outBus,sig);
}).add;

//This synthesizer applies reverb to the signal coming from inBus
SynthDef.new(\rev, {
	arg inBus, outBus, mixRev=1, roomRev=0.5, dampRev=0.5, wetAmp=0.33;
	var sig, wet;
	sig = In.ar(inBus,2);
	wet = FreeVerb2.ar(sig[0],sig[1], mix:mixRev, room:roomRev, damp:dampRev, mul:wetAmp);
	Out.ar(outBus, wet);
}).add;


//Allocating busses
~harmInBus = Bus.audio(s,2);
~harmOutBus = Bus.audio(s,8);
~revBus = Bus.audio(s,2);

//Main function to run the harmonizer with mic as input
g = {
~micGrp = Group.new;
~harmInGrp = Group.after(~micGrp);
~harmOutGrp = Group.after(~harmInGrp);
~revGrp = Group.after(~harmOutGrp);

//we register (at a NodeWatcher object) the created synths in order to check their states later
~micDirect = Synth(\mic, [\outBus, 0], ~micGrp).register;
~micHarmEffect = Synth(\mic, [\outBus,~harmInBus], ~micGrp).register;
~micRevEffect = Synth(\mic, [\outBus,~revBus], ~micGrp).register;
~harm = Synth(\harmonizer, [\inBus, ~harmInBus , \outBus, ~harmOutBus], ~harmInGrp).register;
~harm1 = Synth(\harmController, [\inBus, ~harmOutBus, \outBus, 0], ~harmOutGrp).register;
~harm2 = Synth(\harmController, [\inBus, ~harmOutBus.index+2, \outBus, 0], ~harmOutGrp).register;
~harm3 = Synth(\harmController, [\inBus, ~harmOutBus.index+4, \outBus, 0], ~harmOutGrp).register;
~harm4 = Synth(\harmController, [\inBus, ~harmOutBus.index+6, \outBus, 0], ~harmOutGrp).register;
~rev = Synth(\rev, [\inBus, ~revBus, \outBus,0], ~revGrp).register;

//Setting of the parameters of the synths according to the values of the knobs, sliders and menu
//Mic parameters
~micDirect.set(\amp, ~k1.value);
~micDirect.set(\pan, ~p1.value);
//Harmonizer parameters
~harm.set(\key, ~m.value);
~harm.set(\dispr, ~p6.value);
~harm.set(\disp, ~p7.value);
//Harmonizer controller
~harm1.set(\amp, ~k2.value);
~harm1.set(\pan, ~p2.value);
~harm2.set(\amp, ~k3.value);
~harm2.set(\pan, ~p3.value);
~harm3.set(\amp, ~k4.value);
~harm3.set(\pan, ~p4.value);
~harm4.set(\amp, ~k5.value);
~harm4.set(\pan, ~p5.value);
//Reverb parameters
~rev.set(\wetAmp, ~k6.value);
~rev.set(\roomRev, ~k7.value);
~rev.set(\revMix, ~k8.value);
~rev.set(\dampRev, ~k9.value);
};

//Main function to run the harmonizer with audio file as input
f = {
~audioGrp = Group.new;
~harmInGrp = Group.after(~audioGrp);
~harmOutGrp = Group.after(~harmInGrp);
~revGrp = Group.after(~harmOutGrp);

//we register (at a NodeWatcher object) the created synths in order to check their states later
~audioDirect = Synth(\audio, [\outBus, 0, \buf, c], ~audioGrp).register;
~audioHarmEffect = Synth(\audio, [\outBus,~harmInBus], ~audioGrp).register;
~audioRevEffect = Synth(\audio, [\outBus,~revBus], ~audioGrp).register;
~harm = Synth(\harmonizer, [\inBus, ~harmInBus , \outBus, ~harmOutBus], ~harmInGrp).register;
~harm1 = Synth(\harmController, [\inBus, ~harmOutBus, \outBus, 0], ~harmOutGrp).register;
~harm2 = Synth(\harmController, [\inBus, ~harmOutBus.index+2, \outBus, 0], ~harmOutGrp).register;
~harm3 = Synth(\harmController, [\inBus, ~harmOutBus.index+4, \outBus, 0], ~harmOutGrp).register;
~harm4 = Synth(\harmController, [\inBus, ~harmOutBus.index+6, \outBus, 0], ~harmOutGrp).register;
~rev = Synth(\rev, [\inBus, ~revBus, \outBus,0], ~revGrp).register;

//Setting of the parameters of the synths according to the values of the knobs, sliders and menu
//Audio parameters
~audioDirect.set(\amp, ~k1.value);
~audioDirect.set(\pan, ~p1.value);
//Harmonizer parameters
~harm.set(\key, ~m.value);
~harm.set(\dispr, ~p6.value);
~harm.set(\disp, ~p7.value);
//Harmonizer controller
~harm1.set(\amp, ~k2.value);
~harm1.set(\pan, ~p2.value);
~harm2.set(\amp, ~k3.value);
~harm2.set(\pan, ~p3.value);
~harm3.set(\amp, ~k4.value);
~harm3.set(\pan, ~p4.value);
~harm4.set(\amp, ~k5.value);
~harm4.set(\pan, ~p5.value);
//Reverb Parameters
~rev.set(\wetAmp, ~k6.value);
~rev.set(\roomRev, ~k7.value);
~rev.set(\revMix, ~k8.value);
~rev.set(\dampRev, ~k9.value);
};

a = { //Set all the knobs and the sliders at the initial value
~k1.value=1;
~k2.value=0;
~k3.value=0;
~k4.value=0;
~k5.value=0;
~k6.value=0;
~k7.value=0;
~k8.value=0;
~k9.value=0;
~p1.value=0;
~p2.value=0;
~p3.value=0;
~p4.value=0;
~p5.value=0;
~p6.value=0;
~p7.value=0;
~m.value=0;
};

//GUI

Window.closeAll;

//window
w = Window.new(
	"Harmonizer",
	Rect(

		Window.screenBounds.width/2-485, //centered
		Window.screenBounds.height/2-300,
		970,
		600), resizable: false
);

w.background= Color.fromHexString("#B8AAA5");

//three sections of the window
~wharm = CompositeView(w, Rect(w.bounds.width-140, 30, 130, w.bounds.height-20));
~wharm.background = Color.fromHexString("#B8AAA5"); // harmonizer window

~mainw = CompositeView(w, Rect(10, 60, w.bounds.width-~wharm.bounds.width-30, 280));
~mainw.background = Color.fromHexString("#cebeb9"); // main window

~reverb = CompositeView(w, Rect(10, 350, w.bounds.width-~wharm.bounds.width-30, 240));
~reverb.background = Color.fromHexString("#cebeb9"); // reverb window

~title = StaticText(w, Rect(0,0,970,50));
~title.string = "HARMONIZER";
~title.font = Font("Arial", 30, true);
~title.stringColor = Color.fromHexString("#F2F0E4");
~title.background = Color.fromHexString("#3B3635");
~title.align = \center;

//MAIN WINDOW

//decorator that arranges automatically the views in a row
~mainw.decorator = FlowLayout(~mainw.bounds, 50@10, 75@5);

~t1 = StaticText(~mainw,Rect(0,0,80,50));
~t1.string = "Source";
~t1.font = Font("Monaco", 16);
~t1.align = \center;

~t2 = StaticText(~mainw,Rect(0,0,80,50));
~t2.string = "Sixth Down";
~t2.font = Font("Monaco", 16);
~t2.align = \center;

~t3 = StaticText(~mainw,Rect(0,0,80,50));
~t3.string = "Fourth Down";
~t3.font = Font("Monaco", 16);
~t3.align = \center;

~t4 = StaticText(~mainw,Rect(0,0,80,50));
~t4.string = "Third Up";
~t4.font = Font("Monaco", 16);
~t4.align = \center;

~t5 = StaticText(~mainw,Rect(0,0,80,50));
~t5.string = "Fifth Up";
~t5.font = Font("Monaco", 16);
~t5.align = \center;

~mainw.decorator.nextLine;

//five knobs with range from 0 to 1
d = ControlSpec.new(0, 1, \lin);

//first knob controls the volume of the source
~k1 = EZKnob(parent:~mainw, bounds:Rect(0,0,80,125), label:"Vol", controlSpec:d, initVal:1);
~k1.labelView.align = \center;
~k1.setColors(nil,Color.black,nil,nil, nil ,Color.fromHexString("#3B3635"),[Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635"),Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635")], nil);
~k1.action_({
	arg view;
	if(~audioDirect.isPlaying, {~audioDirect.set(\amp, view.value)});
	if(~micDirect.isPlaying,{ ~micDirect.set(\amp, view.value)});
});

//second knob controls the volume of the sixth down harmonizer
~k2 = EZKnob(parent:~mainw, bounds:Rect(0,0,80,125), label:"Vol", controlSpec:d, initVal:0);
~k2.setColors(nil,Color.black,nil,nil, nil ,Color.fromHexString("#3B3635"),[Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635"),Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635")], nil);
~k2.labelView.align = \center;
~k2.action_({
	arg view;
	if(~harm1.isPlaying, {~harm1.set(\amp, view.value)});
});

//third knob controls the volume of the fourth down harmonizer
~k3 = EZKnob(parent:~mainw, bounds:Rect(0,0,80,125), label:"Vol", controlSpec:d, initVal:0);
~k3.setColors(nil,Color.black,nil,nil, nil ,Color.fromHexString("#3B3635"),[Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635"),Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635")], nil);
~k3.labelView.align = \center;
~k3.action_({
	arg view;
	if(~harm2.isPlaying, {~harm2.set(\amp, view.value)});
});

//fourth knob controls the volume of the third up harmonizer
~k4 = EZKnob(parent:~mainw, bounds:Rect(0,0,80,125), label:"Vol", controlSpec:d, initVal:0);
~k4.setColors(nil,Color.black,nil,nil, nil ,Color.fromHexString("#3B3635"),[Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635"),Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635")], nil);
~k4.labelView.align = \center;
~k4.action_({
	arg view;
	if(~harm3.isPlaying, {~harm3.set(\amp, view.value)});
});

//second knob controls the volume of the fifth up harmonizer
~k5 = EZKnob(parent:~mainw, bounds:Rect(0,0,80,125), label:"Vol", controlSpec:d, initVal:0);
~k5.setColors(nil,Color.black,nil,nil, nil ,Color.fromHexString("#3B3635"),[Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635"),Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635")], nil);
~k5.labelView.align = \center;
~k5.action_({
	arg view;
	if(~harm4.isPlaying, {~harm4.set(\amp, view.value)});
});

~mainw.decorator.nextLine;

//five sliders with range from -1 to 1 to control the pan of the signals controlled by the five knobs
j = ControlSpec.new(-1, 1, \lin);
~p1 = EZSlider(parent:~mainw, bounds:Rect(0,0,80,65), label:"Pan", controlSpec:j, initVal: 0, layout: 'vert');
~p1.sliderView.background_(Color.fromHexString("#3B3635"));
~p1.labelView.align = \center;
~p1.action_({
	arg view;
	if(~audioDirect.isPlaying, {~audioDirect.set(\pan, view.value)});
	if(~micDirect.isPlaying,{ ~micDirect.set(\pan, view.value)});
});
~p2 = EZSlider(parent:~mainw, bounds:Rect(0,0,80,65), label:"Pan", controlSpec:j, initVal: 0, layout: 'vert');
~p2.sliderView.background_(Color.fromHexString("#3B3635"));
~p2.labelView.align = \center;
~p2.action_({
	arg view;
	if(~harm1.isPlaying, {~harm1.set(\pan, view.value)});
});
~p3 = EZSlider(parent:~mainw, bounds:Rect(0,0,80,65), label:"Pan", controlSpec:j, initVal: 0, layout: 'vert');
~p3.sliderView.background_(Color.fromHexString("#3B3635"));
~p3.labelView.align = \center;
~p3.action_({
	arg view;
	if(~harm2.isPlaying, {~harm2.set(\pan, view.value)});
});
~p4 = EZSlider(parent:~mainw, bounds:Rect(0,0,80,65), label:"Pan", controlSpec:j, initVal: 0, layout: 'vert');
~p4.sliderView.background_(Color.fromHexString("#3B3635"));
~p4.labelView.align = \center;
~p4.action_({
	arg view;
	if(~harm3.isPlaying, {~harm3.set(\pan, view.value)});
});
~p5 = EZSlider(parent:~mainw, bounds:Rect(0,0,80,65), label:"Pan", controlSpec:j, initVal: 0, layout: 'vert');
~p5.sliderView.background_(Color.fromHexString("#3B3635"));
~p5.labelView.align = \center;
~p5.action_({
	arg view;
	if(~harm4.isPlaying, {~harm4.set(\pan, view.value)});
});

//REVERB WINDOW

~reverb.decorator = FlowLayout(~reverb.bounds, 120@5, 75@5);

~t = StaticText(~reverb,Rect(0,25,580,50));
~t.string = "REVERB";
~t.font = Font("Arial", 22, bold: true,);
~t.align = \center;
~t.stringColor = Color.fromHexString("#3B3635");
~reverb.decorator.nextLine;

//four knobs to control the reverberation effect
l = ControlSpec.new(0, 1, \lin);
//first knob controls the param \wetAmp of the reverberation effect
~k6 = EZKnob(parent:~reverb, bounds:Rect(0,0,80,150), label:"Wet Amp", controlSpec:l, initVal:0);
~k6.labelView.align = \center;
~k6.setColors(nil,Color.black,nil,nil, nil ,Color.fromHexString("#3B3635"),[Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635"),Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635")], nil);
~k6.action_({
	arg view;
	if(~rev.isPlaying, {~rev.set(\wetAmp, view.value)});
});
//second knob controls the param \roomRev of the reverberation effect
~k7 = EZKnob(parent:~reverb, bounds:Rect(0,0,80,150), label:"Room", controlSpec:l, initVal:0);
~k7.labelView.align = \center;
~k7.setColors(nil,Color.black,nil,nil, nil ,Color.fromHexString("#3B3635"),[Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635"),Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635")], nil);
~k7.action_({
	arg view;
	if(~rev.isPlaying, {~rev.set(\roomRev, view.value)});
});
//third knob controls the param \revMix of the reverberation effect
~k8 = EZKnob(parent:~reverb, bounds:Rect(0,0,80,150), label:"Wet/Dry", controlSpec:l, initVal:0);
~k8.labelView.align = \center;
~k8.setColors(nil,Color.black,nil,nil, nil ,Color.fromHexString("#3B3635"),[Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635"),Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635")], nil);
~k8.action_({
	arg view;
	if(~rev.isPlaying, {~rev.set(\revMix, view.value)});
});
//fourth knob controls the param \dampRev of the reverberation effect
~k9 = EZKnob(parent:~reverb, bounds:Rect(0,0,80,150), label:"Damp", controlSpec:l, initVal:0);
~k9.labelView.align = \center;
~k9.setColors(nil,Color.black,nil,nil, nil ,Color.fromHexString("#3B3635"),[Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635"),Color.fromHexString("#F2F0E4"), Color.fromHexString("#3B3635")], nil);
~k9.action_({
	arg view;
	if(~rev.isPlaying, {~rev.set(\dampRev, view.value)});
});

//HARMONIZER WINDOW

//button that chooses the microphone as input signal
~b1 = Button(parent:~wharm, bounds:Rect(15, 40, 100, 70));
//~b1.string = "Play with mic";
~b1.states_([["Play with mic", Color.black], ["Playing with mic", Color.white, Color.fromHexString("#3B3635")]]);
~b1.font = Font("Arial", 12, bold: false, italic:true);
~b1.action_({
	arg view;
	//if it is pushed, it frees the Synth \audio (if it is playing) and run the function g that controls the mic
	if(view.value==1,{
		if(~audioDirect.isPlaying, {
			~audioDirect.free;
			~audioHarmEffect.free;
			~audioRevEffect.free;
			~b2.value = 0;});
		g.value;
	},
	//it frees all Synths if it is pushed again
	{s.freeAll});
});

//button that chooses the audio file as input signal
~b2 = Button(parent:~wharm, bounds:Rect(15, 130, 100, 70));
~b2.states_([["Play with file", Color.black], ["Playing with file", Color.white,Color.fromHexString("#3B3635")]]);
~b2.font = Font("Arial", 12, bold: false, italic:true);
~b2.action_({
	arg view;
	//if it is pushed, it frees the Synth \mic (if it is playing) and run the function f that controls the mic
	if(view.value==1,{
		if(~micDirect.isPlaying, {
			~micDirect.free;
			~micHarmEffect.free;
			~micRevEffect.free;
			~b1.value = 0;});
		f.value;
	},
	//it frees all Synths if it is pushed again
	{s.freeAll});
});

//button that stops the execution and reset all the variables to the initial value
~b3 = Button(parent:~wharm, bounds:Rect(15, 220, 100, 70));
~b3.string = "STOP";
~b3.font = Font("Arial", 12, bold: true, italic:false);
~b3.action_({
	a.value;
	s.freeAll;
	~b1.value = 0;
	~b2.value = 0;
});

~wharm.decorator = FlowLayout(~wharm.bounds, 15@315, 50@10);

//menu that allows to choose the key of the song
~m = EZPopUpMenu.new(
    ~wharm,
    100@40,
    "Key",
    [
		"C" ->{if(~harm.isPlaying, {~harm.set(\key, 0);})},
		"C#/Db" ->{if(~harm.isPlaying, {~harm.set(\key, 1);})},
		"D" ->{if(~harm.isPlaying, {~harm.set(\key, 2);})},
		"D#/Eb" ->{if(~harm.isPlaying, {~harm.set(\key, 3);})},
		"E" ->{if(~harm.isPlaying, {~harm.set(\key, 4);})},
		"F" ->{if(~harm.isPlaying, {~harm.set(\key, 5);})},
		"F#/Gb" ->{if(~harm.isPlaying, {~harm.set(\key, 6);})},
		"G" ->{if(~harm.isPlaying, {~harm.set(\key, 7);})},
		"G#/Ab" ->{if(~harm.isPlaying, {~harm.set(\key, 8);})},
		"A" ->{if(~harm.isPlaying, {~harm.set(\key, 9);})},
		"A#/Bb" ->{if(~harm.isPlaying, {~harm.set(\key, 10);})},
		"B" ->{if(~harm.isPlaying, {~harm.set(\key, 11);})},
    ],
    initVal: 0,
    initAction: true,
    labelWidth: 100,
    labelHeight: 20,
    layout: \vert,
    gap: 2@2
);

//slider with range from 0 to 0.5 to control deviation of the pitched signal (detune)
o = ControlSpec.new(0, 0.5, \lin);
~p6 = EZSlider(parent:~wharm, bounds:Rect(0,0,100,80), label:"Pitch disp", controlSpec:o, initVal: 0, layout: 'vert');
~p6.labelView.align = \center;
~p6.sliderView.background_(Color.fromHexString("#3B3635"));
~p6.action_({
	arg view;
	if(~harm.isPlaying, {~harm.set(\dispr, view.value)});
});

//slider with range from 0 to 0.2 to control the param \disp of the harmonizer
i = ControlSpec.new(0, 0.2, \lin);
~p7 = EZSlider(parent:~wharm, bounds:Rect(0,0,100,80), label:"Time disp", controlSpec:i, initVal: 0, layout: 'vert');
~p7.labelView.align = \center;
~p7.sliderView.background_(Color.fromHexString("#3B3635"));
~p7.action_({
	arg view;
	if(~harm.isPlaying, {~harm.set(\disp, view.value)});
});

w.alwaysOnTop_(true);
w.front;

w.onClose_({CmdPeriod.run; Server.killAll;});
});
)