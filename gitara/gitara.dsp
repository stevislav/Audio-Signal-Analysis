process = vgroup("Gitara",environment{

import("stdfaust.lib");

KEY = 20;	// osnovna midi nota
CCY = 15;	// duzina ciklusa
BPS = 360;	// tempo (beats per second)

START=checkbox("Start");
process = gitara * START <: _,_;    

gitara = vgroup("Gitara", instrument(C,11,48), instrument(C,11,60), (instrument(C,11,72) : *(1.5), *(1.5)) 
	:>*(l))
	with {
		l = hslider("[1]Jačina",-20, -60, 0, 0.01) : ba.db2linear;
		C = hslider("[2]Bistrina[acc:0 1 -10 0 10]", 0.2, 0, 1, 0.01) : ba.automat(BPS, CCY, 0.0);
	};

// C - koeficijent filtra između 0 i 1
// N žica koristeći pentatonsku skalu
// b nota
// trzaj žice na osnovu položaja ruke

instrument(C,N,b) = 	ruka(b) <: par(i, N, position(i+1)
							: zica(C,Penta(b).degree2Hz(i), att, lvl)
							: pan((i+0.5)/N) )
				 	:> _,_
	with {
		att  = hslider("[3]Rezonanca[acc:2 1 -10 0 12]", 4, 0.1, 10, 0.01); 
		ruka(48) = vslider("h:[1]Instrument /1 (Nota %b)[acc:1 0 -10 0 14]", 0, 0, N, 1) : int : ba.automat(120, CCY, 0.0);
		ruka(60) = vslider("h:[1]Instrument /2 (Nota %b)[acc:1 0 -10 0 14]", 2, 0, N, 1) : int : ba.automat(240, CCY, 0.0);
		ruka(72) = vslider("h:[1]Instrument /3 (Nota %b)[acc:1 0 -10 0 10]", 4, 0, N, 1) : int : ba.automat(360, CCY, 0.0);
		lvl = 1;
		pan(p) = _ <: *(sqrt(1-p)), *(sqrt(p));
		position(a,x) = abs(x - a) < 0.5;
	};

//Pentatonska skala

Penta(key) = environment {

	A4Hz = 440; 
	
	degree2midi(0) = key+0;
	degree2midi(1) = key+2;
	degree2midi(2) = key+4;
	degree2midi(3) = key+7;
	degree2midi(4) = key+9;
	degree2midi(d) = degree2midi(d-5)+12;
	
	degree2Hz(d) = A4Hz*semiton(degree2midi(d)-69) with { semiton(n) = 2.0^(n/12.0); };

}; 
 
// Karplus Strong algoritam

zica(coef, freq, t60, level, trig) = no.noise*level
							: *(trig : trigger(freq2samples(freq)))
							: resonator(freq2samples(freq), att)
	with {
		resonator(d,a)	= (+ : @(d-1)) ~ (average : *(a));
		average(x)		= (x*(1+coef)+x'*(1-coef))/2;
		trigger(n) 		= upfront : + ~ decay(n) : >(0.0);
		upfront(x) 		= (x-x') > 0.0;
		decay(n,x)		= x - (x>0.0)/n;
		freq2samples(f) = 44100.0/f;
		att 			= pow(0.001,1.0/(freq*t60)); // attenuation coefficient
		random  		= +(12345)~*(1103515245);  // random broj
		noise   		= random/2147483647.0; // Mersenov prost broj
	};

   
}.process);