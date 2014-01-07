function [DataFI,FileName,Tp,Otherargs] = grid_fopen(cmd,varargin)
%GRID_FOPEN Routine for opening attribute files on grid.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2014 Stichting Deltares.                                     
%                                                                               
%   This library is free software; you can redistribute it and/or                
%   modify it under the terms of the GNU Lesser General Public                   
%   License as published by the Free Software Foundation version 2.1.                         
%                                                                               
%   This library is distributed in the hope that it will be useful,              
%   but WITHOUT ANY WARRANTY; without even the implied warranty of               
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU            
%   Lesser General Public License for more details.                              
%                                                                               
%   You should have received a copy of the GNU Lesser General Public             
%   License along with this library; if not, see <http://www.gnu.org/licenses/>. 
%                                                                               
%   contact: delft3d.support@deltares.nl                                         
%   Stichting Deltares                                                           
%   P.O. Box 177                                                                 
%   2600 MH Delft, The Netherlands                                               
%                                                                               
%   All indications and logos of, and references to, "Delft3D" and "Deltares"    
%   are registered trademarks of Stichting Deltares, and remain the property of  
%   Stichting Deltares. All rights reserved.                                     
%                                                                               
%-------------------------------------------------------------------------------
%   http://www.deltaressystems.com
%   $HeadURL$
%   $Id$

DataFI   = [];
FileName = '';
Tp       = '';
Otherargs= {};
%
if matlabversionnumber<6
    filterspec='*.*';
else
    filterspec={...
        '*.*'         'All files'                            ''
        '*.dep;*.qin' 'QuickIn file'                         'wldep'
        '*.*'         'SIMONA box file'                      'boxfile'
        '*.*'         'Delft3D-MOR field file'               'wlfdep'
        'tri-rst.*'   'Delft3D-FLOW restart file'            'trirst'
        '*.enc'       'Delft3D/SIMONA enclosure file'        'enclosure'
        '*.aru;*.arv' 'Delft3D/SIMONA roughness area file'   'trtarea'
        'swanout'     'SWAN map output file'                 'swanout'
        '*.bnd'       'Delft3D-FLOW boundary file'           'attrib'
        '*.thd'       'Delft3D-FLOW thin dam file'           'attrib'
        '*.dry'       'Delft3D-FLOW dry points file'         'attrib'
        '*.obs'       'Delft3D-FLOW observation point file'  'attrib'
        '*.crs'       'Delft3D-FLOW cross-section file'      'attrib'
        '*.src'       'Delft3D-FLOW discharge station file'  'attrib'
        '*.2dw;*.wr'  'Delft3D-FLOW 2D weir file'            'attrib'
        'bag*.*'      'Delft3D-MOR dredge map output file'   'bagmap'
        '*.inc'       'Incremental file'                     'fls'};
end
%
switch cmd
    case 'opennew'
        FileName  = '';
        targetdir = varargin{1};
    case 'open'
        FileName  = varargin{1};
        targetdir = fileparts(FileName);
end
gridsize  = varargin{2};
Otherargs= {gridsize};
if isempty(FileName)
    currentdir=pwd;
    cd(targetdir);
    [fn,pn]=uigetfile(filterspec(:,1:2),'Select data file to open ...');
    cd(currentdir);
    if ~ischar(fn)
        return
    end
    FileName=[pn fn];
end
%autodetect intelligence ...
try1=1;
lasttry=0;
trytp='trtarea';
[pn,fn,en]=fileparts(FileName);
if strncmpi('bag',fn,3)
    trytp='bagmap';
elseif strncmpi('tri-rst',fn,7)
    trytp='trirst';
elseif strncmpi('swanout',fn,7)
    trytp='swanout';
else
    switch lower(en),
        case {'.aru','.arv'}
            trytp='trtarea';
        case {'.dep','.qin'}
            trytp='wldep';
        case {'.inc'}
            trytp='fls';
        case {'.bnd','.thd','.wr','.obs','.crs','.src','.dry'}
            trytp='attrib';
        case '.enc'
            trytp='enclosure';
    end
end
FileName = absfullfile(FileName);

%try opening the file ...
while isempty(DataFI)
    switch trytp
        case 'trtarea'
            try1=0;
            try
                DataFI=trtarea('read',FileName);
            catch
            end
            if ~isempty(DataFI)
                DataFI.FileType=trytp;
            end
            trytp='swanout';
        case 'swanout'
            try
                DataFI=swan('read',FileName,gridsize);
            catch
            end
            trytp='wldep';
        case 'wldep'
            try
                DataFI=wldep('read',FileName,gridsize,'multiple');
            catch
                try
                    DataFI=wldep('read',FileName,gridsize-1,'multiple');
                catch
                end
            end
            if ~isempty(DataFI)
                if ~isstruct(DataFI)
                    Tmp.Data={DataFI};
                    DataFI=Tmp; Tmp=[];
                else
                    Tmp.Data={DataFI.Data};
                    DataFI=Tmp; Tmp=[];
                end;
                DataFI.FileType=trytp;
            end
            trytp='wlfdep';
        case 'wlfdep'
            try
                DataFI=wlfdep('read',FileName);
            catch
            end
            if ~isempty(DataFI)
                if ~isequal(size(DataFI),gridsize)
                    emsg = 'Size of datafield does not match size of grid';
                    DataFI=[];
                else
                    Tmp.Data={DataFI};
                    DataFI=Tmp; Tmp=[];
                    DataFI.FileType=trytp;
                end
            end
            trytp='boxfile';
        case 'boxfile'
            try
                DataFI=boxfile('read',FileName,gridsize);
            catch
            end
            if ~isempty(DataFI)
                if ~isequal(size(DataFI),gridsize)
                    %          ui_message('error','Size of datafield does not match size of grid');
                    %          DataFI=[]; return
                    DataFI=[];
                else
                    Tmp.Data={DataFI};
                    DataFI=Tmp; Tmp=[];
                    DataFI.FileType=trytp;
                end
            end
            trytp='fls';
        case 'fls'
            try
                DataFI=incremental('open',FileName,gridsize);
                DataFI=incremental('readtimes',DataFI);
            catch
            end
            if ~isempty(DataFI)
                if ~isfield(DataFI,'Check')
                    DataFI=[];
                elseif strcmp(DataFI.Check,'NotOK')
                    DataFI=[];
                elseif ~strcmp(DataFI.FileType,'FLS-inc')
                    emsg = sprintf('Don''t know how to relate %s file to grid.',DataFI.FileType);
                    DataFI=[];
                elseif length(DataFI.Domain)~=1
                    emsg = 'Multi-domain incremental file not supported on grid.';
                    DataFI=[];
                elseif ~isequal([DataFI.Domain.NRows DataFI.Domain.NCols],gridsize)
                    emsg = 'Size of datafield does not match size of grid.';
                    DataFI=[];
                end
            end
            trytp='trirst';
        case 'trirst'
            try1=0;
            try
                DataFI=trirst('read',FileName,gridsize,'all');
            catch
            end
            if ~isempty(DataFI)
                Tmp.Data={DataFI.Data};
                Tmp.NLyr=1;
                DataFI=Tmp; Tmp=[];
                DataFI.FileType=trytp;
            end
            trytp='bagmap';
        case 'bagmap'
            try1=0;
            try
                DataFI=bagmap('open',FileName);
            catch
            end
            if ~isempty(DataFI)
                if ~isequal([DataFI.M DataFI.N],gridsize)
                    emsg = 'Size of datafield does not match size of grid.';
                    DataFI=[];
                else
                    DataFI.FileType=trytp;
                end
            else
                DataFI=[];
            end
            trytp='attrib';
        case 'attrib'
            try
                DataFI=d3d_attrib('read',FileName);
            catch
            end
            if ~isempty(DataFI) && strcmp(DataFI.Check,'OK');
                trytp=DataFI.Type;
                if isfield(DataFI,'MNu')
                    if (max(max(DataFI.MNu(:,[1 3])))>gridsize(1)) || (max(max(DataFI.MNv(:,[1 3])))>gridsize(1)) || ...
                            (max(max(DataFI.MNu(:,[2 4])))>gridsize(2)) || (max(max(DataFI.MNv(:,[2 4])))>gridsize(2))
                        emsg = 'Weirs/dams outside grid encountered.';
                        DataFI=[];
                    else
                        DataFI.FileType=trytp;
                    end
                elseif isfield(DataFI,'MNKu')
                    if (max(max(DataFI.MNKu(:,[1 3])))>gridsize(1)) || (max(max(DataFI.MNKv(:,[1 3])))>gridsize(1)) || ...
                            (max(max(DataFI.MNKu(:,[2 4])))>gridsize(2)) || (max(max(DataFI.MNKv(:,[2 4])))>gridsize(2))
                        emsg = 'Gates/sheets outside grid encountered.';
                        DataFI=[];
                    else
                        DataFI.FileType=trytp;
                    end
                elseif isequal(DataFI.Type,'drypoint')
                    if (max(max(DataFI.MN(:,[1 3])))>gridsize(1)) || (max(max(DataFI.MN(:,[2 4])))>gridsize(2))
                        emsg = 'Dry points outside grid encountered.';
                        DataFI=[];
                    else
                        DataFI.FileType=trytp;
                    end
                elseif isequal(DataFI.Type,'observation points')
                    if (max(DataFI.MN(:,1))>gridsize(1)) || (max(DataFI.MN(:,2))>gridsize(2))
                        emsg = 'Observation points outside grid encountered.';
                        DataFI=[];
                    else
                        DataFI.FileType=trytp;
                    end
                elseif isequal(DataFI.Type,'openboundary')
                    if (max(DataFI.MN(:,1))>gridsize(1)) || (max(DataFI.MN(:,2))>gridsize(2))
                        emsg = 'Boundary locations outside grid encountered.';
                        DataFI=[];
                    else
                        DataFI.FileType=trytp;
                    end
                elseif isequal(DataFI.Type,'discharge stations')
                    if (max(DataFI.MNK(:,1))>gridsize(1)) || (max(DataFI.MNK(:,2))>gridsize(2))
                        emsg = 'Discharge stations outside grid encountered.';
                        DataFI=[];
                    else
                        DataFI.FileType=trytp;
                    end
                elseif isequal(DataFI.Type,'cross-sections')
                    if (max(max(DataFI.MNMN(:,[1 3])))>gridsize(1)) || ...
                            (max(max(DataFI.MNMN(:,[2 4])))>gridsize(2))
                        emsg = 'Cross-sections outside grid encountered.';
                        DataFI=[];
                    else
                        DataFI.FileType=trytp;
                    end
                else
                    emsg = sprintf('%s not yet supported.',DataFI.Type);
                    DataFI=[];
                end
            else
                DataFI=[];
            end
            trytp='enclosure';
        case 'enclosure'
            try1=0;
            try
                DataTmp=enclosure('read',FileName);
            catch
                DataTmp=[];
            end
            if ~isempty(DataTmp)
                if any(max(DataTmp)>gridsize)
                    emsg = 'Enclosure extends beyond grid';
                    DataFI=[];
                else
                    DataFI.Data=DataTmp;
                    DataFI.FileType=trytp;
                end
            else
                DataFI=[];
            end
            trytp='';
        otherwise
            break
    end
    if lasttry
        if isempty(DataFI)
            if isempty(emsg)
                emsg = lasterr;
            end
            ui_message('error','Unable to load attribute file ''%s'' onto grid.\nError reported:\n%s',FileName,emsg)
            return
        end
        break
    elseif try1
        trytp='trtarea';
        try1=0;
    elseif isempty(trytp)
        [trytp,try_i]=ui_type(filterspec(2:end,2),'windowtitle','Specify file format');
        if isempty(trytp)
            return
        end
        emsg = '';
        trytp=filterspec{1+try_i,3};
        lasttry=1;
    end
end
if ~isempty(DataFI)
    Tp=DataFI.FileType;
end
