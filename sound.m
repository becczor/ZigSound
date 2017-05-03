% Tested exponential for increasing in every step
x = 1:30;
y = 0.5*1.105.^x;

plot(x,y,'b')
grid on
hold on

% Tested values that works okey
z1 = [ 30, 38, 46, 54, 62, 70, 78, 86, 94, 102, 110, 120, 130, 140, 152, 166, 180, 195, 211, 230, 252, 275, 300, 330, 370, 410, 460, 520, 590, 660];
z = z1 ./60.00;

plot(x, z, 'r*')
hold on

% Wolfram approximation
% exponential fit 30, 38, 46, 54, 62, 70, 78, 86, 94, 102, 110, 120, 130, 140, 152, 166, 180, 195, 211, 230, 252, 275, 300, 330, 370, 410, 460, 520, 590, 660
q = 33.3473* exp(0.0980481.*x);

plot(x, q, 'g')
%% Tables for setting sound manually
bpm = [ 30, 38, 46, 54, 62, 70, 78, 86, 94, 102, 110, 120, 130, 140, 152, 166, 180, 195, 211, 230, 252, 275, 300, 330, 370, 410, 460, 520, 590, 660];
Hz_beat = bpm ./60.00;

% Multiply with 0.5 for 50% duty cycle
div_beat = round((power(10,6)*0.5) ./ Hz_beat);


x = 1:40;
Hz_freq = 440+25.*x;
% Multiply with 0.5 for 50% duty cycle
div_freq = round((power(10,6)*0.5) ./ Hz_freq);







