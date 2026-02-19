function java_dnd(target, dropFcn)
% Set Matlab dropFcn for a figure object. Called by uiFileDnD.m.

% 170421 Xiangrui Li adapted from dndcontrol class by Maarten van der Seijs:
%   https://www.mathworks.com/matlabcentral/fileexchange/53511
% 260201 include findjobj_fast(), so input is figure component
% 260209 use fh.WindowKeyPressFcn to catch ctrlKey/shiftKey

% Required: MLDropTarget.class under the same folder

if ~exist('MLDropTarget', 'class')
    pth = fileparts(mfilename('fullpath'));
    javaaddpath(pth); % dynamic for this session
    fid = fopen(fullfile(prefdir, 'javaclasspath.txt'), 'a+');
    if fid>0 % static path for later sessions: work for 2013+?
        cln = onCleanup(@() fclose(fid));
        fseek(fid, 0, 'bof');
        classpth = fread(fid, inf, '*char')';
        if isempty(strfind(classpth, pth)) %#ok<*STREMP> % avoid multiple write
            fseek(fid, 0, 'bof');
            fprintf(fid, '%s\n', pth);
        end
    end
end

dropTarget = handle(javaObjectEDT('MLDropTarget'), 'CallbackProperties');
set(dropTarget, 'DropCallback', {@DropCallback target dropFcn});
jObj = handle(findjobj_fast(target), 'CallbackProperties');
jObj.setDropTarget(dropTarget);
%%

function DropCallback(jSource, ~, target, dropFcn)
% Try to detect control and shift key during drop 
fh = ancestor(target, 'figure');
keyFcn = fh.WindowKeyPressFcn;
restoreKeyFcn = onCleanup(@()set(fh,'WindowKeyPressFcn',keyFcn));
fh.WindowKeyPressFcn = @(o,e)setappdata(fh,'Modifiers',e.Modifier);
figure(fh); drawnow;
bot = java.awt.Robot();
k = java.awt.event.KeyEvent.VK_CAPS_LOCK; % no harm key
bot.keyPress(k); bot.keyRelease(k); bot.keyPress(k); pause(0.05); bot.keyRelease(k);
dat = getappdata(fh, 'Modifiers');
if ~iscell(dat), dat = {}; end % in case Robot() fails
evt.ctrlKey = contains('control', dat);
evt.shiftKey = contains('shift', dat);

evt.names = cellstr(char(jSource.getTransferData()));
if strncmp(evt.names, 'file://', 7) % files identified as string
    evt.names = regexp(evt.names, '(?<=file://).*?(?=\r?\n)', 'match')';
end

if iscell(dropFcn), feval(dropFcn{1}, target, evt, dropFcn{2:end});
else, feval(dropFcn, target, evt);
end
%%

% findjobj_fast() from Yair Altman (2026). findjobj - find java handles of Matlab graphic objects
% https://www.mathworks.com/matlabcentral/fileexchange/14317-findjobj-find-java-handles-of-matlab-graphic-objects
function jControl = findjobj_fast(hControl) %#ok<*JAVFM,*JAPIMATHWORKS>
if double(get(hControl,'Parent'))~=0  % avoid below for figure handles
    try jControl = hControl.getTable; return, catch, end  % fast bail-out for old uitables
    try jControl = hControl.JavaFrame.getGUIDEView; return, catch, end  % bail-out for HG2 matlab.ui.container.Panel
end
oldWarn = warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
restoreWarn = onCleanup(@()warning(oldWarn));
% Use a HG2 matlab.ui.container.Panel jContainer if the control's parent is a uipanel
try
    hParent = get(hControl,'Parent');
catch
    % Probably indicates an invalid/deleted/empty handle
    jControl = [];
    return
end
try jContainer = hParent.JavaFrame.getGUIDEView; catch, jContainer = []; end
if isempty(jContainer)
    hFig = ancestor(hControl,'figure');
    jf = get(hFig, 'JavaFrame');
    if isequal(hFig,hControl) % speedup suggested by T. Carpenter 2021-08-17
        jControl = jf.getAxisComponent;
        return
    end
    jContainer = jf.getFigurePanelContainer.getComponent(0);
end
jControl = [];
specialTooltipStr = '!@#$%^&*';
try  % Fix for R2018b suggested by Eddie (FEX comment 2018-09-19)
    tooltipPropName = 'TooltipString';
    oldTooltip = get(hControl,tooltipPropName);
    set(hControl,tooltipPropName,specialTooltipStr);
catch
    tooltipPropName = 'Tooltip';
    oldTooltip = get(hControl,tooltipPropName);
    set(hControl,tooltipPropName,specialTooltipStr);
end
restoreTooltip = onCleanup(@()set(hControl,tooltipPropName,oldTooltip));
for counter = 1:3
    jControl = findTooltipIn(jContainer, specialTooltipStr);
    if ~isempty(jControl), break; else, pause(0.017); end
end
set(hControl,tooltipPropName,oldTooltip);
try jControl.setToolTipText(oldTooltip); catch, end
try jControl = jControl.getParent.getView.getParent.getParent; catch, end  % return JScrollPane if exists

function jControl = findTooltipIn(jContainer, specialTooltipStr)
try
    jControl = [];  % Fix suggested by H. Koch 11/4/2017
    tooltipStr = jContainer.getToolTipText;
    if ~isempty(tooltipStr) && tooltipStr.startsWith(specialTooltipStr)  % a bit faster
        jControl = jContainer;
    else
        for idx = 1 : jContainer.getComponentCount
            jControl = findTooltipIn(jContainer.getComponent(idx-1), specialTooltipStr);
            if ~isempty(jControl), return; end
        end
    end
catch
    % ignore
end
%%