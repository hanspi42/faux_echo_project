% Pro7E Matlab File for the Simulink simulation
clc; clear; close all; clear sound; format longeng
s = tf('s');

%-------------------------------------------------------
%-------------------- USER SETTINGS --------------------
%-------------------------------------------------------

%----- Specify input signal and model -----
sim_name = 'Der_Faux_FPGA_V2';      % V2 uses an improved comparator logic
load_audio_sample = true;

if load_audio_sample == true
   [audio, fs] = audioread('Faux_Sample_Guitar_01_in.wav');
else
    fs = 48000;
    audio_max_p = 0.99996948242187;
    audio_max_n = -1;
    audio_min_p = (2^-15);
    audio_min_n = -(2^-15);
%     audio = zeros(1000,1);
%     audio(10:100) = 0.1;
%     audio(101:300) = 0.9999; audio(301:500) = -1; audio(501:700) = 0.9999; audio(701:900) = -1;
%     audio(1001:1300) = 2*rem(1:300,2) - 1;
%     audio = [audio; (2^-15).*audio; audio;(2^-15).*audio];
%     audio = [1*sin(2*pi*1000*[0:1/fs:0.05]), 0.001*sin(2*pi*1000*[0:1/fs:0.05])];
%     audio = audio';
    audio(1:1500) = audio_max_p;
    audio(1501:3000) = audio_max_n;
    audio(3001:4500) = 2*rem(1:1500,2) - 1;
    audio(4501:6000) = 0;
    audio(6001:7500) = audio_min_p;
    audio(7501:9000) = audio_min_n;
    audio(9001:10500) = audio_min_p*(2*rem(1:1500,2)-1);
    audio = [audio,audio,audio,audio,audio_max_p*ones(1,9000),audio_max_n*ones(1,9000),2*rem(1:9000,2) - 1]';
%     audio = [0.1*sin(2*pi*1000*[0:1/fs:0.05]), sin(2*pi*1000*[0:1/fs:0.05]), zeros(1,2400), 0.001*sin(2*pi*1000*[0:1/fs:0.05])];
%     audio = [audio,audio,audio,audio,audio,audio,audio,audio,audio,audio,audio,audio,audio,audio,audio];
end

% --- Simulation parameters ---
ovs = 200;              % Oversampling factor
fs_sim = fs*ovs;        % Simulation frequency
ADC_res = 5;            % Resolution of the ADC in bit. This affects the size of the LUTs
ADC_res_G4 = 8;         % Resolution of the ADC channel used for the delay LUT
WL_RAM = 5;             % Number of 1-bit samples that are collected to one word
input_space = linspace(0,2^ADC_res-1,2^ADC_res);
input_space_G4 = linspace(0,2^ADC_res_G4-1,2^ADC_res_G4);
%delay_time = 0.602987104283718;      % Delay of the demodulator path in seconds
%max_delay = 0.602987104283718;       % To fit on BRAM, do not exceed this limit
% max_delay = 0.516 % if parity is used
delay_time = 0.603;
max_delay = 0.603;
model = 'tustin';       % Method used to convert s-domain TFs to z-domain TFs

% --- Default numeric settings ---
FP_len = 46;             % Word length for fixed point datatype (to be optimized by fixpoint tool)
FP_frac = FP_len-10;     % Fraction length for fixed point datatype (to be optimized by fixpoint tool)

% --- Fixed-point optimizer settings ---
e_rel = 0.001;          % Relative quantization error in percent
N_max = 128;            % Highest allowed word length of filter coefficients

% --- Poti positions ---
Rvar1 = 24e3;           % P1 = 25e3, do not exceed. Resistance between node 22 and 23, lower = more feedback
Rvar2 = 9e3;            % P2 = 10e3, do not exceed. Resistance between node 23 and 25, lower = more influence
Rvar3 = 49e3;           % P3 = 50e3, do not exceed. Resistance between node 23 and 24, lower = louder
Rvar4 = 49e3;           % P3 = 50e3, do not exceed.

% --- Poti Stimuli (change poti value during simulation ---
use_stimuli = [true,true,true,true];     % false = fixed values for potis during simulation, based on "Poti positions" above

poti_stimuli1(1:10500) = 2^ADC_res-1;
poti_stimuli1(10501:21000) = 0;
poti_stimuli1(21001:31500) = 2^ADC_res-1;
poti_stimuli1(31501:42000) = 0;
poti_stimuli1(42001:132000) = 0;

poti_stimuli2(1:10500) = 2^ADC_res-1;
poti_stimuli2(10501:21000) = 2^ADC_res-1;
poti_stimuli2(21001:31500) = 0;
poti_stimuli2(31501:42000) = 0;
poti_stimuli2(42001:132000) = 0;

poti_stimuli3(1:10500) = 2^ADC_res-1;
poti_stimuli3(10501:21000) = 0;
poti_stimuli3(21001:31500) = 2^ADC_res-1;
poti_stimuli3(31501:42000) = 0;
poti_stimuli3(42001:132000) = 0;

%poti_stimuli4(1:10500) = 2^ADC_res_G4-1;
poti_stimuli4(1:10500) = 0;
poti_stimuli4(10501:21000) = 0;
poti_stimuli4(21001:31500) = 0;
poti_stimuli4(31501:42000) = 0;
poti_stimuli4(42001:96000) = 0;
poti_stimuli4(96000:132000) = 2^ADC_res_G4-1;

% --- Satturation limits of opamps ---
limit_Faux = 4.5;     % Op-amps outside of the PT2399, supplied with 9V (+/- 4.5V)
limit_PT2399 = 2.5;   % Op-amps inside of the PT2399, supplied with 5V (+/- 2.5V)

%-------------------------------------------------------
%------------------ END USER SETTINGS ------------------
%-------------------------------------------------------

%  NEW FOR BUFFERED RAM (Simulink model V2 only)
demdelay = ceil(delay_time*fs_sim / WL_RAM);
counter_limit = demdelay + 24;
RAM_address_bitwidth = ceil(log2(counter_limit));

%---- LUT for variable delay ----
dmin = 29.7625192133726e-3;     % Min Delay when Gvar4_N = 0
dmax = max_delay;               % Max Delay, specified by used according to BRAM recources
tdn = linspace(dmin,dmax,2^ADC_res_G4);
%LUT_Delay = floor(tdn.*fs_sim);
LUT_Delay = floor(tdn.*fs_sim./WL_RAM);
LUT_Delay = fi(LUT_Delay,0,RAM_address_bitwidth,0);

%--- LUT for clock divider ---
f_clk = fs_sim;
shift_reg_size = 4*44000;
f_vco = shift_reg_size./tdn;
ovs_clk_ext = 1;
LUT_cd = round(f_clk*ovs_clk_ext./f_vco)-1;
for k=1:length(LUT_cd)
    if LUT_cd(k)<1
        LUT_cd(k) = 1;
    end
end
LUT_cd_res = ceil(log2(max(LUT_cd)));
LUT_cd = fi(LUT_cd,0,LUT_cd_res,0);


%----- Prepare data -----
if load_audio_sample == true
    %audio = (audio_stereo(:,1)+audio_stereo(:,2))./2;  % Convert to Mono
    % audio = audio_stereo;                               % If samples are already Mono
end
audio = sfi(audio,16, 15);          % CAREFUL REAL AUDIO REPRESENTATION, SATTURATES AT +/-1
t = 1/fs .* [0:length(audio)-1]';
sim_time = 1/fs * length(audio);
simin.time = t;
simin.signals.values = audio;
simin.signals.dimenstions = 1;

%----- Potis -----
P1 = 25e3;
P2 = 10e3;
P3 = 50e3;
P4 = 50e3;

%----- ADC -----
Dmax = 2^ADC_res -1;

%---- Slicing ----
step_P1 = P1 / (2^ADC_res+1);
step_P2 = P2 / (2^ADC_res+1);
step_P3 = P3 / (2^ADC_res+1);
step_P4 = P4 / (2^ADC_res+1);

range_P1 = 0:step_P1:P1;
range_P2 = 0:step_P2:P2;
range_P3 = 0:step_P3:P3;
range_P4 = 0:step_P4:P4;

LUT_Gvar1 = 1./range_P1(2:end-1);
LUT_Gvar2 = 1./range_P2(2:end-1);
LUT_Gvar3 = 1./range_P3(2:end-1);
LUT_Gvar4 = 1./range_P4(2:end-1);

LUT_Gvar1_reversed = fliplr(LUT_Gvar1);
LUT_Gvar2_reversed = fliplr(LUT_Gvar2);
LUT_Gvar3_reversed = fliplr(LUT_Gvar3);
LUT_Gvar4_reversed = fliplr(LUT_Gvar4);

% Calculate Din with shifted index (only for simulation purpose)
Din1 = round(Rvar1 * 2^ADC_res / (P1-step_P1))-1;
Din2 = round(Rvar2 * 2^ADC_res / (P2-step_P2))-1;
Din3 = round(Rvar3 * 2^ADC_res / (P3-step_P3))-1;
Din4 = round(Rvar4 * 2^ADC_res / (P4-step_P4))-1;

Gvar1_N = Din1;
Gvar2_N = Din2;
Gvar3_N = Din3;
Gvar4_N = Din4;
Gvar1_N = 0;
Gvar2_N = 2^ADC_res-1;
Gvar3_N = 0;
Gvar4_N = 2^ADC_res_G4-1;

Gvar1_N = fi(Gvar1_N,0,ADC_res,0);
Gvar2_N = fi(Gvar2_N,0,ADC_res,0);
Gvar3_N = fi(Gvar3_N,0,ADC_res,0);
Gvar4_N = fi(Gvar4_N,0,ADC_res_G4,0);

len1 = findMinWordLenght(LUT_Gvar1,e_rel,N_max);
len2 = findMinWordLenght(LUT_Gvar2,e_rel,N_max);
len3 = findMinWordLenght(LUT_Gvar3,e_rel,N_max);
len4 = findMinWordLenght(LUT_Gvar4,e_rel,N_max);
LUT_Gvar1_opt = sfi(LUT_Gvar1, len1);
LUT_Gvar2_opt = sfi(LUT_Gvar2, len2);
LUT_Gvar3_opt = sfi(LUT_Gvar3, len3);
LUT_Gvar4_opt = sfi(LUT_Gvar4, len4);
len1 = findMinWordLenght(LUT_Gvar1_reversed,e_rel,N_max);
len2 = findMinWordLenght(LUT_Gvar2_reversed,e_rel,N_max);
len3 = findMinWordLenght(LUT_Gvar3_reversed,e_rel,N_max);
len4 = findMinWordLenght(LUT_Gvar4_reversed,e_rel,N_max);
LUT_Gvar1_reversed_opt = sfi(LUT_Gvar1_reversed, len1);
LUT_Gvar2_reversed_opt = sfi(LUT_Gvar2_reversed, len2);
LUT_Gvar3_reversed_opt = sfi(LUT_Gvar3_reversed, len3);
LUT_Gvar4_reversed_opt = sfi(LUT_Gvar4_reversed, len4);

%----- op amps -----
w1 = 1e6;
w2 = NaN;           % Modelled as ideal comparator?
w3 = 1e6;
w4 = 1e6;
w5 = 1e6;
w6 = NaN;           % Not used in signal path
w7 = 2*pi*3e6;
w8 = 2*pi*3e6;

%----- Nummerical values of components -----
G0 = 1/4.7e3;
G1 = 1/4.7e3;
G2 = 1/511e3;
G3 = NaN;           % Not used in signal path
G4 = 1/1e6;
G5 = 1/22e3;
G6 = NaN;           % Not used in signal path
G7 = 1/12e3;
G8 = 1/470;
G9 = 1/100e3;      
G10 = 1/12e3;
G11 = 1/12e3;
G12 = 1/12e3;
G13 = 1/47e3;
G14 = 1/22e3;
G15 = 1/12e3;
G16 = 1/12e3;
G17 = 1/12e3;
G18 = 1/2.7e3;
G19 = 1/20e3;
G20 = 1/10e3;
G21 = 1/10e3;

C1 = 100e-9;
C2 = 5e-12;
C3 = 47e-12;
C4 = 1e-9;
C5 = 100e-12;
C6 = 1e-6;
C7 = 1e-6;
C8 = 10e-9;
C9 = 10e-9;
C10 = 680e-12;
C11 = 1e-9;
C12 = 68e-9;
C13 = 150e-9;
C14 = 10e-9;
C15 = 10e-9;
C16 = 10e-9;
C17 = 1e-6;
C18 = 100e-9;
C19 = 68e-9;
C20 = 1e-6;
C21 = 100e-12;

%----- Mod & Dem ----- 
Gmod = 0.00096;
Gdem = 0.00096;


%----- Driving point admittance -----
y1 = G2 + s*C1;
y2 = G2 + G4 + s*C2 + s*C3;
y3 = NaN;                       % Real V-Source at this node
y4 = G5 + G7 + G21 + s*C4 + s*C5;
y5 = NaN;                       % Real V-Source at this node
y6 = G8 + s*C6;
y7 = G10 + s*C7;
y8 = G10 + G11 + G19 + s*C8;
y9 = NaN;                       % Real V-Source at this node
y10 = G0 + s*C13;
y11 = G1 + s*C12;
y12 = NaN;                      % Real V-Source at this node
y13 = G15 + s*C11;
y14 = NaN;                      % Real V-Source at this node
y15 = NaN;                      % Real V-Source at this node
y16 = G12 + s*C10;
y17 = NaN;                      % Real V-Source at this node
y18 = NaN;                      % Unknown
y19 = NaN;                      % Unknown
y20 = G11 + G12 + G13 + s*C9;
y21 = G19 + s*C18;
% y22 = 1/Rvar1 + 1/(P1-Rvar1) + s*C18;
% y23 = 1/Rvar1 + 1/Rvar3 + 1/(P2-Rvar2) + s*C17;
% y24 = 1/Rvar3 + 1/(P3-Rvar3) + s*C20;
% y25 = 1/(P2-Rvar2) + s*C19;
% y22_C = 1/Rvar1 + 1/(P1-Rvar1);
% y24_C = 1/Rvar3 + 1/(P3-Rvar3);
y26 = G20 + G21 + s*C21;
y27 = G20 + s*C20;
y28 = G18 + s*C16 + s*C17;
y29 = G14 + G15 + G17 + s*C15;
y30 = G16 + G17 + s*C14;
yout = G9 + s*C6;

% ---- LUT's for driving-point impedances ----

% --- LUT Z22 ---
LUT_Z22a = zeros(1,2^ADC_res);
LUT_Z22b = zeros(1,2^ADC_res);
for k=1:2^ADC_res
    LUT_Z22a(k) = 1/(2*C18*fs_sim + LUT_Gvar1(k) + LUT_Gvar1_reversed(k));
    LUT_Z22b(k) = (LUT_Gvar1(k) + LUT_Gvar1_reversed(k)-2*C18*fs_sim)/(2*C18*fs_sim + LUT_Gvar1(k) + LUT_Gvar1_reversed(k));
end
len_LUT22a = findMinWordLenght(LUT_Z22a,e_rel*0.1,N_max);   % stricter error here
len_LUT22b = findMinWordLenght(LUT_Z22b,e_rel*0.1,N_max);
LUT_Z22a_opt = sfi(LUT_Z22a, len_LUT22a);
LUT_Z22b_opt = sfi(LUT_Z22b, len_LUT22b);

% --- LUT Z24 ---
LUT_Z24a = zeros(1,2^ADC_res);
LUT_Z24b = zeros(1,2^ADC_res);
for k=1:2^ADC_res
    LUT_Z24a(k) = 1/(LUT_Gvar3(k) + LUT_Gvar3_reversed(k)+2*C20*fs_sim);
    LUT_Z24b(k) = (LUT_Gvar3(k) + LUT_Gvar3_reversed(k)-2*C20*fs_sim)/(LUT_Gvar3(k) + LUT_Gvar3_reversed(k)+2*C20*fs_sim);
end
len_LUT24a = findMinWordLenght(LUT_Z24a,e_rel*0.1,N_max);   % stricter error here
len_LUT24b = findMinWordLenght(LUT_Z24b,e_rel*0.1,N_max);
LUT_Z24a_opt = sfi(LUT_Z24a, len_LUT24a);
LUT_Z24b_opt = sfi(LUT_Z24b, len_LUT24b);

% --- LUT Z25 ---
LUT_Z25a = zeros(1,2^ADC_res);
LUT_Z25b = zeros(1,2^ADC_res);
for k=1:2^ADC_res
    LUT_Z25a(k) = 1/(LUT_Gvar2_reversed(k)+2*C19*fs_sim);
    LUT_Z25b(k) = (LUT_Gvar2_reversed(k)-2*C19*fs_sim)/(LUT_Gvar2_reversed(k)+2*C19*fs_sim);
end
len_LUT25a = findMinWordLenght(LUT_Z25a,e_rel*0.1,N_max);   % stricter error here
len_LUT25b = findMinWordLenght(LUT_Z25b,e_rel*0.1,N_max);
LUT_Z25a_opt = sfi(LUT_Z25a, len_LUT25a);
LUT_Z25b_opt = sfi(LUT_Z25b, len_LUT25b);

% ---- Z23 ----
N_adc = 2^ADC_res;
N_ext = ceil(log2((2^ADC_res)^3));      % Data type for new indexing
input_spcae_extended = linspace(0,(2^ADC_res)^3-1,(2^ADC_res)^3);

LUT_Z23a = zeros(1,N_adc*N_adc*N_adc);
LUT_Z23b = zeros(1,N_adc*N_adc*N_adc);

cnt = 1;
for m=1:2^ADC_res           % Index for 'z' (Gvar3_N)
    for l=1:2^ADC_res       % Index for 'y' (Gvar2_N)
        for k=1:2^ADC_res   % Index for 'x' (Gvar1_N)
            LUT_Z23a(cnt) = 1/(LUT_Gvar1(k) + LUT_Gvar2_reversed(l) + LUT_Gvar3(m) + 2*C17*fs_sim);
            LUT_Z23b(cnt) = (LUT_Gvar1(k) + LUT_Gvar2_reversed(l) + LUT_Gvar3(m) - 2*C17*fs_sim)/(LUT_Gvar1(k) + LUT_Gvar2_reversed(l) + LUT_Gvar3(m)+2*C17*fs_sim);
            cnt = cnt + 1;
        end
    end
end
len_Z23a = findMinWordLenght(LUT_Z23a,e_rel*0.1,N_max);
len_Z23b = findMinWordLenght(LUT_Z23b,e_rel*0.1,N_max);
LUT_Z23a_opt = sfi(LUT_Z23a, len_Z23a);
LUT_Z23b_opt = sfi(LUT_Z23b, len_Z23b);

%test
% LUT_dummy = sfi(randn(1,2^12), 32);
% LUT_dummy2 = sfi(randn(1,2^6), 32);
% LUT_dummy3D = sfi(LUT_Z23b, 32);

% ----- Calculate z transfer functions -----
Ts_transform = 1/fs_sim;

% [N1 D1] = tfdata(c2d(1/y1, Ts_transform, model),'v');
% N1 = sfi(N1,FP_len, FP_frac);
% D1 = sfi(D1,FP_len, FP_frac);
% [N2 D2] = tfdata(c2d(1/y2, Ts_transform, model),'v');
% N2 = sfi(N2,FP_len, FP_frac);
% D2 = sfi(D2,FP_len, FP_frac);
%[N3 D3]
[N4 D4] = tfdata(c2d(1/y4, Ts_transform, model),'v');
len_N = findMinWordLenght(N4,e_rel,N_max);
len_D = findMinWordLenght(D4,e_rel,N_max);
N4_opt = sfi(N4,len_N); N4_WL = N4_opt.WordLength; N4_FL = N4_opt.FractionLength;
D4_opt = sfi(D4,len_D); D4_WL = D4_opt.WordLength; D4_FL = D4_opt.FractionLength;
%[N5 D5]
% [N6 D6] = tfdata(c2d(1/y6, Ts_transform, model),'v');
% N6 = sfi(N6,FP_len, FP_frac);
% D6 = sfi(D6,FP_len, FP_frac);
[N7 D7] = tfdata(c2d(1/y7, Ts_transform, model),'v');
len_N = findMinWordLenght(N7,e_rel,N_max);
len_D = findMinWordLenght(D7,e_rel,N_max);
N7_opt = sfi(N7,len_N); N7_WL = N7_opt.WordLength; N7_FL = N7_opt.FractionLength;
D7_opt = sfi(D7,len_D); D7_WL = D7_opt.WordLength; D7_FL = D7_opt.FractionLength;
[N8 D8] = tfdata(c2d(1/y8, Ts_transform, model),'v');
len_N = findMinWordLenght(N8,e_rel,N_max);
len_D = findMinWordLenght(D8,e_rel,N_max);
N8_opt = sfi(N8,len_N); N8_WL = N8_opt.WordLength; N8_FL = N8_opt.FractionLength;
D8_opt = sfi(D8,len_D); D8_WL = D8_opt.WordLength; D8_FL = D8_opt.FractionLength;
%[N9 D9]
[N10 D10] = tfdata(c2d(1/y10, 1/fs_sim, model),'v');
[N10_opt,D10_opt,N10_WL,N10_FL,D10_WL,D10_FL] = findOptimizedCoefficients(N10,D10,e_rel,N_max);
[N11 D11] = tfdata(c2d(1/y11, 1/fs_sim, model),'v');
[N11_opt,D11_opt,N11_WL,N11_FL,D11_WL,D11_FL] = findOptimizedCoefficients(N11,D11,e_rel,N_max);
%[N12 D12]
[N13 D13] = tfdata(c2d(1/y13, Ts_transform, model),'v');
[N13_opt,D13_opt,N13_WL,N13_FL,D13_WL,D13_FL] = findOptimizedCoefficients(N13,D13,e_rel,N_max);
%[N14 D14] = tfdata(c2d(1/y14, Ts_transform, model),'v');
%[N15 D15]
[N16 D16] = tfdata(c2d(1/y16, Ts_transform, model),'v');
[N16_opt,D16_opt,N16_WL,N16_FL,D16_WL,D16_FL] = findOptimizedCoefficients(N16,D16,e_rel,N_max);
%[N17 D17]
%[N18 D18]
%[N19 D19]
[N20 D20] = tfdata(c2d(1/y20, Ts_transform, model),'v');
[N20_opt,D20_opt,N20_WL,N20_FL,D20_WL,D20_FL] = findOptimizedCoefficients(N20,D20,e_rel,N_max);
[N21 D21] = tfdata(c2d(1/y21, Ts_transform, model),'v');
[N21_opt,D21_opt,N21_WL,N21_FL,D21_WL,D21_FL] = findOptimizedCoefficients(N21,D21,e_rel,N_max);
% [N22 D22] = tfdata(c2d(tf(1/y22_C), Ts_transform, model),'v');
% N22 = sfi(N22,FP_len, FP_frac);
% D22 = sfi(D22,FP_len, FP_frac);
% [N23 D23] = tfdata(c2d(1/y23, Ts_transform, model),'v');
% N23 = sfi(N23,FP_len, FP_frac);
% D23 = sfi(D23,FP_len, FP_frac);
% [N24 D24] = tfdata(c2d(tf(1/y24_C), Ts_transform, model),'v');
% N24 = sfi(N24,FP_len, FP_frac);
% D24 = sfi(D24,FP_len, FP_frac);
% [N25 D25] = tfdata(c2d(1/y25, Ts_transform, model),'v');
% N25 = sfi(N25,FP_len, FP_frac);
% D25 = sfi(D25,FP_len, FP_frac);
[N26 D26] = tfdata(c2d(1/y26, Ts_transform, model),'v');
[N26_opt,D26_opt,N26_WL,N26_FL,D26_WL,D26_FL] = findOptimizedCoefficients(N26,D26,e_rel,N_max);
[N27 D27] = tfdata(c2d(1/y27, Ts_transform, model),'v');
[N27_opt,D27_opt,N27_WL,N27_FL,D27_WL,D27_FL] = findOptimizedCoefficients(N27,D27,e_rel,N_max);
[N28 D28] = tfdata(c2d(1/y28, Ts_transform, model),'v');
[N28_opt,D28_opt,N28_WL,N28_FL,D28_WL,D28_FL] = findOptimizedCoefficients(N28,D28,e_rel,N_max);

[N29 D29] = tfdata(c2d(1/y29, Ts_transform, model),'v');
[N29_opt,D29_opt,N29_WL,N29_FL,D29_WL,D29_FL] = findOptimizedCoefficients(N29,D29,e_rel,N_max);
[N30 D30] = tfdata(c2d(1/y30, Ts_transform, model),'v');
[N30_opt,D30_opt,N30_WL,N30_FL,D30_WL,D30_FL] = findOptimizedCoefficients(N30,D30,e_rel,N_max);
% [Nout Dout] = tfdata(c2d(1/yout, Ts_transform, model),'v');
% Nout = sfi(Nout,FP_len, FP_frac);
% Dout = sfi(Dout,FP_len, FP_frac);

% --- Simplifications ---

% Simplification 1
% Path from Vin to V3
[Ncs1 Dcs1] = tfdata(c2d(tf([-C1*G2*w7,0],[C1*C2 + C1*C3, C1*G2 + C2*G2 + C1*G4 + C3*G2 + C1*C2*w7, G2*G4 + C2*G2*w7 + C1*G4*w7, G2*G4*w7]), Ts_transform, model),'v');
len_N = findMinWordLenght(Ncs1,e_rel,N_max);
len_D = findMinWordLenght(Dcs1,e_rel,N_max);
Ncs1_opt = sfi(Ncs1,len_N); Ncs1_WL = Ncs1_opt.WordLength; Ncs1_FL = Ncs1_opt.FractionLength;
Dcs1_opt = sfi(Dcs1,len_D); Dcs1_WL = Dcs1_opt.WordLength; Dcs1_FL = Dcs1_opt.FractionLength;

% Simplification 2
% Path from V5 to Vout -> (G8/y6*s*C6/yout) / (1-s*C6*s*C6/y6/yout)
[Ncs2 Dcs2] = tfdata(c2d(tf([-C6*G8, 0],[-C6*G8-C6*G9, -G8*G9]), Ts_transform, model),'v');
len_N = findMinWordLenght(Ncs2,e_rel*0.01,N_max);
len_D = findMinWordLenght(Dcs2,e_rel*0.01,N_max); % This one need more precision
Ncs2_opt = sfi(Ncs2,len_N); Ncs2_WL = Ncs2_opt.WordLength; Ncs2_FL = Ncs2_opt.FractionLength;
Dcs2_opt = sfi(Dcs2,len_D); Dcs2_WL = Dcs2_opt.WordLength; Dcs2_FL = Dcs2_opt.FractionLength;

% Simplification 3
% Path from V12 to V14
% [Ncs3 Dcs3] = tfdata(c2d(tf([G15*G16*G17*w5],[-C11*C14*C15, - C11*C14*G14 - C11*C14*G15 - C11*C14*G17 - C11*C15*G16 - C11*C15*G17 - C14*C15*G15 - C11*C14*C15*w5, - C11*G14*G16 - C11*G14*G17 - C11*G15*G16 - C11*G15*G17 - C14*G14*G15 - C11*G16*G17 - C14*G15*G17 - C15*G15*G16 - C15*G15*G17 - C11*C14*G14*w5 - C11*C14*G15*w5 - C11*C14*G17*w5 - C11*C15*G16*w5 - C11*C15*G17*w5, - G14*G15*G16 - G14*G15*G17 - G15*G16*G17 - C11*G14*G16*w5 - C11*G14*G17*w5 - C11*G15*G16*w5 - C11*G15*G17*w5 - C14*G14*G15*w5 - C11*G16*G17*w5, - G14*G15*G16*w5 - G14*G15*G17*w5]), Ts_transform, model),'v');
% Ncs3 = sfi(Ncs3,FP_len, FP_frac);
% Dcs3 = sfi(Dcs3,FP_len, FP_frac);
%% ----- Start Simulink Model -----
tic
out = sim(sim_name, 'StartTime', '0','StopTime',num2str(sim_time),'FixedStep','1/(fs_sim)');
toc

%% ----- Evaluate results -----
t_axis_low_fs = out.output_signal.time;
output_signal = out.output_signal.data;
input_signal = out.input_signal.data;

t_axis_high_fs = out.decicion_comparator.time;
decicion_comparator = out.decicion_comparator.data;
output_dem = out.output_dem.data;
comparator_input_n = out.comparator_input_n.data;
comparator_input_p = out.comparator_input_p.data;
delay_line_output = out.delay_line_output.data;

%----- Visualize Input and output -----
plot(t_axis_low_fs, input_signal);
grid on
hold on
plot(t_axis_low_fs, output_signal);
title('Input vs output signal')
legend('Input','Output')
xlabel('Time [s]')

%----- Visualize Other interesting signals -----
figure
plot(t_axis_high_fs,decicion_comparator)
grid on
title('Decicion Comparator')
xlabel('Time [s]')
ylabel('Logic level')
figure
plot(t_axis_high_fs,output_dem)
grid on
title('Output Demodulator')
xlabel('Time [s]')
figure
plot(t_axis_high_fs,comparator_input_n)
grid on
hold on
plot(t_axis_high_fs,comparator_input_p)
title('Input Comparator')
legend('Negative Input','Positive Input')
xlabel('Time [s]')

%----- Output of all opamps -----
opamp1 = out.opamp_out1.data;
opamp3 = out.opamp_out3.data;
opamp4 = out.opamp_out4.data;
opamp5 = out.opamp_out5.data;
opamp7 = out.opamp_out7.data;
opamp8 = out.opamp_out8.data;
figure
plot(t_axis_high_fs, opamp1)
grid on
hold on
plot(t_axis_high_fs, opamp3)
plot(t_axis_high_fs, opamp4)
plot(t_axis_high_fs, opamp5)
plot(t_axis_high_fs, opamp7)
plot(t_axis_high_fs, opamp8)
title('output of all opamps')
xlabel('Time [s]')
legend('opamp 1 (input LPF)','opamp 3 (Feedback Mod)','opamp 4 (LPF Dem)','opamp 5 (second LPF output)','opamp 7 (pre amp)','opamp 8 (opamp7 + opamp5)')

% ---- RAM pointers and Poti values (digitized) ----
% write_pointer = out.write_pointer.data;
% read_pointer = out.read_pointer.data;
Gvar1_N_sim = out.Gvar1_N_sim.data;
Gvar2_N_sim = out.Gvar2_N_sim.data;
Gvar3_N_sim = out.Gvar3_N_sim.data;
Gvar4_N_sim = out.Gvar4_N_sim.data;
samples_fs_high = out.Gvar1_N_sim.time;
samples_fs_low = out.Gvar4_N_sim.time;
% figure
% plot(samples_fs_high,write_pointer)
% hold on
% plot(samples_fs_high,read_pointer)
figure
plot(samples_fs_high,Gvar1_N_sim)
hold on
plot(samples_fs_high,Gvar2_N_sim)
plot(samples_fs_high,Gvar3_N_sim)
plot(samples_fs_low,Gvar4_N_sim)
legend('P1','P2','P3','P4')

%----- Comparison of poti signals -----
% poti_in = out.V23.data;
% poti1_out = out.V22.data;
% poti2_out = out.V25.data;
% poti3_out = out.V24.data;
% v28 = out.V28.data;
% figure
% plot(t_axis_high_fs, poti_in)
% grid on
% hold on
% plot(t_axis_high_fs, poti1_out)
% plot(t_axis_high_fs, poti2_out)
% plot(t_axis_high_fs, poti3_out)
% legend('in','out Poti 1','out Poti 2','out Poti 3')
% plot(t_axis_high_fs, v28)

%----- Show power density of output -----
figure
nx = max(size(double(output_signal)));
na = 16;
w = hanning(floor(nx/na));
pwelch(double(output_signal),w,0,[],fs);
grid on