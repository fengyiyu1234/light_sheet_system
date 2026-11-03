%This function writes a DC value to the Siglent AFG
%The input is in mv

function [dcValueAfterWrite] = SetAfg2DCValue(afg, dcValue)

    % Convert the input from mV to V, as Siglent expects Volts
    dcValue_V = dcValue / 1000;
    
    % --- Channel 1 ---
    % Change the state to DC and set the offset
    fprintf(afg, sprintf('C1:BSWV WVTP,DC,OFST,%f', dcValue_V));
    
    % Query the settings. (Note: Siglent returns all Basic Wave parameters, 
    % not just the offset, so dcValueAfterWrite will be a longer string)
    dcValueAfterWrite = query(afg, 'C1:BSWV?');
    
    % Turn on output 1
    fprintf(afg, 'C1:OUTP ON');    
    
    % --- Channel 2 ---
    % Change the state to DC and set the offset
    fprintf(afg, sprintf('C2:BSWV WVTP,DC,OFST,%f', dcValue_V));
    
    % Turn on output 2
    fprintf(afg, 'C2:OUTP ON');

end


