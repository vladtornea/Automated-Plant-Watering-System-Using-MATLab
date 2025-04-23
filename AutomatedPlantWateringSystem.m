% Vlad Tornea 
% Automated Plant watering System

clear all; close all; 
a = arduino('COM3', 'Nano3'); 

%Max voltage = 3.5, - Dry Soil voltage was found to be 3.5 V 
%Min voltage = 2.4, - Wet soil voltage was found to be 2.4 V 
VoltageDry = 3.5; 
VoltageWet = 2.4; 

dry_max = 0;    %Set the most dry value to be 0 
wet_max = 100;  %Set the maximum moisture value to be 100

%Find equation to turn the Voltage values into user friendly values form 0 to 100 (0 for most dry, 100 for most wet):
%Calculate the slope first:
Slope = (dry_max - wet_max)/(VoltageDry - VoltageWet);  %Slope = Rise/Run 
%Moisture = slope.*(CurrentVoltage)+b (y = mx + b form)
%Find y-intercept (solve for b): 
%wet_max = Slope_m * VoltageWet + b
b = wet_max + abs(Slope)*VoltageWet; 

%Graph setup
figure 
movingline = animatedline;  %(Create an aimated line)
ax = gca;   %(current axes)
ax.YGrid = 'on'; 
ax.YLim = [0 110];  %set y-axis limits (from 0 to 110)
title('Moisture Level vs. Time')    %create title
xlabel('Time (HH/MM/SS)');  %label x-axis 
ylabel('Moisture Level (0 to 100)');    %label y-axis 

counts = 1;     %initialize count for state switch
countb = 1;     %initialize count to allow time for soil to absorb water before state initialization
stopbutton = false; %set up stop button 

while(~stopbutton)    %start while loop for sensor to take volatge reading as long as loop is true (while(~stop))

    Current_Voltage = readVoltage(a, 'A1');     %Read the current Voltage from moisture sensor

ml = ReadMoisture(Slope, Current_Voltage, b);   %call ReadMoisture function to convert sensor voltage to moisture level from 0 to 100

MoistureState = Read_Level(ml);     %Call Read_Level function to output the State of the soil moisture based on set up moisture intervals


t = datetime('now');    %for the graph read current time 
addpoints(movingline, datenum(t), ml)   %Add points to the moving line
%set limits for x-axis:
ax.XLim = datenum([t - seconds(15) t]); 
datetick('x', 'keeplimits')
drawnow  %draw and add to the graph

countb = countb + 1;    %countb will increase by 1 until it reaches 100
if countb == 100    %if loop will start if countb == 100

    if MoistureState == 1   %Dry moisture state (moisture interval between 0 to 40); if Dry state then water
        disp('The Soil is dry! It needs water!');   %Message in the command window to tell us that soil is in dry state 
        disp('Starting to water now!');     %Message in command window to tell us that the pump is startig to water 
        writeDigitalPin(a, 'D2', 1);    %Turn on pump 
        pause(2);   %Keep pump runnig for 2 seconds
        writeDigitalPin(a, 'D2', 0);    %Trun off pump
        counts = counts + 1;    %Increase counts by 1 

    elseif MoistureState == 2   %Semi-wet moisture state (moisture interval between 41 and 65); if Semi-wet state then water
      if counts >= 2    %Only start if counts >= 2 to ensure that pump will not turn on when soil goes from wet back to semi-wet
          %Pump will only turn on when soil goes from dry to semi-wet
          disp('The soil is semi-wet! It still needs more water!');   %Message in command window telling us Soil is in semi-wet state
          disp('Starting to water!')    %Message in command window to tell us pump will turn on
            writeDigitalPin(a, 'D2', 1); %Turn pump on
            pause(2);                    %Keep pump on for 2 seconds
            writeDigitalPin(a, 'D2', 0); %Turn off pump
      end
      
    elseif MoistureState == 3 %Wet moisture state (moisture interval between 65 and 100); if wet state then say no water needed, keep pump off
        disp('The soil is now saturated! No need to water!') %message in command window to say soil is in wet state
        counts = 1; %set counts back to 1 to allow pump to turn on when soil is dry again but to now allow it to turn on when soil is semi-wet again
    else 
        disp('Moisture Level out of scope') %Moisture state 4 (out of scope) Error state
    end
    countb = 1; %set countb back to 1 to allow proccess to start again
end
stopbutton = readDigitalPin(a, 'D6'); %check the stop button on the arduino pin D6
end

disp('Process Terminated'); %Display 'Process Terminated' in command window once program stops 

%Fnction to turn sensor voltage to values user friendly values from 0 to 100: 
function moisture_Level = ReadMoisture(Slope_m, CurrentVoltage, b)
moisture_Level = Slope_m.*(CurrentVoltage) + b; %equation to turn volatage fro sensor into values form 0 to 100
% 0 for most dry
% 100 for most wet
end 

%Function to set moisture level intervals and to set the states 
function MoistureState = Read_Level(moisture_level)
    if moisture_level <= 40 && moisture_level >= 0 % moisture interval from 0 and 40 
        MoistureState = 1; % State 1 (Dry soil state)
    elseif moisture_level >= 41 && moisture_level <= 65 % moisture interval from 41 to 65
        MoistureState = 2; % State 2 (Semi-wet soil state)
    elseif moisture_level > 65 && moisture_level <= 100 % moisture interval between 65 and 100
        MoistureState = 3; % State 3 (Wet soil state)
    else 
        MoistureState = 4; %Error state (out of scope); for when mositure sensor reads Volatages beyond the max and min voltages specified
        %(for when moisture is below 0 or above 100)
    end
end

% References: 
% [1] ee-diary. (2021, October 8). How to plot real time data from arduino in matlab. https://www.ee-diary.com/2021/10/how-to-plot-real-time-data-from-arduino.html 