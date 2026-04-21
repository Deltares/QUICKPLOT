# Drag and Drop OS file/folder(s) into Matlab figure/uifigure (2026.02.16)
[![View uiFileDnD on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/80656-uifilednd)

The uiFileDnD implementation allows to set up a callback fired when files and/or folders are dropped onto a (ui)figure component. 

In the callback, full file/folder names are captured for user to decide the action. Ctrl and Shift key status during the drop event are also reported.

Example to drop file/folder onto uilistbox of uifigure:
    
    target = uilistbox(uifigure, 'Position', [80 100 400 100]);
    uiFileDnD(target, @(o,dat)set(o,'Items',dat.names));

Example to drop file/folder onto listbox of figure:
    
    target = uicontrol(figure, 'Style', 'listbox', 'Position', [80 100 400 100]);
    uiFileDnD(target, @(o,dat)set(o,'String',dat.names));

Note: 
 1. File DnD onto uifigure works since Matlab R2020b (since R2025a for Linux).
 2. The following line needs to be added into startup.m file for R2025a,b, maybe later:

    try addprop(groot, 'ForceIndependentlyHostedFigures'); catch, end

 3. java_dnd.m & MLDropTarget.class are for figure() before R2025a, and can be removed in the future.
