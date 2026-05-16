% create_simulink_model.m
% Automatically builds the graphical Simulink model using string-based routing paths

function create_simulink_model()
    modelName = 'fpp_cs_recharge_model';
    
    % If the system is already open or exists, close it without saving
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    
    % Initialize a blank Simulink model layout
    new_system(modelName);
    open_system(modelName);
    
    % Set layout positioning parameters
    set_param(modelName, 'Solver', 'ode45', 'StopTime', '1000');
    
    % --- Add Source Blocks with clean spacing ---
    add_block('simulink/Sources/Step', [modelName '/Ini_Step'], 'Position', [50, 50, 100, 90]);
    set_param([modelName '/Ini_Step'], 'Time', '200', 'Before', '1.75e6', 'After', '9.5e6');
    
    add_block('simulink/Sources/Constant', [modelName '/Vc_Const'], 'Position', [50, 130, 100, 170]);
    set_param([modelName '/Vc_Const'], 'Value', '0');
    
    % --- Add Core Physics Block ---
    add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/Tokamak_Core_Physics'], 'Position', [220, 80, 360, 220]);
    
    % --- EXPLICIT PORT INITIALIZATION FOR STATEFLOW ---
    sf = sfroot;
    block = sf.find('Name', 'Tokamak_Core_Physics', '-isa', 'Stateflow.EMChart');
    
    % Clear default 'u' and 'y' ports to avoid layout conflicts
    existingData = block.find('-isa', 'Stateflow.Data');
    for k = 1:length(existingData)
        delete(existingData(k));
    end
    
    % Programmatically create the 4 required physical Input Ports
    inputs = {'Ini', 'Vc', 'Ip', 'Ic'};
    for k = 1:length(inputs)
        d = Stateflow.Data(block);
        d.Name = inputs{k};
        d.Scope = 'Input';
        d.DataType = 'double';
    end
    
    % Programmatically create the 4 required physical Output Ports
    outputs = {'dIp', 'dIc', 'Vloop', 'f_bs'};
    for k = 1:length(outputs)
        d = Stateflow.Data(block);
        d.Name = outputs{k};
        d.Scope = 'Output';
        d.DataType = 'double';
    end
    
    % Inject the custom physics code directly into the newly budgeted block
    block.Script = sprintf([ ...
        'function [dIp, dIc, Vloop, f_bs] = fcn(Ini, Vc, Ip, Ic)\n', ...
        '    %% FAST Tokamak Device Parameters\n', ...
        '    Lp = 5.0e-6;   %% Plasma self-inductance (H)\n', ...
        '    Lc = 0.5;      %% Central Solenoid self-inductance (H)\n', ...
        '    M  = 1.2e-3;   %% Mutual inductance (H)\n', ...
        '    Rp = 1.0e-8;   %% Plasma resistance\n', ...
        '    Rc = 0.0;      %% Superconducting HTS magnet resistance\n', ...
        '    Ip_nominal = 7.0e6; \n\n', ...
        '    %% State Derivatives Matrix Solution\n', ...
        '    denom = (Lp * Lc) - (M^2);\n', ...
        '    dIp = (Lc * Rp * (Ini - Ip) - M * (Vc - Rc * Ic)) / denom;\n', ...
        '    dIc = (-M * Rp * (Ini - Ip) + Lp * (Vc - Rc * Ic)) / denom;\n\n', ...
        '    %% Diagnostic Outputs\n', ...
        '    Vloop = Rp * (Ip - Ini);\n', ...
        '    f_bs = (Ini * 0.4) / Ip_nominal;\n', ...
        'end']);

    % --- Add State Integrators ---
    add_block('simulink/Continuous/Integrator', [modelName '/Ip_Integrator'], 'Position', [420, 90, 450, 120]);
    set_param([modelName '/Ip_Integrator'], 'InitialCondition', '7.0e6');
    
    add_block('simulink/Continuous/Integrator', [modelName '/Ic_Integrator'], 'Position', [420, 130, 450, 160]);
    set_param([modelName '/Ic_Integrator'], 'InitialCondition', '3.0e4');
    
    % --- Add Outport Sinks for Data Collection ---
    add_block('simulink/Sinks/To Workspace', [modelName '/Out_Ip'], 'Position', [520, 35, 580, 55]);
    set_param([modelName '/Out_Ip'], 'VariableName', 'Ip_out', 'SaveFormat', 'Timeseries');
    
    add_block('simulink/Sinks/To Workspace', [modelName '/Out_Ic'], 'Position', [520, 185, 580, 205]);
    set_param([modelName '/Out_Ic'], 'VariableName', 'Ic_out', 'SaveFormat', 'Timeseries');
    
    add_block('simulink/Sinks/To Workspace', [modelName '/Out_Vloop'], 'Position', [520, 115, 580, 135]);
    set_param([modelName '/Out_Vloop'], 'VariableName', 'Vloop_out', 'SaveFormat', 'Timeseries');
    
    add_block('simulink/Sinks/To Workspace', [modelName '/Out_f_bs'], 'Position', [520, 245, 580, 265]);
    set_param([modelName '/Out_f_bs'], 'VariableName', 'fbs_out', 'SaveFormat', 'Timeseries');

    % --- ROUTING VIA CORRECTED STRING FORMAT ---
    % Connect Inputs to Core Physics
    add_line(modelName, 'Ini_Step/1', 'Tokamak_Core_Physics/1', 'autorouting', 'on');
    add_line(modelName, 'Vc_Const/1', 'Tokamak_Core_Physics/2', 'autorouting', 'on');
    
    % Connect Derivatives to Integrators
    add_line(modelName, 'Tokamak_Core_Physics/1', 'Ip_Integrator/1', 'autorouting', 'on');
    add_line(modelName, 'Tokamak_Core_Physics/2', 'Ic_Integrator/1', 'autorouting', 'on');
    
    % Integrator State Feedback Loops back to Physics Inputs
    add_line(modelName, 'Ip_Integrator/1', 'Tokamak_Core_Physics/3', 'autorouting', 'on');
    add_line(modelName, 'Ic_Integrator/1', 'Tokamak_Core_Physics/4', 'autorouting', 'on');
    
    % Route Data Signals to Workspace Sinks
    add_line(modelName, 'Ip_Integrator/1', 'Out_Ip/1', 'autorouting', 'on');
    add_line(modelName, 'Tokamak_Core_Physics/3', 'Out_Vloop/1', 'autorouting', 'on');
    add_line(modelName, 'Ic_Integrator/1', 'Out_Ic/1', 'autorouting', 'on');
    add_line(modelName, 'Tokamak_Core_Physics/4', 'Out_f_bs/1', 'autorouting', 'on');
    
    % Clean up block presentation layout cleanly
    Simulink.BlockDiagram.arrangeSystem(modelName);
    
    % Save completed asset
    save_system(modelName);
    fprintf('Success: "fpp_cs_recharge_model.slx" built using correct ''autorouting'' parameters.\n');
end