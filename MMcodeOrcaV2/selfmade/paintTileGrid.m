function g = paintTileGrid(curX, curZ, initX, initZ, V, H, stepUm, pixelUm)
% PAINTTILEGRID  Tile rectangles for the Paint view, in Paint-canvas pixels.
%   g = paintTileGrid(curX, curZ, initX, initZ, V, H, stepUm, pixelUm)
%   Uses createScanpattern, so the tiles (positions, numbering, odd/even
%   centring) are exactly the ones "create scan pattern" would make at the
%   current stage position (curX, curZ) with V x H tiles and step stepUm.
%   Canvas mapping is the one used by Paint/Up/Down/Left/Right/Center:
%     row = 2048*10 + 1024.5 + (x - initX)/pixelUm   (X stage -> image rows)
%     col = 2048*10 + 1024.5 - (z - initZ)/pixelUm   (Z stage -> image columns, inverted)
%   g.row, g.col : tile centres (canvas pixels), tile k in scan-pattern order
%   g.half       : half tile size (1024 px)
%   g.extent_um  : [vertical horizontal] size of the whole grid (um)
%   (2026-11-04)

xyz = createScanpattern(curX, 0, curZ, V, H, stepUm);
c0 = 2048*10 + 1024.5;
g.row = c0 + (xyz(1,:)' - initX) / pixelUm;
g.col = c0 - (xyz(3,:)' - initZ) / pixelUm;
g.half = 1024;
g.extent_um = [2048*pixelUm + (V-1)*stepUm, 2048*pixelUm + (H-1)*stepUm];
end
