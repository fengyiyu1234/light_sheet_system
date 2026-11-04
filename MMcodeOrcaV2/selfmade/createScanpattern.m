function [xyzScanArray]=createScanpattern(xPos,yPos,zPos,Vertiles_num,Horztiles_num,stepSize)
    xyzScanArray = zeros(3,Vertiles_num*Horztiles_num);
    xyzScanArray(2,:)=yPos;
    % tile offsets centred on the current position, for odd and even tile counts
    % (e.g. 3 tiles: -1 0 1; 2 tiles: -0.5 0.5)
    xVec = (0:Vertiles_num-1) - (Vertiles_num-1)/2;
    zVec = (0:Horztiles_num-1) - (Horztiles_num-1)/2;
    
    xVec = xVec*stepSize + xPos;
    zVec = zVec*stepSize + zPos;
    
    [xx,zz] = meshgrid(xVec,zVec);
    xyzScanArray(1,:) = xx(:);
    %snake pattern
%     for ii=2:2:Horztiles_num
%         zz(:,ii) = zz(end:-1:1,ii);
%     end
    xyzScanArray(3,:) = zz(:);
end