%This function establish com with the AFG3022B using Visa
%The output is the afg device object for visa com
%Default buffer size 5120, should be X*1024

function [afg2] = EstablishComAfg2(sizeOfBuffer)
    if (nargin == 0)
        sizeOfBuffer = 200000; % Increased to 200KB for Waveform Uploads
    end
    
    % Tektronix
    % afg2 = visa('ni', 'USB0::0x0699::0x0356::C011307::INSTR', 'InputBufferSize',sizeOfBuffer,'OutputBufferSize',sizeOfBuffer);
    % Rigol DG4102
    % afg2 = visa('ni', 'USB0::0x1AB1::0x0641::DG4E184350146::INSTR', 'InputBufferSize',sizeOfBuffer,'OutputBufferSize',sizeOfBuffer);
    % Siglent SDG1022X PLUS
    afg2 = visa('ni', 'USB0::0xF4EC::0x1103::SDG1PA0C900516::INSTR', 'InputBufferSize',sizeOfBuffer,'OutputBufferSize',sizeOfBuffer);
    
    fopen(afg2);


end

