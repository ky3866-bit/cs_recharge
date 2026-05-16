% run_simulation.m
% Main execution script to initialize, run, and plot the CS recharge model

clear; clc; close all;

fprintf('Step 1: Programmatically generating the Simulink file...\n');
create_simulink_model();

fprintf('Step 2: Executing transient simulation (1000s timeline)...\n');
% Run the correctly named model
simout = sim('fpp_cs_recharge_model');

fprintf('Step 3: Generating publication-ready plots...\n');
% Call your dedicated plotting script
plot_simulation_results(simout);

% Optional: Save data for the cluster workflow
save('tokamak_run_results.mat', 'simout');
fprintf('Success! All data saved to tokamak_run_results.mat\n');