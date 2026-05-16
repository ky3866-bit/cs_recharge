% plot_simulation_results.m
% Extracts and plots the transient physics data from the CS recharge simulation

function plot_simulation_results(simout)
% If no input argument is provided, try to find 'simout' in the base workspace
if nargin < 1
    try
        simout = evalin('base', 'simout');
    catch
        error('No simulation output found. Please run the simulation first (e.g., simout = sim(''cs_recharge_model'')).');
    end
end

%% 1. Extract Time-Series Datasets
time  = simout.Ip_out.Time;
Ip    = simout.Ip_out.Data;
Ic    = simout.Ic_out.Data;
Vloop = simout.Vloop_out.Data;
f_bs  = simout.fbs_out.Data;

%% 2. Configure High-Fidelity Figure Layout
figure('Color', [1 1 1], 'Position', [200, 100, 850, 750]);

% Global plotting properties
lineWidth = 2.5;
labelFontSize = 11;
axisFontSize = 10;

%% Subplot 1: Plasma Current (Ip)
subplot(4, 1, 1);
plot(time, Ip / 1e6, 'b-', 'LineWidth', lineWidth);
grid on; hold on;
% Mark the transition point (t = 200s)
xline(200, 'k--', 'DT Overdrive Active', 'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.5);
ylabel('I_p (MA)', 'FontWeight', 'bold', 'FontSize', labelFontSize);
title('FAST Tokamak: Central Solenoid Recharging Dynamics', 'FontSize', 13, 'FontWeight', 'bold');
set(gca, 'FontSize', axisFontSize);

%% Subplot 2: Central Solenoid Current (Ic)
subplot(4, 1, 2);
plot(time, Ic / 1e3, 'r-', 'LineWidth', lineWidth);
grid on; hold on;
xline(200, 'k--', 'LineWidth', 1.5);
ylabel('I_{CS} (kA)', 'FontWeight', 'bold', 'FontSize', labelFontSize);
set(gca, 'FontSize', axisFontSize);

%% Subplot 3: Loop Voltage (Vloop)
subplot(4, 1, 3);
plot(time, Vloop, 'm-', 'LineWidth', lineWidth);
grid on; hold on;
% Highlight the zero crossover line where charging begins
plot(time, zeros(size(time)), 'k-', 'LineWidth', 1); 
xline(200, 'k--', 'LineWidth', 1.5);
ylabel('V_{loop} (V)', 'FontWeight', 'bold', 'FontSize', labelFontSize);
set(gca, 'FontSize', axisFontSize);

%% Subplot 4: Self-Generated Bootstrap Current Fraction (f_bs)
subplot(4, 1, 4);
plot(time, f_bs * 100, 'g-', 'LineWidth', lineWidth);
grid on; hold on;
xline(200, 'k--', 'LineWidth', 1.5);
xlabel('Time (seconds)', 'FontWeight', 'bold', 'FontSize', labelFontSize);
ylabel('Bootstrap % (f_{bs})', 'FontWeight', 'bold', 'FontSize', labelFontSize);
set(gca, 'FontSize', axisFontSize);

%% 3. Clean up Layout Spatial Margins
linkaxes(get(gcf, 'Children'), 'x'); % Sync zoom across all subplots
xlim([0, max(time)]);
end