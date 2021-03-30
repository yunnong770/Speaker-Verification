%************************************************
%*  Name:  Yu Nong          Date:  10/30/2017   *
%*  Seat/Table: C       File:  Class_12_App.m   *
%*  Instructor: Dr. Bixler                      *
%************************************************

%% Problem 1   
clc, clear
% d = fluid density
% V = fluid velocity
% D = characteristic  length
% u = dynamic viscocity
% Re = Reynolds number
% Name = user's name
Name = input('Please enter your name:','s');% Get user's name
d = input('Please enter a value as fluid density:');% Get fluid density by user input
u = input('Please enter a value as dynamic viscocity:');% Get dynamic viscocity bu user input
V = input('Please enter a value as fluid velocity:');% Get fluid density by suer input
D = input('Please enter a value as characteristic length:');% Get characteristic length by user input
Re = d*V*D/u;% equation for calculating Reynold number

% print out user input and calculation result for Reynold number
fprintf('**********************************Output**********************************\n')
fprintf('Name: %s\n', Name)
fprintf('\nDensity=%.4f kg/m^3',d)
fprintf('\nViscocity=%.4e Pa*s' ,u)
fprintf('\nVelocity=%.2f m/s',V)
fprintf('\nCharacterisctic Length=%.2f m\n',D)
fprintf('\nThe Reynolds number for this fluid flow is Re=%.4e\n',Re)
fprintf('**************************************************************************\n')

%% Problem 2
time = load('Class15_time.txt');%load time data into vector time
voltage = load('Class15_voltage.txt');%load voltage data into vector voltage
figure(1)% make it as figure 1
plot(time,voltage)% plot the graph
xlabel('Time(s)')% change the label on x axis
ylabel('Voltage(mV)')% change the label on y axis
title('Relationship between time and voltage')% modify the title
legend('time vs voltage','Location','NorthEast')% modify the legends

%% Problem 3
figure(2)% make it as figure 2 so that the first graph won't be closed
time_1 = load('Class15_TimeWalk.txt');%load time data for walking into vector time_1
forceWalk = load('Class15_ForceWalk.txt');% load force data for walking into vector forceWalk
time_2 = load('Class15_TimeRun.txt');%load time data for walking into vector time_2
forceRun = load('Class15_ForceRun.txt');% load force data for running into vector forceRun
plot(time_1,forceWalk,'-r*',time_2,forceRun,'-bo');% plot the graphs and change color to make it distinguishable and add markers on it
xlabel('Time(s)')% modify the label on x axis
ylabel('Force(N)')% modify the label on y axis
title('Force exerted on foot')% change the title
legend('Walking','Running','Location','NorthEast')% change the legend and re-position it